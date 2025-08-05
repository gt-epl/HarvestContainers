#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#include "external/json.hpp"

extern "C" {
#include "shmem.h"
#include "listener.h"
#include "getpids.h"
}

#define DEVICE_FILENAME "/dev/qidlecpu"
#define SERVER_PORT 10101
#define TIMEOUT_SEC 1

extern "C" int get_containers(char* pod_id);
int listenerControl;
std::string read_payload(int sock);
pthread_t conn_handler_thread;
struct idleStats *idleCpuStats = NULL;

int parseCpuList(std::string cpuList) 
{
    char *cpuListString = strdup(cpuList.c_str());
    char *token;
    int curr_cpu = 0;
    int curr_cpuid;
    while ((token = strsep(&cpuListString, ",")) != NULL) {
      sscanf(token, "%d", &curr_cpuid);
      idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].cpuList[curr_cpu] = curr_cpuid;
      curr_cpu++;
      printf("  -> Added cpu%d to cpuList list (count: %d)\n", curr_cpuid, curr_cpu);
    }
    idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].NUMCPUS = curr_cpu;
    free(cpuListString);
    return 0;
}

/* Read client payload from socket */
std::string read_payload(int sock) {
    std::string data;
    char buf[1024];
    ssize_t bytes_read;

    struct timeval tv;
    tv.tv_sec = TIMEOUT_SEC;
    tv.tv_usec = 0;

    if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        perror("Failed to set socket timeout");
        return "";
    }

    while ((bytes_read = read(sock, buf, sizeof(buf))) > 0) {
        data.append(buf, bytes_read);
    }
    return data;
}

void handle_signal(int signum)
{
    if (signum == SIGUSR1) {
        std::cout<< "[!] [Listener] Caught signal. Cleaning up." << std::endl;
        listenerControl = -1;
        pthread_cancel(conn_handler_thread);
    }
}

/* Handle incoming client connections */
void *handle_connection(void *arg)
{
    (void)arg;

    int sockfd;
    int sock = -1;
    socklen_t c;
    struct sockaddr_in server, client;
    char send_buf[4] = "ACK";

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
        perror("[!] [Listener] Failed to create socket");
        return NULL;
    }

    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_port = htons(SERVER_PORT);

    if (bind(sockfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
        perror("[!] [Listener] Failed to bind to port");
        close(sockfd);
        return NULL;
    }

    listen(sockfd, 3);

    std::cout << "[+] [Listener] Listening for incoming connections on port " << SERVER_PORT << std::endl;

    while (listenerControl == 1) {
        sock = accept(sockfd, (struct sockaddr *)&client, &c);
        if (sock < 0) {
            continue;
        }

        try {
            std::string json_data = read_payload(sock);

            if (json_data.empty()) {
                close(sock);
                sock = -1;
                continue;
            }

	    std::cout << "raw data:" << json_data << std::endl;
            auto json = nlohmann::json::parse(json_data);
            std::string ctr_type = json["ctr_type"];
            if (ctr_type == "Secondary") {
                std::string pod_id = json["pod_id"];
                std::cout << "[+] [Listener] Got Secondary pod_id " << pod_id << std::endl;
                // Process containers for this pod
                int result = get_containers(const_cast<char*>(pod_id.c_str()));
                if (result < 0) {
                    std::cout << "[!] [Listener] Failed to process containers for pod " << pod_id << std::endl;
                } else if (idleCpuStats->balancerControl == 0) {
                    idleCpuStats->balancerControl = 1;
                }
            } else if (ctr_type == "Primary") {
		std::cout << "[!] [Listener] Got Primary with acbf: " << json ["LOWIDLEFREQ_THRESHOLD"] << std::endl;
                std::string cpuList = json["cpuList"];
                std::string LOWIDLEFREQ_THRESHOLD = json["LOWIDLEFREQ_THRESHOLD"];
                std::string LOW_TIC = json["LOW_TIC"];
                std::string targetIdleCores = json["targetIdleCores"];
                std::string static_targetIdleCores = json["static_targetIdleCores"];
                std::string minSecondaryCores = json["minSecondaryCores"];

                parseCpuList(cpuList);

                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].LOWIDLEFREQ_THRESHOLD = std::stof(LOWIDLEFREQ_THRESHOLD);
                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].LOW_TIC = std::stoi(LOW_TIC);
                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].targetIdleCores = std::stoi(targetIdleCores);
                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].static_targetIdleCores = std::stoi(static_targetIdleCores);
                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].minSecondaryCores = std::stoi(minSecondaryCores);

                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].totalEligibleCores = idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].NUMCPUS;
                idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].maxSecondaryCores = idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].totalEligibleCores - idleCpuStats->primary_ctrs[idleCpuStats->nr_primary_ctrs].targetIdleCores;
                idleCpuStats->nr_primary_ctrs+=1;
            }

            // Send ACK response
            ssize_t bytes_sent = write(sock, send_buf, sizeof(send_buf));
            if (bytes_sent < 0 || (size_t)bytes_sent != sizeof(send_buf)) {
                std::cout << "[!] [Listener] Failed to send response" << std::endl;
            }

        } catch (const nlohmann::json::parse_error& e) {
            std::cout << "[!] [Listener] Invalid JSON received: " << e.what() << std::endl;
            close(sock);
            sock = -1;
            continue;
        } catch (const nlohmann::json::type_error& e) {
            std::cout << "[!] [Listener] Missing field in JSON: " << e.what() << std::endl;
            close(sock);
            sock = -1;
            continue;
        }

        close(sock);
        sock = -1;
    }

    close(sockfd);
    return NULL;
}

int main()
{
    int shm_fd = -1;
    struct idleStats *idle_shm = NULL;

    // Initialize control flag
    listenerControl = 1;

    std::cout << "idleStats size: " << sizeof(struct idleStats) << std::endl;

    // Open HarvestContainers shared memory device file
    shm_fd = open(DEVICE_FILENAME, O_RDWR | O_NDELAY);
    if (shm_fd < 0) {
        perror("[!] [Listener] Unable to open shared memory device file");
        return EXIT_FAILURE;
    }

    // Map shared memory segment
    idle_shm = (struct idleStats*)mmap(0, SHMEM_SIZE,
                                     PROT_WRITE | PROT_READ,
                                     MAP_SHARED, shm_fd, 0);
    if (idle_shm == MAP_FAILED) {
        perror("[!] [Listener] Unable to map shared memory");
        close(shm_fd);
        return EXIT_FAILURE;
    }

    idleCpuStats = &idle_shm[0];

    // Signal handler for graceful shutdown
    signal(SIGUSR1, handle_signal);

    // Connection handler thread
    if (pthread_create(&conn_handler_thread, NULL, handle_connection, NULL) < 0) {
        perror("[!] [Listener] Failed to create connection handler thread");
        goto cleanup;
    }

    // Wait for connection thread to finish
    pthread_join(conn_handler_thread, NULL);

cleanup:
    if (idle_shm && idle_shm != MAP_FAILED) {
        munmap(idle_shm, sizeof(struct idleStats));
    }
    if (shm_fd >= 0) {
        close(shm_fd);
    }

    return EXIT_SUCCESS;
}

