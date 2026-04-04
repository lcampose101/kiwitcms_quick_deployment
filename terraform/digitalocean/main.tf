terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "kiwitcms" {
  image  = var.image_id
  name   = "kiwitcms-server"
  region = var.region
  size   = var.size
  ssh_keys = [var.ssh_key_id]

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/kiwi/kiwitcms
              cat <<EOT > /home/kiwi/kiwitcms/docker-compose.yml
              ${file("../../docker-compose.yml")}
              EOT
              cat <<EOT > /home/kiwi/kiwitcms/.env
              KIWI_DB_PASSWORD=${var.db_password}
              KIWI_DB_HOST=db
              KIWI_DB_NAME=kiwitcms
              KIWI_DB_USER=kiwitcms
              EOT
              chown -R kiwi:kiwi /home/kiwi/kiwitcms
              cd /home/kiwi/kiwitcms
              docker compose up -d
              EOF
}

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "image_id" {
  description = "The ID of the custom snapshot built by Packer"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  default     = "nyc3"
}

variable "size" {
  description = "Droplet size"
  default     = "s-1vcpu-1gb"
}

variable "ssh_key_id" {
  description = "ID or fingerprint of the SSH key"
  type        = string
}

variable "db_password" {
  description = "Kiwi TCMS database password"
  type        = string
  sensitive   = true
}
