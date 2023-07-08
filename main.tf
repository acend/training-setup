terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "terraform.tfstate"
    region = "main"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}

module "training-cluster" {
  source = "git::https://github.com/acend/terraform-k8s-cluster-lab.git//modules/training-cluster"


  cluster_domain = "cluster.acend.ch"
  cluster_name   = "training"

  worker_count = "2"

  hcloud_api_token     = var.hcloud_api_token
  hosttech_dns_token   = var.hosttech_dns_token
  hosttech-dns-zone-id = var.hosttech_dns_zone_id


  # SSH Public keys deployed on the VM's for SSH access
  extra_ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBH2Z8xf19GNAHY3t/S4kIVTcjDpUI83DG51vG48j8UOM0HodNcH8DnhvLb7WUptNtB056pNFSO5NDLgwa+paZbRzjg/9R5eWAM1q2aBYUrGqJTC2zP7BapA+50oEtKoPYTxQadkMCnEX+C8+Bk12aMPPWuFn85ARrmfA4jpqCbqj5iPzVCKIAKToTJAVM2nnCNpF8I2rHczd6QrZyXbGCMUYqR+Cs+cvcDGxzvew954zUkSRfOoeEfTgWqUQ8bbcL8Y9VZnhcFHCphSKCoFzu/MDlEZzAfnlcjqShUb0Quxo1DX3XaZUnH4rDL3Shnzyf2GQd9RL3cc0mA7DcqfYd sebastian@acend.ch",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVSSqdclkvOOeqvMwxILmIZYcNxLSJ2Mzu3ep5XKa6SaM9el1Qy2p/hDCLCcxSnd09zraRC0v17Vw28i4XVSMMliEQAaWfnKYNOlt7y0/zVMz0zNk7gxeANQMCu8SSMqo9sbJtLoqkUHROc+xG0p2gYWvoczQhMUrgyPLCax720nginO1rsJEcA9W6ICp5nyAQ8ZUlpiBIGOhbMj36UvD3f2gsjx1aF6UMKkYYTLDXEb7OvwyyQkxJjBWY/C4OWS+0nHGArjqdpUMqBQvVGN+5j27a/Nn/Z7cK/X39CELAn1QwC6x3OFzn4gap6kUA1y3n2IZXUUMX9n+IgfvY4Di+ozy/hmM12W2kF9Wp6VzAdMwznW178EJ9fOOoycRYFyQrUOE/kJr+BOfVr1YLxtMYBRQrR6zjET1nrGD/Fjlgv/Xj3jOgOfXl0i0TZXlP0auV30tFxiPac+Z5j42s8Ijl7R+K4puu+gvwVkF4fuly0WR1RSG5z5K6gjd3CxrcYF8= daniel@acend.ch",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrZjA4K3PgqMIsPD1S8DF0K5khvf5WFXJpYo50ygOZ+di5yHgc+grUG7IkC8i6J4m4UPb7VW6Ae70t/6PkLv49NsmUfYWvlL1K6m6QYNYQu8exX7TdRuKF/dcLz0vPvkmcy68spNCIs2/IxIL02L58zf72IbNCLkCr35cqc8EAsGaXMLJM3Vx+8Bjg2oA/tsI7+eqMlKIwfOk0jkQwZQAy38MZtDYJ3crISIZknv6NGK7HDx4LGZifRxe04nxB1xZlgWO6jzl4DrH96EyxgUqLO/Rc0X92ugKmIUZ9ZyCOB1jVAbGmt8dH2rgEX41PHkplQhfv6AybQ22jDX6BcGZv"
  ]

  cluster_admin = ["user1", "user2", "user3","user4","user5"]

  # Webshell
  count-students = 0

  # User VMs
  user-vms-enabled = false

  # RBAC in Webshell
  webshell-rbac-enabled = true
}
