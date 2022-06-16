# Define the security group for jump server.
resource "aws_security_group" "jump_server" {
  name   = "Security group for jump server"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH inbound traffic"
  }

  # Allow all outbound traffic
  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = merge({
    Name : "Security group for jump server"
  }, local.tags)
}

# Define the role to be attached ec2 instance of the jump server
resource "aws_iam_role" "jump_server" {
  name               = "jump-server-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
  tags = merge({
    Name : "Jump Server Role"
  }, local.tags)
}

# Attach the AdministratorAccess policy to jump server role
resource "aws_iam_role_policy_attachment" "jump_server__AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.jump_server.name
}

# Define iam instance profile for ec2 instance of the message transmission service
resource "aws_iam_instance_profile" "jump_server_profile" {
  name = "jump-server-profile"
  role = aws_iam_role.jump_server.name
  tags = merge({
    Name : "Jump Server Profile"
  }, local.tags)
}

# Define the ec2 instance
resource "aws_instance" "jump_server" {
  count                       = 1
  instance_type               = local.instance_type
  ami                         = local.instance_ami
  associate_public_ip_address = true
  hibernation                 = false
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = setunion([aws_security_group.jump_server.id], local.security_group_ids)
  iam_instance_profile        = aws_iam_instance_profile.jump_server_profile.name
  key_name                    = "jump-server"
  user_data                   = <<EOF
#!/bin/bash
mkdir -p /usr/local
cd /usr/local
yum install update -y
yum install java-1.8.0 -y
yum install git -y

mkdir -p /usr/local/bin
curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
cd /usr/local/bin/
chmod a+x kubectl

echo "export PATH=$PATH:/bin:/sbin:/usr/local/bin" >> /etc/bashrc
  EOF
  tags                        = merge({
    Name = "Jumper Server"
  }, local.tags)
}