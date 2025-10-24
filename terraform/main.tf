locals {
  servers = {
    controller = "controller"
    manager    = "manager"
    workera    = "workera"
    workerb    = "workerb"
  }
}

# Generate SSH key pair
resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.deploy_key.private_key_pem
  filename        = "${path.module}/terraform-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "deploy" {
  key_name   = "devops-terraform-key"
  public_key = tls_private_key.deploy_key.public_key_openssh
}

# Security Group
resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "allow ssh,http,https and swarm ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Docker Swarm (2377)"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Container data"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use Ubuntu 20.04 AMI - ensure AMI ID valid in region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "servers" {
  for_each = local.servers

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deploy.key_name
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = each.key
  }
}

# Create EIPs for manager and workers (controller doesn't require EIP per PDF but you can include)
# Create EIPs and associate to instances
resource "aws_eip" "manager_eip" {
  instance = aws_instance.servers["manager"].id
}

resource "aws_eip" "workera_eip" {
  instance = aws_instance.servers["workera"].id
}

resource "aws_eip" "workerb_eip" {
  instance = aws_instance.servers["workerb"].id
}

output "controller_public_ip" {
  value = aws_instance.servers["controller"].public_ip
}

output "manager_public_ip" {
  value = aws_eip.manager_eip.public_ip
}

output "workera_public_ip" {
  value = aws_eip.workera_eip.public_ip
}

output "workerb_public_ip" {
  value = aws_eip.workerb_eip.public_ip
}

