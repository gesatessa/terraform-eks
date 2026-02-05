# # iam user & iam role for eks cluster

# resource "aws_iam_user" "developer" {
#   name = "${local.prefix}-developer"
# }

# resource "aws_iam_policy" "developer_eks" {
#   name = "${local.prefix}-developer-eks-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = [
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "eks:ListNodeGroups",
#           "eks:ListNodeGroups",
#           "eks:DescribeNodeGroup",
#           "eks:ListFargateProfiles",
#           "eks:DescribeFargateProfile"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }
# resource "aws_iam_user_policy_attachment" "developer_eks_attach" {
#   user       = aws_iam_user.developer.name
#   policy_arn = aws_iam_policy.developer_eks.arn
# }

# # access entry point for eks cluster
# resource "aws_eks_access_entry" "developer" {
#   cluster_name = aws_eks_cluster.eks_cluster.name
#   principal_arn = aws_iam_user.developer.arn
#   kubernetes_groups = ["viwew-only"]
# }


# # iam role for eks cluster
# data "aws_iam_policy_document" "eks_assume_role_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#   }
# }

# # resource "aws_iam_role" "eks_admin" {
# #   name               = "${local.prefix}-eks-cluster-admin"
# #   assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
# # }

# resource "aws_iam_role" "eks" {
#   name               = "${local.prefix}-eks-cluster-role"
#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_policy" "eks_admin" {
#   name = "${local.prefix}-eks-cluster-admin-policy"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = "*"
#         Resource = "*"
#       }
#     ]
#   })
# }
# resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
#   role       = aws_iam_role.eks.name
#   policy_arn = aws_iam_policy.eks_admin.arn
# }
# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
#   role       = aws_iam_role.eks.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
#   role       = aws_iam_role.eks.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSWorkerNodePolicy" {
#   role       = aws_iam_role.eks.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEC2ContainerRegistryReadOnly" {
#   role       = aws_iam_role.eks.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }
