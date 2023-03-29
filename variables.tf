variable "hcloud_api_token" {
  type      = string
  sensitive = true
}

variable "hosttech_dns_token" {
  type        = string
  description = "hosttech dns api token"
}

variable "hosttech-dns-zone-id" {
  type        = string
  description = "Zone ID of the hosttech DNS Zone where LoadBalancer A/AAAA records are created"
}
