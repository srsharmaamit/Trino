# Trino 446 Deployment Package - Complete Overview

## 📁 Directory Structure

```
trino-deployment/
├── docker/                          # Docker image files
│   ├── Dockerfile                   # Multi-stage Trino 446 image
│   ├── entrypoint.sh               # Smart container entrypoint
│   ├── build.sh                    # Docker build script
│   └── config/                     # Default Trino configuration
│       ├── log.properties          # Logging configuration
│       └── catalog/                # Connector configurations
│           ├── tpch.properties     # TPCH benchmark connector
│           └── tpcds.properties    # TPCDS benchmark connector
│
├── helm-chart/                     # Kubernetes/OpenShift deployment
│   ├── Chart.yaml                 # Helm chart metadata
│   ├── values.yaml                # Default configuration values
│   └── templates/                 # Kubernetes resource templates
│       ├── _helpers.tpl           # Template helpers
│       ├── coordinator-deployment.yaml    # Coordinator deployment
│       ├── coordinator-service.yaml       # Coordinator service
│       ├── worker-deployment.yaml         # Worker deployment
│       ├── configmap.yaml         # Configuration management
│       ├── pvc.yaml               # Persistent storage
│       ├── route.yaml             # OpenShift route (load balancer)
│       └── rbac.yaml              # Security permissions
│
├── examples/                       # Environment-specific configurations
│   ├── values-dev.yaml            # Development environment
│   └── values-prod.yaml           # Production environment
│
├── docs/                          # Documentation
│   └── deployment-guide.md        # Detailed deployment instructions
│
├── deploy.sh                      # Automated deployment script
├── status.sh                      # Health check and status script
└── README.md                      # Main documentation
```

## 🚀 Key Features

### Docker Image (Trino 446)
- ✅ **Exact Version**: Trino 446 specifically built and configured
- ✅ **Java 17**: Latest LTS Java runtime for optimal performance
- ✅ **Non-root User**: Security-hardened container (UID 1000)
- ✅ **Health Checks**: Built-in health monitoring
- ✅ **Flexible Configuration**: Environment-driven setup
- ✅ **Discovery URI**: Properly configured for cluster communication

### Helm Chart (OpenShift Ready)
- ✅ **OpenShift Compatibility**: Routes, SCCs, and security contexts
- ✅ **Load Balancer Integration**: Automatic external access via OpenShift Route
- ✅ **High Availability**: Coordinator + multiple workers
- ✅ **Persistent Storage**: Data persistence for coordinator
- ✅ **Resource Management**: CPU and memory limits/requests
- ✅ **Configuration Management**: ConfigMaps for connectors

### Discovery URI Configuration
- ✅ **Internal DNS**: `http://{{ release-name }}-coordinator:8080`
- ✅ **Service Discovery**: Automatic coordinator discovery
- ✅ **Worker Registration**: Seamless worker-coordinator communication
- ✅ **Load Balancer Ready**: External access via OpenShift Route

## 📋 Quick Start Commands

### 1. Build Docker Image
```bash
cd docker/
./build.sh
```

### 2. Deploy to OpenShift
```bash
# Development environment
./deploy.sh dev trino-dev

# Production environment  
./deploy.sh prod trino-prod
```

### 3. Check Status
```bash
./status.sh trino-dev
```

### 4. Access Trino UI
```bash
# Get route URL
oc get route trino-ui -o jsonpath='{.spec.host}'
```

## 🔧 Configuration Highlights

### Discovery URI Setup
The discovery URI is automatically configured to ensure proper cluster communication:

**Coordinator**: `discovery.uri=http://{{ release-name }}-coordinator:8080`
**Workers**: Connect to coordinator via internal service DNS

### OpenShift Route Configuration
```yaml
openshift:
  route:
    enabled: true
    host: ""  # Auto-generated or custom domain
    tls:
      termination: edge
      insecureEdgeTerminationPolicy: Redirect
```

### Resource Allocation
- **Development**: 1 coordinator + 1 worker (minimal resources)
- **Production**: 1 coordinator + 5 workers (enterprise-grade resources)

## 🛠 Customization Options

### 1. Add Database Connectors
```yaml
configMap:
  data:
    postgresql.properties: |
      connector.name=postgresql
      connection-url=jdbc:postgresql://db:5432/warehouse
```

### 2. Scale Workers
```yaml
trino:
  worker:
    replicaCount: 10  # Scale based on workload
```

### 3. Adjust Memory
```yaml
trino:
  jvm:
    maxHeapSize: "16G"
  query:
    maxMemory: "32GB"
```

## 🔒 Security Features

- **Non-root containers** (UID 1000)
- **OpenShift Security Context Constraints**
- **RBAC permissions** for service accounts
- **TLS termination** at load balancer
- **Network policies** ready

## 📊 Monitoring & Troubleshooting

### Health Endpoints
- **Info**: `http://coordinator:8080/v1/info`
- **Cluster**: `http://coordinator:8080/v1/cluster`
- **Node**: `http://coordinator:8080/v1/node`

### Useful Commands
```bash
# Check logs
oc logs deployment/trino-coordinator

# Connect to CLI
oc exec -it deployment/trino-coordinator -- /opt/trino/bin/trino --server http://localhost:8080

# Monitor resources
oc adm top pods
```

## 🎯 Production Checklist

- [ ] Build and push Docker image to registry
- [ ] Update `values-prod.yaml` with registry URL
- [ ] Configure persistent storage class
- [ ] Set up monitoring and alerting
- [ ] Configure database connectors
- [ ] Test failover scenarios
- [ ] Set up backup procedures

## 📞 Support

- **Trino Issues**: [Trino Documentation](https://trino.io/docs/)
- **OpenShift Issues**: [OpenShift Documentation](https://docs.openshift.com/)
- **Kubernetes Issues**: [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Ready to Deploy!** 🎉

This package provides everything needed to deploy Trino 446 on OpenShift with proper discovery URI configuration and load balancer access.