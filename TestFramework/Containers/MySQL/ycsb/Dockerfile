FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    openjdk-8-jre \
    python2 \
    python3 \
    python3-pip \
    wget \
    curl \
    sudo \
    util-linux \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install MySQL connector for Ubuntu 20.04 (focal)
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java_8.0.29-1ubuntu20.04_all.deb \
    && apt install -y ./mysql-connector-java_8.0.29-1ubuntu20.04_all.deb \
    && ln -sf /usr/share/java/mysql-connector-java-8.0.29.jar /usr/share/java/mysql-connector-java.jar \
    && rm mysql-connector-java_8.0.29-1ubuntu20.04_all.deb

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Set YCSB configuration variables  
ENV YCSB_THREADS=8
ENV YCSB_CORE_RANGE=1-31
ENV YCSB_DURATION=60

# Create working directory
WORKDIR /app

# Download and setup YCSB
RUN curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz \
    && tar xzvf ycsb-0.17.0.tar.gz \
    && rm ycsb-0.17.0.tar.gz

# Update YCSB binary to use python2
RUN cd ycsb-0.17.0 \
    && mv bin/ycsb bin/ycsb.original \
    && sed "s/env python/env python2/g" bin/ycsb.original > bin/ycsb \
    && chmod u+x bin/ycsb

# Copy application files
COPY db.properties ycsb-0.17.0/
COPY harvest_read ycsb-0.17.0/workloads/
COPY launcher.py .
COPY run_ycsb.sh .
COPY load_ycsb.sh .

# Make scripts executable
RUN chmod +x launcher.py run_ycsb.sh load_ycsb.sh

# Create directory for results (may be mounted as volume)
RUN mkdir -p /app/results

# Expose the default port for the launcher
EXPOSE 20002

# Set the entry point to launcher.py
ENTRYPOINT ["python3", "launcher.py"]