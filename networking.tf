resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # Enable DNS support and hostnames for the VPC
  # This is required for EKS clusters to function properly, because
  # the worker nodes need to resolve the cluster endpoint.
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

# public subnets ============================== #

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-igw"
  }
}

# resource "aws_subnet" "public1" {
#   vpc_id = aws_vpc.main.id
#   cidr_block = "10.0.1.0/24"
#   availability_zone = local.zones[0]
#   # Enable public IP addresses for instances launched in this subnet
#     map_public_ip_on_launch = true 

#     tags = {
#     Name = "${local.prefix}-public-subnet-1"
#     }

# }

# create 2 subnets in a loop
resource "aws_subnet" "public" {
  count                   = length(local.zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                               = "${local.prefix}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name_full}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public-rt"
  }
}

resource "aws_route" "public_rt_route" {
  route_table_id = aws_route_table.public_rt.id
  # This route directs all outbound traffic to the internet gateway
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# private subnets ============================== #

# eip and nat gateway for private subnets
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${local.prefix}-nat-eip"
  }
}

# one nat gateway for the VPC
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.prefix}-nat-gw"
  }
}

resource "aws_subnet" "private" {
  count                   = length(local.zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 11)
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                                               = "${local.prefix}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name_full}" = "shared"
    "kubernetes.io/role/internal-elb"                  = "1"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-private-rt"
  }
}

resource "aws_route" "private_rt_route" {
  route_table_id = aws_route_table.private_rt.id
  # This route directs all outbound traffic to the NAT gateway
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

