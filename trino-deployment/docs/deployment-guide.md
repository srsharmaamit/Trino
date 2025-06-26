# Trino 446 Deployment Guide for OpenShift

## Prerequisites

- OpenShift cluster with appropriate permissions
- Docker/Podman for building images
- Helm 3.x installed
- `oc` CLI tool configured

## Step-by-Step Deployment

### 1. Build and Push Docker Image

```bash
# Navigate to docker directory
cd docker/

# Build the image
./build.sh

# Tag for your registry
docker tag trino:446 your-registry.com/trino:446

# Push to registry
docker push your-registry.com/trino:446
```

### 2. Create OpenShift Project

```bash
# Create new project
oc new-project trino-production

# Or use existing project
oc project trino-production
```

### 3. Configure Image Registry

Update `values.yaml` with your registry:

```yaml
image:
  repository: your-registry.com/trino
  tag: "446"
```

### 4. Deploy with Helm

#### Basic Deployment

```bash
helm install trino ./helm-chart/
```

#### Production Deployment

```bash
# Create custom values file
cat > production-values.yaml << EOF
trino:
  coordinator:
    replicaCount: 1
  worker:
    replicaCount: 3
  jvm:
    maxHeapSize: "8G"
    minHeapSize: "8G"
  query:
    maxMemory: "16GB"
    maxMemoryPerNode: "4GB"

resources:
  coordinator:
    limits:
      cpu: 4000m
      memory: 12Gi
    requests:
      cpu: 2000m
      memory: 8Gi
  worker:
    limits:
      cpu: 2000m
      memory: 6Gi
    requests:
      cpu: 1000m
      memory: 4Gi

persistence:
  enabled: true
  size: 50Gi
  storageClass: "fast-ssd"

openshift:
  route:
    host: trino.your-domain.com
EOF

# Deploy with production values
helm install trino ./helm-chart/ -f production-values.yaml
```

### 5. Verify Deployment

```bash
# Check pods
oc get pods -l app.kubernetes.io/name=trino

# Check services
oc get svc

# Check route
oc get route trino-ui

# Check logs
oc logs deployment/trino-coordinator
```

### 6. Access Trino UI

```bash
# Get route URL
TRINO_URL=$(oc get route trino-ui -o jsonpath='{.spec.host}')
echo "Trino UI: https://$TRINO_URL"
```

## Configuration Examples

### Adding Database Connectors

#### PostgreSQL Connector

```yaml
configMap:
  create: true
  data:
    postgresql.properties: |
      connector.name=postgresql
      connection-url=jdbc:postgresql://postgres:5432/database
      connection-user=trino
      connection-password=secret
```

#### MySQL Connector

```yaml
configMap:
  create: true
  data:
    mysql.properties: |
      connector.name=mysql
      connection-url=jdbc:mysql://mysql:3306/database
      connection-user=trino
      connection-password=secret
```

### Scaling Configuration

#### High Availability Setup

```yaml
trino:
  coordinator:
    replicaCount: 1  # Always 1 for coordinator
  worker:
    replicaCount: 5  # Scale based on workload

# Anti-affinity for workers
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            component: worker
        topologyKey: kubernetes.io/hostname
```

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod events
oc describe pod <pod-name>

# Check resource constraints
oc get nodes
oc describe node <node-name>
```

#### 2. Discovery Issues

```bash
# Verify service resolution
oc exec deployment/trino-worker -- nslookup trino-coordinator

# Check coordinator logs
oc logs deployment/trino-coordinator | grep -i discovery
```

#### 3. Memory Issues

```bash
# Check memory usage
oc top pods

# Adjust JVM settings
helm upgrade trino ./helm-chart/ --set trino.jvm.maxHeapSize=4G
```

### Monitoring Commands

```bash
# Watch pod status
watch oc get pods

# Monitor resource usage
oc adm top pods

# Check cluster info
oc get nodes -o wide
```

## Security Hardening

### 1. Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: trino-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: trino
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: trino
    ports:
    - protocol: TCP
      port: 8080
```

### 2. Security Context Constraints

```yaml
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: trino-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
runAsUser:
  type: MustRunAs
  uid: 1000
fsGroup:
  type: MustRunAs
  ranges:
  - min: 1000
    max: 1000
```

## Backup and Restore

### Backup Configuration

```bash
# Backup Helm release
helm get values trino > trino-backup-values.yaml

# Backup persistent data
oc exec deployment/trino-coordinator -- tar -czf /tmp/backup.tar.gz /data/trino
oc cp trino-coordinator-pod:/tmp/backup.tar.gz ./backup.tar.gz
```

### Restore Process

```bash
# Restore from backup
oc cp ./backup.tar.gz trino-coordinator-pod:/tmp/
oc exec deployment/trino-coordinator -- tar -xzf /tmp/backup.tar.gz -C /
```

## Performance Tuning

### JVM Tuning

```yaml
trino:
  jvm:
    maxHeapSize: "8G"
    minHeapSize: "8G"
    additionalOptions:
      - "-XX:+UseG1GC"
      - "-XX:G1HeapRegionSize=32M"
      - "-XX:+UseGCOverheadLimit"
```

### Query Optimization

```yaml
trino:
  query:
    maxMemory: "20GB"
    maxMemoryPerNode: "4GB"
    maxTotalMemoryPerNode: "6GB"
```

## Maintenance

### Regular Updates

```bash
# Update Helm chart
helm upgrade trino ./helm-chart/ -f production-values.yaml

# Rolling restart
oc rollout restart deployment/trino-coordinator
oc rollout restart deployment/trino-worker
```

### Health Checks

```bash
# Verify health
curl -f http://trino-coordinator:8080/v1/info

# Check cluster status
curl -f http://trino-coordinator:8080/v1/cluster
```