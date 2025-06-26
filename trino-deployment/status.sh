#!/bin/bash
set -e

# Trino Status Check Script
# Usage: ./status.sh [release-name] [namespace]

RELEASE_NAME=${1:-trino}
NAMESPACE=${2:-trino}

echo "Checking Trino deployment status..."
echo "Release Name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"

# Switch to namespace
oc project $NAMESPACE 2>/dev/null || {
    echo "Error: Namespace $NAMESPACE not found"
    exit 1
}

echo ""
echo "Helm Release Status:"
echo "==================="
helm status $RELEASE_NAME

echo ""
echo "Pod Status:"
echo "==========="
oc get pods -l app.kubernetes.io/instance=$RELEASE_NAME

echo ""
echo "Service Status:"
echo "==============="
oc get svc -l app.kubernetes.io/instance=$RELEASE_NAME

echo ""
echo "Route Status:"
echo "============="
oc get route -l app.kubernetes.io/instance=$RELEASE_NAME

echo ""
echo "Persistent Volume Claims:"
echo "========================"
oc get pvc -l app.kubernetes.io/instance=$RELEASE_NAME

echo ""
echo "Recent Events:"
echo "=============="
oc get events --sort-by='.lastTimestamp' | grep $RELEASE_NAME | tail -10

echo ""
echo "Resource Usage:"
echo "==============="
oc adm top pods -l app.kubernetes.io/instance=$RELEASE_NAME 2>/dev/null || echo "Metrics not available"

echo ""
echo "Health Check:"
echo "============="
COORDINATOR_POD=$(oc get pods -l app.kubernetes.io/instance=$RELEASE_NAME,component=coordinator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$COORDINATOR_POD" ]; then
    echo "Testing Trino info endpoint..."
    oc exec $COORDINATOR_POD -- curl -f http://localhost:8080/v1/info 2>/dev/null && echo "✓ Coordinator is healthy" || echo "✗ Coordinator health check failed"
else
    echo "✗ Coordinator pod not found"
fi

echo ""
echo "Access Information:"
echo "=================="
ROUTE_HOST=$(oc get route ${RELEASE_NAME}-ui -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -n "$ROUTE_HOST" ]; then
    echo "Trino UI: https://$ROUTE_HOST"
else
    echo "Port-forward command: oc port-forward svc/${RELEASE_NAME}-coordinator 8080:8080"
fi