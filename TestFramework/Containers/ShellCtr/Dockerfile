FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y iperf3 openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:shell' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 22022/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
EXPOSE 22022
CMD ["/usr/sbin/sshd", "-D"]
