resource "aws_security_group" "bastion_sg" {
  name        = "${local.prefix}-bastion-sg"
  description = "SSH access to bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------
# IAM role and policy for EKS cluster
resource "aws_iam_role" "bastion" {
  name = "${local.prefix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.prefix}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# -----------------------------------------------
# Bastion Host
resource "aws_key_pair" "this" {
  key_name   = "${local.prefix}-key"
  public_key = file("${path.module}/eks-cluster-demo.pub")
}
# ssh-keygen -t ed25519 -f eks-cluster-demo -C terraform

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.this.key_name

  iam_instance_profile = aws_iam_instance_profile.bastion.name

  tags = {
    Name = "${local.prefix}-bastion"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.bastion_sg.id
}

# ssh -i your-key.pem ec2-user@<BASTION_PUBLIC_IP>
# ssh -i eks-cluster-demo ec2-user@54.174.208.14
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}
