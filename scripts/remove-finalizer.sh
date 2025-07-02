#!/bin/bash

# Remove all finalizers from a Kubernetes object
# Usage: ./remove-finalizers.sh <resource-type> <resource-name> [namespace]

RESOURCE_TYPE=$1
RESOURCE_NAME=$2
NAMESPACE=$3

if [ -z "$RESOURCE_TYPE" ] || [ -z "$RESOURCE_NAME" ]; then
    echo "Usage: $0 <resource-type> <resource-name> [namespace]"
    echo "Example: $0 pod my-pod default"
    echo "Example: $0 pvc my-pvc my-namespace"
    exit 1
fi

# Build kubectl command
if [ -n "$NAMESPACE" ]; then
    KUBECTL_CMD="kubectl patch $RESOURCE_TYPE $RESOURCE_NAME -n $NAMESPACE"
else
    KUBECTL_CMD="kubectl patch $RESOURCE_TYPE $RESOURCE_NAME"
fi

# Remove finalizers by setting the array to empty
$KUBECTL_CMD --type='merge' -p='{"metadata":{"finalizers":null}}'

echo "Finalizers removed from $RESOURCE_TYPE/$RESOURCE_NAME"