packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

variable "api_token" {
  type    = string
  default = "${env("DIGITALOCEAN_TOKEN")}"
}

source "digitalocean" "kiwitcms" {
  api_token    = var.api_token
  image        = "ubuntu-20-04-x64"
  region       = "nyc3"
  size         = "s-1vcpu-1gb"
  ssh_username = "root"
  snapshot_name = "kiwitcms-{{timestamp}}"
}

build {
  sources = ["source.digitalocean.kiwitcms"]

  provisioner "ansible" {
    playbook_file = "playbook.yml"
    user          = "root"
    use_proxy     = false
  }
}
