#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
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

static unsigned long long SAMPLE_RATE = 1*1000*1000*1000ULL;

void handle_signal(int signum)
{
    if (signum == SIGUSR1) {
        printf("[!] [Listener] Caught signal. Cleaning up.\n");
        listenerControl = -1;
        pthread_cancel(conn_handler_thread);
    }
}

unsigned long long getTimeElapsed(struct timespec *prev_time)
{
    struct timespec curr_time;
    unsigned long long elapsed;
    clock_gettime(CLOCK_MONOTONIC_RAW, &curr_time);
    elapsed = (1000*1000*1000) *
    (curr_time.tv_sec - prev_time->tv_sec) +
    (curr_time.tv_nsec - prev_time->tv_nsec);
    return elapsed;
}

void *handle_connection()
{
  int sockfd;
  int sock;
  int n, c;
  struct sockaddr_in server;
  struct sockaddr_in client;
  char *send_buf;
  char recv_buf[40];

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd == -1)
  {
      printf("[!] [Listener] Failed to create socket.\n");
  }

  // int status = fcntl(sockfd, F_SETFL, fcntl(sockfd, F_GETFL, 0) | O_NONBLOCK);
  // if(status == -1) {
  //   printf("Failed to change socket to non-blocking\n");
  //   return -1;
  // }

  server.sin_family = AF_INET;
  server.sin_addr.s_addr = INADDR_ANY;
  server.sin_port = htons(SERVER_PORT);

  if( bind(sockfd, (struct sockaddr *)&server, sizeof(server)) < 0 ) {
      printf("[!] [Listener] ERROR: Failed to bind to port %d\n", SERVER_PORT);
      exit(-1);
  }

  listen(sockfd, 3);
  c = sizeof(struct sockaddr_in);

  printf("[+] [Listener] Listening for incoming connections on port %d\n", SERVER_PORT);
  while(listenerControl == 1) {
    sock = accept(sockfd, (struct sockaddr *)&client, (socklen_t*)&c);
    if (!(sock < 0)) {
      n = read(sock, recv_buf, 40);
      recv_buf[39] = '\0';
      printf("[+] [Listener] Connection received with POD ID: %s\n", recv_buf);

      /* Get containers for pod, extract tasks in each container */
      get_containers(recv_buf);
      if(idleCpuStats->balancerControl == 0) idleCpuStats->balancerControl = 1;
      /* Send ACK to client */
      send_buf = "ACK";
      write(sock, send_buf, strlen(send_buf));
    }
  }
}

int main(int argc , char **argv)
{
  int shm_fd;
  struct idleStats *idle_shm;
  struct timespec sample_time;
  //pthread_t conn_handler_thread;
  
  listenerControl = 1;

  if(argc < 2) {
    printf("[!] [Listener] Please specify CPUSET (e.g., 1-11)\n");
    exit(1);
  }
  snprintf(cpuList, sizeof(cpuList), "%s", argv[1]);

  shm_fd = open(DEVICE_FILENAME, O_RDWR|O_NDELAY);
  if(shm_fd >= 0) {
      idle_shm = (struct idleStats*)mmap(0, 4096, PROT_WRITE, MAP_SHARED, shm_fd, 0);
  }
  else {
      printf("[!] [Listener] Unable to open QIDLECPU shared memory\n");
      exit(-1);
  }

  idleCpuStats = &idle_shm[0];

  signal(SIGUSR1, handle_signal);

  if(pthread_create(&conn_handler_thread, NULL, handle_connection, NULL) < 0)
  {
    perror("[!] [Listener] Failed to create handle connection thread\n");
    return 1;
  }

  pthread_join(conn_handler_thread, NULL);

  munmap(idle_shm, 4096);
  close(shm_fd);
  return 0;
}
