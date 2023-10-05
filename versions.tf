terraform {
  required_providers {
    restapi = {
      source = "Mastercard/restapi"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }

  required_version = "1.5.7"
}
