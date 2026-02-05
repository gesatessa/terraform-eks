data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}
