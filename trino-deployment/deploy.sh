#!/bin/bash
set -e

# Trino Deployment Script for OpenShift
# Usage: ./deploy.sh [dev|prod] [release-name]

ENVIRONMENT=${1:-dev}
RELEASE_NAME=${2:-trino}
NAMESPACE=${3:-trino}

echo "Deploying Trino $ENVIRONMENT environment..."
echo "Release Name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"

# Check if oc is available
if ! command -v oc &> /dev/null; then
    echo "Error: oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm not found. Please install Helm 3.x."
    exit 1
fi

# Create namespace if it doesn't exist
echo "Creating namespace if it doesn't exist..."
oc create namespace $NAMESPACE --dry-run=client -o yaml | oc apply -f -

# Switch to namespace
oc project $NAMESPACE

# Deploy based on environment
case $ENVIRONMENT in
    dev)
        echo "Deploying development environment..."
        helm upgrade --install $RELEASE_NAME ./helm-chart/ \
            -f examples/values-dev.yaml \
            --namespace $NAMESPACE
        ;;
    prod)
        echo "Deploying production environment..."
        helm upgrade --install $RELEASE_NAME ./helm-chart/ \
            -f examples/values-prod.yaml \
            --namespace $NAMESPACE
        ;;
    *)
        echo "Usage: $0 [dev|prod] [release-name] [namespace]"
        exit 1
        ;;
esac

echo "Waiting for deployment to be ready..."
oc wait --for=condition=available --timeout=300s deployment/${RELEASE_NAME}-coordinator

echo "Deployment completed successfully!"
echo ""
echo "Access Information:"
echo "=================="

# Get route information
ROUTE_HOST=$(oc get route ${RELEASE_NAME}-ui -o jsonpath='{.spec.host}' 2>/dev/null || echo "No route found")
if [ "$ROUTE_HOST" != "No route found" ]; then
    echo "Trino UI: https://$ROUTE_HOST"
else
    echo "Trino UI: Port-forward using 'oc port-forward svc/${RELEASE_NAME}-coordinator 8080:8080'"
fi

echo ""
echo "Useful Commands:"
echo "==============="
echo "Check pods: oc get pods -l app.kubernetes.io/instance=$RELEASE_NAME"
echo "View logs: oc logs deployment/${RELEASE_NAME}-coordinator"
echo "Connect CLI: oc exec -it deployment/${RELEASE_NAME}-coordinator -- /opt/trino/bin/trino --server http://localhost:8080"
echo ""
echo "To uninstall: helm uninstall $RELEASE_NAME"