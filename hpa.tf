# data "aws_eks_cluster" "main" {
#   name = aws_eks_cluster.eks_cluster.name
# }

# data "aws_eks_cluster_auth" "main" {
#   name = aws_eks_cluster.eks_cluster.name
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.main.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.main.token
#   }
# }

# metrics server must be deployed in the cluster for HPA to work
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  # https://github.com/kubernetes-sigs/metrics-server/releases
  version = "3.13.0"

  values = [
    file("${path.module}/values/metrics-server.yaml")
  ]

  depends_on = [aws_eks_node_group.eks_node_group]
}


# resource "kubernetes_horizontal_pod_autoscaler" "example" {
#   metadata {
#     name      = "example-hpa"
#     namespace = "default"
#   }

#   spec {
#     max_replicas = 10
#     min_replicas = 1

#     scale_target_ref {
#       kind       = "Deployment"
#       name       = "example-deployment"
#       api_version = "apps/v1"
#     }

#     target_cpu_utilization_percentage = 50
#   }
# }