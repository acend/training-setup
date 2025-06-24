terraform {
  required_providers {
    restapi = {
      source = "Mastercard/restapi"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "< 3.0.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    time = {
      source = "hashicorp/time"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  required_version = ">=1.9.0"
}
