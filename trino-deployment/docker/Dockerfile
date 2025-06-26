FROM openjdk:17-jre-slim

# Set Trino version
ENV TRINO_VERSION=446
ENV TRINO_HOME=/opt/trino
ENV TRINO_DATA_DIR=/data/trino

# Create trino user and directories
RUN groupadd -r trino --gid=1000 && \
    useradd -r -g trino --uid=1000 --home-dir=${TRINO_HOME} --shell=/bin/bash trino && \
    mkdir -p ${TRINO_HOME} ${TRINO_DATA_DIR} && \
    chown -R trino:trino ${TRINO_HOME} ${TRINO_DATA_DIR}

# Install required packages
RUN apt-get update && \
    apt-get install -y wget python3 less procps && \
    rm -rf /var/lib/apt/lists/*

# Download and install Trino server
RUN wget -q https://repo1.maven.org/maven2/io/trino/trino-server/${TRINO_VERSION}/trino-server-${TRINO_VERSION}.tar.gz && \
    tar -xzf trino-server-${TRINO_VERSION}.tar.gz -C ${TRINO_HOME} --strip-components=1 && \
    rm trino-server-${TRINO_VERSION}.tar.gz && \
    chown -R trino:trino ${TRINO_HOME}

# Download Trino CLI
RUN wget -q https://repo1.maven.org/maven2/io/trino/trino-cli/${TRINO_VERSION}/trino-cli-${TRINO_VERSION}-executable.jar \
    -O ${TRINO_HOME}/bin/trino && \
    chmod +x ${TRINO_HOME}/bin/trino

# Create configuration directories
RUN mkdir -p ${TRINO_HOME}/etc/catalog && \
    chown -R trino:trino ${TRINO_HOME}/etc

# Copy configuration files
COPY --chown=trino:trino config/ ${TRINO_HOME}/etc/
COPY --chown=trino:trino entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

# Set working directory and user
WORKDIR ${TRINO_HOME}
USER trino

# Expose Trino port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/v1/info || exit 1

# Set entrypoint
ENTRYPOINT ["/opt/entrypoint.sh"]