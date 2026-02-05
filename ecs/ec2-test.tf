# resource "aws_security_group" "test_ssh" {
#   name   = "${local.prefix}-test-ssh"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     # cidr_blocks = ["${var.my_public_ip}/32"]
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress = []

# #   egress {
# #     from_port   = 0
# #     to_port     = 0
# #     protocol    = "-1"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }
# }

# # ssh-keygen -t rsa -b 4096 -f watchlist-api-dev.pub
# resource "aws_key_pair" "this" {
#   key_name   = "${local.prefix}-key"
#   public_key = file("${path.module}/watchlist-api-dev.pub")
# }
# # ssh-keygen -t ed25519 -f watchlist-api-dev -C terraform


# resource "aws_instance" "public_test" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = "t3.micro"
#   # launch in the first public subnet: aws_subnet.public_subnets[0].id
#   subnet_id                   = element(aws_subnet.public_subnets[*].id, 0)
#   vpc_security_group_ids      = [aws_security_group.test_ssh.id]
#   associate_public_ip_address = true
#   key_name                    = aws_key_pair.this.key_name

#   tags = {
#     Name = "${local.prefix}-public-test"
#   }
# }

# # ssh ec2-user@$(terraform output -raw public_test_ip)
# # ssh -i ./deploy/watchlist-api-dev ec2-user@100.53.20.215
# output "public_instance_ip" {
#   value = aws_instance.public_test.public_ip
# }


# =========================================================== #
# private subnet & ssm
# =========================================================== #

# # test for private subnet access (should not be accessible from the internet) ----- #

resource "aws_security_group" "private_test" {
  name   = "${local.prefix}-private-test"
  vpc_id = aws_vpc.main.id

  # Allow outbound internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ssm" {
  name = "${local.prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.prefix}-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "private_test" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.private_subnets[0].id
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  vpc_security_group_ids = [
    aws_security_group.private_test.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              set -eux

              dnf update -y
              dnf install -y postgresql15

              # sanity check
              psql --version
              EOF

  tags = {
    Name = "${local.prefix}-private-test"
    Access = "devops"
  }
}


output "private_instance_id" {
  value = aws_instance.private_test.id
}
