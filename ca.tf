# Add EKS Pod Identity Addon
# This addon is required for using IAM Roles for Service Accounts (IRSA)
# one agent pod is deployed per node group to manage the token projection for pods
# kubectl get pods -n kube-system | grep pod-identity
# kubectl get daemonset -n kube-system pod-identity-agent
# this is required for Cluster Autoscaler to assume the IAM role assigned to it
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "eks-pod-identity-agent"
  # aws eks describe-addon-versions --region us-east-1 --addon-name eks-pod-identity-agent
  addon_version = "v1.3.10-eksbuild.2"
}

# IAM Role for Cluster Autoscaler
# This role will be assumed by the Cluster Autoscaler pods via IRSA
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.prefix}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

}

resource "aws_iam_policy" "ca_policy" {
  name = "${local.prefix}-cluster-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          # +++ just for test: drop them initially to see if CA works +++
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "eks:DescribeNodegroup",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ca_AmazonEKSClusterAutoscalerPolicy" {
  policy_arn = aws_iam_policy.ca_policy.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

# Associate the IAM Role with the Cluster Autoscaler Service Account
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  role_arn        = aws_iam_role.cluster_autoscaler.arn
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
}

# Deploy Cluster Autoscaler via Helm
# resource "helm_release" "cluster_autoscaler" {
#   name       = "cluster-autoscaler"
#   repository = "https://kubernetes.github.io/autoscaler"
#   chart      = "cluster-autoscaler"
#   namespace  = "kube-system"
# #   version    = "9.54.1" # check latest version
# #   values = [
# #     file("${path.module}/values/cluster-autoscaler.yaml")
# #   ]

#     set {
#         name  = "autoDiscovery.clusterName"
#         value = aws_eks_cluster.eks_cluster.name
#     }
#     set {
#         name  = "awsRegion"
#         value = local.region
#     }
#     set {
#         name = "rbac.serviceAccount.name"
#         value = "cluster-autoscaler"
#     }

#   depends_on = [aws_eks_addon.pod_identity]
# }

resource "kubernetes_service_account" "cluster_autoscaler" {
  depends_on = [aws_eks_cluster.eks_cluster]

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}


resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.51.0"
  namespace  = "kube-system"

  timeout         = 180
  atomic          = false
  cleanup_on_fail = false

  wait          = true
  wait_for_jobs = false

  # timeouts {
  #     create = "3m"
  # }

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }

  set {
    name  = "awsRegion"
    value = local.region
  }

  # IMPORTANT: service account handling
  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  # Required args
  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  #   depends_on = [
  #     aws_eks_addon.pod_identity,
  #     aws_eks_pod_identity_association.cluster_autoscaler
  #   ]
  depends_on = [
    aws_eks_addon.pod_identity,
    aws_eks_pod_identity_association.cluster_autoscaler,
    kubernetes_service_account.cluster_autoscaler,
    helm_release.alb_controller,
  ]

}

# Note: Make sure to set the correct cluster name and region in the values file.
