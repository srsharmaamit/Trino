#!/bin/bash
set -euo pipefail

# Set default values
export TRINO_HOME=${TRINO_HOME:-/opt/trino}
export TRINO_DATA_DIR=${TRINO_DATA_DIR:-/data/trino}

# Create data directory if it doesn't exist
mkdir -p ${TRINO_DATA_DIR}

# Generate node.properties if it doesn't exist
if [ ! -f ${TRINO_HOME}/etc/node.properties ]; then
    cat > ${TRINO_HOME}/etc/node.properties << EOF
node.environment=${NODE_ENVIRONMENT:-production}
node.id=${NODE_ID:-$(uuidgen)}
node.data-dir=${TRINO_DATA_DIR}
EOF
fi

# Generate config.properties for coordinator
if [ "${TRINO_ROLE:-coordinator}" = "coordinator" ]; then
    cat > ${TRINO_HOME}/etc/config.properties << EOF
coordinator=true
node-scheduler.include-coordinator=${INCLUDE_COORDINATOR:-true}
http-server.http.port=8080
discovery.uri=${DISCOVERY_URI:-http://localhost:8080}
query.max-memory=${QUERY_MAX_MEMORY:-4GB}
query.max-memory-per-node=${QUERY_MAX_MEMORY_PER_NODE:-1GB}
query.max-total-memory-per-node=${QUERY_MAX_TOTAL_MEMORY_PER_NODE:-2GB}
discovery-server.enabled=true
EOF
else
    # Worker configuration
    cat > ${TRINO_HOME}/etc/config.properties << EOF
coordinator=false
http-server.http.port=8080
discovery.uri=${DISCOVERY_URI}
query.max-memory-per-node=${QUERY_MAX_MEMORY_PER_NODE:-1GB}
query.max-total-memory-per-node=${QUERY_MAX_TOTAL_MEMORY_PER_NODE:-2GB}
EOF
fi

# Generate jvm.config if it doesn't exist
if [ ! -f ${TRINO_HOME}/etc/jvm.config ]; then
    cat > ${TRINO_HOME}/etc/jvm.config << EOF
-server
-Xmx${JVM_MAX_HEAP:-2G}
-Xms${JVM_MIN_HEAP:-2G}
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-XX:ReservedCodeCacheSize=512M
-XX:PerMethodRecompilationCutoff=10000
-XX:PerBytecodeRecompilationCutoff=10000
-Djdk.attach.allowAttachSelf=true
-Djdk.nio.maxCachedBufferSize=2000000
-XX:+UnlockDiagnosticVMOptions
-XX:+UseAESCTRIntrinsics
EOF
fi

# Start Trino
echo "Starting Trino ${TRINO_VERSION} as ${TRINO_ROLE:-coordinator}..."
echo "Discovery URI: ${DISCOVERY_URI:-http://localhost:8080}"

exec ${TRINO_HOME}/bin/launcher run