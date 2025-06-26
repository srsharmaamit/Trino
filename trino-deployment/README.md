# Trino 446 Docker Image and Helm Chart for OpenShift

This repository contains a Docker image and Helm chart for deploying Trino version 446 on OpenShift.

## Architecture

- **Coordinator**: Single instance that handles query planning and coordination
- **Workers**: Multiple instances that execute query fragments
- **Discovery URI**: Properly configured for internal cluster communication
- **OpenShift Route**: External access to Trino UI via load balancer

## Quick Start

### Building the Docker Image

1. Navigate to the docker directory:
   ```bash
   cd docker/
   ```

2. Build the image:
   ```bash
   ./build.sh
   ```

3. (Optional) Push to your registry:
   ```bash
   docker tag trino:446 your-registry.com/trino:446
   docker push your-registry.com/trino:446
   ```

### Deploying with Helm

1. Install the Helm chart:
   ```bash
   helm install trino ./helm-chart/
   ```

2. Or with custom values:
   ```bash
   helm install trino ./helm-chart/ -f custom-values.yaml
   ```

3. Check the deployment:
   ```bash
   oc get pods -l app.kubernetes.io/name=trino
   oc get route trino-ui
   ```

## Configuration

### Discovery URI

The discovery URI is automatically configured as:
```
http://{{ release-name }}-trino-coordinator:8080
```

This ensures proper internal communication between coordinator and workers.

### External Access

The Trino UI is accessible via OpenShift Route:
- **Route Name**: `{{ release-name }}-trino-ui`
- **Port**: 8080
- **TLS**: Edge termination enabled by default

### Resource Requirements

Default resource allocation:
- **Coordinator**: 2 CPU cores, 4GB RAM
- **Worker**: 1 CPU core, 2GB RAM

### Storage

- **Coordinator**: Persistent volume for data (10GB by default)
- **Workers**: Ephemeral storage (no persistence needed)

## Customization

### Adding Connectors

To add custom connectors, modify the `configMap` section in `values.yaml`:

```yaml
configMap:
  create: true
  data:
    mysql.properties: |
      connector.name=mysql
      connection-url=jdbc:mysql://mysql-server:3306
      connection-user=trino
      connection-password=password
```

### Scaling Workers

To scale workers:

```yaml
trino:
  worker:
    replicaCount: 5  # Increase number of workers
```

### Memory Configuration

Adjust JVM and query memory:

```yaml
trino:
  jvm:
    maxHeapSize: "4G"
    minHeapSize: "4G"
  query:
    maxMemory: "8GB"
    maxMemoryPerNode: "2GB"
```

## OpenShift Specific Features

### Security Context

The chart includes proper security contexts for OpenShift:
- Non-root user (UID 1000)
- FSGroup 1000
- Read-only root filesystem where possible

### Routes

OpenShift Routes are used instead of Ingress for external access:
- Automatic SSL termination
- Integration with OpenShift load balancer
- Proper hostname generation

### Storage Classes

The chart supports OpenShift storage classes:
```yaml
persistence:
  storageClass: "gp2"  # AWS EBS
  # or
  storageClass: "fast-ssd"  # Custom storage class
```

## Monitoring and Troubleshooting

### Health Checks

The deployment includes:
- **Liveness Probe**: `/v1/info` endpoint
- **Readiness Probe**: `/v1/info` endpoint

### Logs

View logs:
```bash
# Coordinator logs
oc logs deployment/trino-coordinator

# Worker logs
oc logs deployment/trino-worker
```

### Accessing Trino CLI

Connect to the coordinator pod:
```bash
oc exec -it deployment/trino-coordinator -- /opt/trino/bin/trino --server http://localhost:8080
```

## Security Considerations

### Network Policies

Consider implementing network policies to restrict traffic:
- Allow coordinator to worker communication
- Allow external access only to coordinator UI
- Restrict database access to specific pods

### Secrets Management

For production deployments:
- Store database credentials in OpenShift Secrets
- Use service accounts with minimal permissions
- Enable HTTPS for all communications

## Production Recommendations

1. **Resource Limits**: Set appropriate CPU and memory limits
2. **Persistent Storage**: Use high-performance storage for coordinator
3. **Backup Strategy**: Implement backup for configuration and metadata
4. **Monitoring**: Deploy Prometheus metrics collection
5. **Alerting**: Set up alerts for failed queries and resource usage

## Support

For issues specific to:
- **Trino**: Check [Trino Documentation](https://trino.io/docs/)
- **OpenShift**: Consult [OpenShift Documentation](https://docs.openshift.com/)
- **Kubernetes**: See [Kubernetes Documentation](https://kubernetes.io/docs/)