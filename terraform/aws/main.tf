provider "aws" {
  region = var.region
}

resource "aws_security_group" "kiwitcms" {
  name        = "kiwitcms-sg"
  description = "Allow HTTP, HTTPS and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kiwitcms" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.kiwitcms.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker-compose-plugin
              mkdir -p /home/ubuntu/kiwitcms
              cat <<EOT > /home/ubuntu/kiwitcms/docker-compose.yml
              ${file("../../docker-compose.yml")}
              EOT
              cat <<EOT > /home/ubuntu/kiwitcms/.env
              KIWI_DB_PASSWORD=${var.db_password}
              KIWI_DB_HOST=db
              KIWI_DB_NAME=kiwitcms
              KIWI_DB_USER=kiwitcms
              EOT
              cd /home/ubuntu/kiwitcms
              docker compose up -d
              EOF

  tags = {
    Name = "KiwiTCMS-Server"
  }
}
