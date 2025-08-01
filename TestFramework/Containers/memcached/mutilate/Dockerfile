FROM ubuntu:20.04

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Set mutilate configuration as environment variables
ENV MUTILATE_THREADS="8"
ENV MUTILATE_CONNS="1"
ENV MUTILATE_DURATION="60"
ENV MEMCACHED_SERVER="127.0.0.1"

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    scons \
    libevent-dev \
    gengetopt \
    libzmq3-dev \
    python3 \
    python3-pip \
    python2.7 \
    python2.7-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create directory structure
RUN mkdir -p /app/workspace && \
    mkdir -p /app/results

# Copy mutilate setup script and run it
COPY setup_mutilate.sh /app/workspace/
RUN chmod +x /app/workspace/setup_mutilate.sh && \
    cd /app/workspace && \
    WORKING_DIR=/app/workspace ./setup_mutilate.sh && \
    cp /app/workspace/mutilate/mutilate /app/mutilate

# Copy the launcher and run script
COPY mutilate_launcher.py /app/
COPY run_mutilate.sh /app/
COPY load.sh /app/

RUN chmod +x /app/run_mutilate.sh && \
    chmod +x /app/load.sh

# Expose the port used by mutilate_launcher.py
EXPOSE 20003

ENTRYPOINT ["python3", "/app/mutilate_launcher.py"]
