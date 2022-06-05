# Define the role to be attached EKS
resource "aws_iam_role" "eks_role" {
  name               = "eks-role"
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
            "eks.amazonaws.com",
          ]
        }
      }
    ]
  })
  tags = merge({
    Name : "EKS Role"
  }, local.tags)
}

# Attach the CloudWatchFullAccess policy to EKS role
resource "aws_iam_role_policy_attachment" "eks_CloudWatchFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

# Optionally, enable Security Groups for Pods
resource "aws_iam_role_policy_attachment" "eks_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

# Default Security Group of EKS
resource "aws_security_group" "security_group" {
  name        = "${local.name} Security Group"
  description = "Default SG to allow traffic from the EKS"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups = local.security_group_ids
  }

  tags = merge({
    Name = "${local.name} Security Group"
  }, local.tags)

}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name    = local.name
  version = "1.22"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  role_arn = aws_iam_role.eks_role.arn

  timeouts {}

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [
      "0.0.0.0/0",
    ]
    security_group_ids = [
      aws_security_group.security_group.id
    ]
    subnet_ids = flatten([var.public_subnets_id, var.private_subnets_id])
  }

  tags = merge({
    Name = local.name
  }, local.tags)
}

######################### Node Group ############################

resource "aws_iam_role" "node_group_role" {
  name                  = format("%s-node-group-role", lower(aws_eks_cluster.eks.name))
  path                  = "/"
  force_detach_policies = false
  max_session_duration  = 3600
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2RoleforSSM" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_iam_role_policy_attachment" "node_group_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group_role.id
}

resource "aws_eks_node_group" "node_group" {
  cluster_name  = aws_eks_cluster.eks.name
  disk_size     = 0
  capacity_type = "SPOT"
  labels        = {
    "eks/cluster-name"   = aws_eks_cluster.eks.name
    "eks/nodegroup-name" = format("nodegroup_%s", lower(aws_eks_cluster.eks.name))
  }
  node_group_name = format("nodegroup_%s", lower(aws_eks_cluster.eks.name))
  node_role_arn   = aws_iam_role.node_group_role.arn

  subnet_ids = local.private_subnets_id

  instance_types = ["t2.micro","t3.micro"]

  scaling_config {
    desired_size = local.desired_size
    max_size     = local.max_size
    min_size     = local.min_size
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Name                 = local.name
    "eks/cluster-name"   = local.name
    "eks/nodegroup-name" = format("%s Node Group", aws_eks_cluster.eks.name)
    "eks/nodegroup-type" = "managed"
  }, local.tags)
}
