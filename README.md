# acend training setup

This repository hosts everything related to the setup of acend's trainings, e.g., the Kubernetes cluster creation.

The following flavors are available to setup a Kubernetes Training cluster:

- `k8s`: [https://github.com/acend/terraform-k8s-cluster-lab.git](https://github.com/acend/terraform-k8s-cluster-lab.git)

## Usage

### Deploy Training Cluster

#### Deploy `k8s` Flavor

1. Make sure the module definition for the `k8s` flavor exists in `main.tf` and are not commented out. There should be one `module "training-cluster"` and two `output`
2. Verify module variables, the following usually have to be changed depending on your training setup:
   - `worker_count`: Number of Kubernetes worker nodes. A minimum of 3 is required. Roughly 1 node per 10 students (TODO: TBD and verified!)
   - `cluster_admin`: All user with cluster admin privileges. E.g. `["user1","user2"]`
   - `count-students`: Number of users / students to be deployed.

TODOs and Work in Progress:

- The cluster does have a lot of dependencies between components and therefore the order in which components are installed is vital.
  ArgoCD Resources uses Sync-Waves to honor the order and also Applications are configured with retries.
- Give the deployment process a good amount of time to fully complete. There are also Certificates that needs to be created for the ingresses.
- For troubleshooting, you can use the kubeconfig given in the output `training-kubeconfig`. In order to get this, you need to run
  `terraform output -raw kubeconfig_raw > kubeconfig.yaml` locally. This requires configured credentials terraform state and bootstrap cluster access (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_S3_ENDPOINT`, `KUBE_TOKEN`)

### Destroy Training Cluster

#### Destroy `k8s` Flavor

1. Run the destroy Github Action. This has to be executed before the next step. Otherwise Terraform will fail to execute due to missing provider configs.
2. Comment the `module.training-cluster` and the two `output` in `main.tf` for the `k8s` flavor.
3. Commit the changes.

TODOs and Work in Progress:

- You might need to remove  DNS Records for the training cluster, because Crossplane might be removed before removal of the ingress controller, which prevents removal of the DNS records.

## Concept Training Cluster Setup

```mermaid
flowchart LR
    A(This Git Repository)
    A1(Kubernetes Provider \nfor bootstrap Cluster)
    B(Terraform Module \n for Cluster Provisioning \n Flavor e.g. k8s)
    C{Acend \nBootstrap Cluster\nwith ArgoCD}

    D{Training Cluster\nFlavor: e.g. k8s}

    E(Cloud Provider)


    A --> A1

    A --> B
    B -- deploy infrastructure ---> D
    B -- on --> E
    B -- deploy --> D1
    B -- with --> A1 -- register Cluster \non ArgoCD --> C


    D1(ArgoCD) -- on --> D

    C2-- deploy -->D2(App of Apps)

    D2 -- deploy -->D3(App 1) -- on --> D
    D2 -- deploy -->D4(App 2) -- on --> D
    D2 -- deploy -->D5(App n) -- on --> D

    C -- with --> C1(Applicationset\nCluster generator\nflavor: e.g. k8s)
    C1 -- deploys --> C2(Bootstrap Application\non Training Cluster)  -- on ---> D1
```

### 1. Cluster provisioning using Terraform triggered in GitHub Actions workflows

- Terraform state stored in S3 bucket (on hcloud)
  - The Github Action in this Repository uses the correct secrets and environment variables for this. The Terraform backend is conifgured to use those to store the state.
- Each cluster flavor has its own Terraform module which is in a seperated repository.
- Terraform provider should be configured in root module (if possible) and passed to the module. Otherwise a simple removing of the module definition does not work as Terraform cannot remove the components within the module if provider definition is gone.

Example for the `k8s` flavor cluster:

```hcl
module "training-cluster" {

  source = "git::https://github.com/acend/terraform-k8s-cluster-lab.git//modules/training-cluster"

  providers = {
    restapi.hosttech_dns = restapi.hosttech_dns
    hcloud               = hcloud
    kubernetes.acend     = kubernetes.acend
  }

  # Variables for the cluster
}
```
  
### 2. Register as cluster in the bootstrap Argocd (on acend cluster)

The Kubernetes Terraform provider `acend` is configured with a bootstrap Service Account (provided in the GitHub Action) that allows to create secrets in the `argocd` Namespace. It can also create `clustersecretstores` for the [external secret operator](https://external-secrets.io/).

Example for cluster registration with ArgoCD:

```hcl
resource "kubernetes_secret" "argocd-cluster" {
  provider = kubernetes.acend

  metadata {
    name      = var.cluster_name
    namespace = "argocd"

    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "flavor"                         = "k8s"
      "type"                           = "training"
    }
  }

  data = {
    name   = "${var.cluster_name}.${var.cluster_domain}"
    server = "https://api.${var.cluster_name}.${var.cluster_domain}:6443"
    config = jsonencode({
      tlsClientConfig = {
        caData   = local.kubeconfig.clusters[0].cluster.certificate-authority-data
        certData = local.kubeconfig.users[0].user.client-certificate-data
        keyData  = local.kubeconfig.users[0].user.client-key-data
      }
    })
  }

  type = "Opaque"
}
```

- The name of the secret is the cluster name. This can then be used in the bootstraping ApplicationSet to apply the correct overlay of the bootstraping Repository.
- The certificate in the secret needs to be able to deploy all the needed ArgoCD applications on the training cluster.
- The bootstrapping ApplicationSet is deployed from the main acend infrastructure. Here is an [example](https://github.com/acend/infrastructure/blob/main/deploy/training-cluster/base/argocd-bootstrap-k8s.yaml) for the `k8s` flavor:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: argocd-bootstrap
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          flavor: k8s
          type: training
  template:
    metadata:
      name: 'bootstrap-cluster-{{name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/acend/terraform-k8s-cluster-lab
        targetRevision: HEAD
        path: 'deploy/bootstrap/overlays/{{name}}'
      destination:
        server: '{{server}}'
        namespace: "argocd"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

- use your flavor specific repository for the Application definition.
- if needed, create overlays per cluster to differentiate between clusters. You have to maintain those overlays in your repository. The overlay shall use the cluster name.

Here's an [example](https://github.com/acend/terraform-k8s-cluster-lab/tree/main/deploy/bootstrap) of the bootstraping app for the `k8s` flavored cluster.

Make sure to use the correct labels for your cluster:

- `argocd.argoproj.io/secret-type: cluster` has to be set for ArgoCD to use this as cluster configuration.
- `type: training` indicating this is a training cluster (tbd).
- `flavor` e.g. `k8s` depending on the cluster you created. The ApplicationSet on the bootstrap cluster and the [cluster generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Cluster/) will target this label to deploy the correct bootstrap application.

### 3. Cluster configuration

The `bootstrap` application (deployed from ArgoCD on the bootstraping cluster using the provider cluster configuration with the provisioned secret) shall deploy a [AppOfApps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) Application on the training cluster.
Here's an [example](https://github.com/acend/terraform-k8s-cluster-lab/tree/main/deploy/apps) of the AppOfApps application for the `k8s` flavored cluster.

The AppOfApps Application shall then deploy all necessary components onto the training cluster:

- use Kustomize (when possible) with.
- For Helm Charts we also use [kustomize to generate YAML resources out of a Helm Chart](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md)
- When Argo app is simple (e.g., one or a few files in a kustomize directory), use a centralized repository for all these apps (regardless of which cluster)
- When Argo app is complex, use a dedicated repository

ArgoCD on the training cluster can be deployed from your Terraform cluster module on using the bootstrap application (which is deployed by the bootstrap ArgoCD Cluster).
For the `k8s` flavor, this is done using terraform, as ArgoCD needs to be configured with the local trainee accounts (which are generated in Terraform) and therefore can currently not be deployed from the bootstrapping app.
