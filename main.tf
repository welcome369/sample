provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket369"
    key            = "terraform/remote-backend/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}

# Generate a key pair (you can also import an existing public key)
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "public-key" {
  key_name   = "my-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}

# Save the private key locally (optional, but helpful)
resource "local_file" "private_key" {
  content  = tls_private_key.keypair.private_key_pem
  filename = "/home/jenkins/ec2/my-keypair.pem"
  file_permission = "0400"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-allow-ssh-http"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.default.id  # Uses the default VPC

  # Inbound rules
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule (default allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"   # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-allow-ssh-http"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-0f918f7e67a3323f0"
  instance_type          = "t3.micro"
  key_name      = aws_key_pair.public-key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

   tags = {
    Name = "EC2 instance with remote provisioner"
   }

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = tls_private_key.keypair.private_key_pem  # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
      "sudo apt install nginx -y",
    ]
  }
}
