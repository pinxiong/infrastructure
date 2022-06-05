# Define the security group for jump server.
resource "aws_security_group" "jump-server" {
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
resource "aws_iam_role" "jump-server" {
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
resource "aws_iam_role_policy_attachment" "jump-server-AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.jump-server.name
}

# Define iam instance profile for ec2 instance of the message transmission service
resource "aws_iam_instance_profile" "jump-server-profile" {
  name = "jump-server-profile"
  role = aws_iam_role.jump-server.name
  tags = merge({
    Name : "Jump Server Profile"
  }, local.tags)
}

# Define the ec2 instance
resource "aws_instance" "jump-server" {
  count                       = 1
  instance_type               = local.instance_type
  ami                         = local.instance_ami
  associate_public_ip_address = true
  hibernation                 = false
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = setunion([aws_security_group.jump-server.id], local.security_group_ids)
  iam_instance_profile        = aws_iam_instance_profile.jump-server-profile.name
  key_name                    = "jump-server"
  user_data                   = <<EOF
#!/bin/bash
mkdir -p /usr/local
cd /usr/local
yum install java-1.8.0 -y
wget https://archive.apache.org/dist/kafka/2.6.2/kafka_2.12-2.6.2.tgz
tar -zxvf kafka_2.12-2.6.2.tgz
rm -rf kafka_2.12-2.6.2.tgz
mv kafka_2.12-2.6.2 kafka

mkdir -p /usr/local/bin
curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
cd /usr/local/bin/
chmod a+x kubectl
echo "export PATH=$PATH:/usr/local/bin" >> /etc/bashrc
cd -

wget https://go.dev/dl/go1.17.8.linux-amd64.tar.gz
tar -zxvf go1.17.8.linux-amd64.tar.gz
rm -rf go1.17.8.linux-amd64.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/bashrc
  EOF
  tags                        = merge({
    Name = "Jumper Server"
  }, local.tags)
}