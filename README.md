# acend training setup

This repository hosts everything related to the setup of acend's trainings, e.g., the Kubernetes cluster creation.


## Initially discussed requirements for the cluster setup 

- Cluster provisioning in one click
- Multiple clusters can be run in parallel
- "Customizable" domain/cluster name


## Workflow

- Cluster provisioning using Terraform triggered in GitHub Actions workflows
  - Terraform state stored in S3 bucket
- Cluster configuration (where possible) using Kustomize (when possible) and Argo CD
  - Cluster and Argo CD up and running
- Training setup using Kustomize (when possible) and Argo CD
  - When Argo app is simple (e.g., one or a few files in a kustomize directory), use a centralized repository for all these apps (regardless of which cluster)
  - When Argo app is complex, use a dedicated repository
