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

#include "listener.h"
#include "getpids.h"

#define DEVICE_FILENAME "/dev/qidlecpu"
#define SERVER_PORT 10101
#define RECV_BUFFER_SIZE 40

int listenerControl;
// char podList[MAX_PODS][MAX_POD_ID_LEN];
pthread_t conn_handler_thread;

struct idleStats *idleCpuStats = NULL;

void handle_signal(int signum)
{
    if (signum == SIGUSR1) {
        printf("[!] [Listener] Caught signal. Cleaning up.\n");
        listenerControl = -1;
        pthread_cancel(conn_handler_thread);
    }
}

/* Handle incoming client connections */
void *handle_connection()
{
    int sockfd;
    int sock = -1;
    ssize_t n;
    socklen_t c;
    struct sockaddr_in server, client;
    char send_buf[4] = "ACK";
    char recv_buf[RECV_BUFFER_SIZE + 1];

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

    printf("[+] [Listener] Listening for incoming connections on port %d\n", SERVER_PORT);

    while (listenerControl == 1) {
        sock = accept(sockfd, (struct sockaddr *)&client, &c);
        if (sock < 0) {
            continue;
        }

        // Read pod ID from client
        n = read(sock, recv_buf, RECV_BUFFER_SIZE);
        if (n <= 0 || n >= RECV_BUFFER_SIZE) {
            close(sock);
            sock = -1;
            continue;
        }

        // Null-terminate and process pod ID
        recv_buf[n] = '\0';
        printf("[+] [Listener] Connection received with POD ID: %s\n", recv_buf);

        // Process containers for this pod
        int result = get_containers(recv_buf);
        if (result < 0) {
            printf("[!] [Listener] Failed to process containers for pod %s\n", recv_buf);
        } else if (idleCpuStats->balancerControl == 0) {
            idleCpuStats->balancerControl = 1;
        }

        // Send ACK response
        ssize_t bytes_sent = write(sock, send_buf, sizeof(send_buf));
        if (bytes_sent < 0 || (size_t)bytes_sent != sizeof(send_buf)) {
            printf("[!] [Listener] Failed to send response\n");
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

    // Open HarvestContainers shared memory device file
    shm_fd = open(DEVICE_FILENAME, O_RDWR | O_NDELAY);
    if (shm_fd < 0) {
        perror("[!] [Listener] Unable to open shared memory device file");
        return EXIT_FAILURE;
    }

    // Map shared memory segment
    idle_shm = (struct idleStats*)mmap(NULL, sizeof(struct idleStats),
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
