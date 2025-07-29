FROM ubuntu:20.04

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Set mutilate configuration as environment variables
ENV MUTILATE_CORE_RANGE="8-15"
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
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create directory structure
RUN mkdir -p /app/bin \
    && mkdir -p /app/Results

# Copy mutilate setup script and run it
COPY setup_mutilate.sh /app/
RUN chmod +x /app/setup_mutilate.sh && \
    cd /app && \
    WORKING_DIR=/app ./setup_mutilate.sh

# Copy the launcher and run script
COPY mutilate_launcher.py /app/
COPY run_mutilate.sh /app/
RUN chmod +x /app/run_mutilate.sh

# Expose the port used by mutilate_launcher.py
EXPOSE 20003

# Set entrypoint to run_mutilate.sh as requested
ENTRYPOINT ["./run_mutilate.sh"]
