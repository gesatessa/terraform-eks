locals {
  environment       = "staging"
  region            = "us-east-1"
  zones             = ["us-east-1a", "us-east-1b"]
  cluster_name      = "movies"
  eks_version       = "1.33"
  prefix            = "${local.environment}-${local.cluster_name}"
  cluster_name_full = "${local.prefix}-cluster"
}
