#!/bin/bash

# Remove finalizer from our Crossplane resources
# Usage: ./cleanup-crossplane-resources.sh

# Get all object names of kind workspaces.tf.upbound.io with label crossplane.io/claim-kind=GiteaUser
GITEAUSERS=$(kubectl get workspaces.tf.upbound.io -l crossplane.io/claim-kind=GiteaUser -o jsonpath='{.items[*].metadata.name}')
for obj in $GITEAUSERS; do
    ./remove-finalizer.sh workspaces.tf.upbound.io "$obj"
done

# Get all object names of kind workspaces.tf.upbound.io with label crossplane.io/claim-kind=GiteaRepo
GITEAREPOS=$(kubectl get workspaces.tf.upbound.io -l crossplane.io/claim-kind=GiteaRepo -o jsonpath='{.items[*].metadata.name}')
for obj in $GITEAREPOS; do
    ./remove-finalizer.sh workspaces.tf.upbound.io "$obj"
done