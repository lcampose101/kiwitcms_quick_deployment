provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_firewall" "kiwitcms" {
  name    = "kiwitcms-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "kiwitcms" {
  name         = "kiwitcms-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose-plugin
              systemctl start docker
              systemctl enable docker
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

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "machine_type" {
  default = "e2-micro"
}

variable "ssh_user" {
  default = "kiwi"
}

variable "ssh_public_key" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
