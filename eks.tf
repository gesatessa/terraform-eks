# eks assume role policy
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# eks iam role
# this role will be used by the EKS cluster to manage AWS resources on your behalf
# why role? because EKS needs permissions to create and manage resources like load balancers, security groups, etc.
# these permissions are granted via IAM policies attached to this role
# the role is assumed by the EKS service
# the assume role policy defines who can assume this role
# in this case, the EKS service
# role vs. user: a role is an AWS identity with specific permissions, while a user is an individual identity with long-term credentials
# roles are used for services and applications, while users are for humans
# roles can be assumed temporarily, while users have permanent credentials
resource "aws_iam_role" "eks" {
  name               = "${local.prefix}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

}
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "${local.prefix}-cluster"
  version  = local.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    # The subnet IDs where the EKS cluster will be deployed
    endpoint_private_access = false # make the cluster endpoint public
    endpoint_public_access  = true  # make the cluster endpoint public

    subnet_ids = aws_subnet.private[*].id
  }

  # access configuration
  # this block configures how users and applications can access the EKS cluster
  access_config {
    authentication_mode = "API" # use API for authentication

    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensure the EKS cluster is created only after the IAM role policy is attached
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# Output the EKS cluster endpoint
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}


# node group iam role
data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  name               = "${local.prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json

}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  version         = local.eks_version
  node_group_name = "${local.prefix}-ng"

  node_role_arn = aws_iam_role.eks_node.arn
  subnet_ids    = aws_subnet.private[*].id
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
  # capacity_type  = "ON_DEMAND"
  capacity_type  = "SPOT"
  instance_types = ["t3.small"]

  update_config {
    # Number of nodes that can be unavailable during the update
    # this helps maintain cluster availability
    max_unavailable = 1
  }

  labels = {
    Environment = local.environment
    Team        = "DevOps"
    role        = "worker-node-general"
  }

  tags = {
    Name                                                            = "${local.prefix}-eks-node-group"
    "k8s.io/cluster-autoscaler/enabled"                             = "true"
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks_cluster.name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}


# 
resource "null_resource" "wait_for_nodes" {
  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name} --region ${local.region}
kubectl wait --for=condition=Ready nodes --all --timeout=10m
kubectl wait --for=condition=Ready pods -n kube-system --all --timeout=10m
EOT
  }

  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}
