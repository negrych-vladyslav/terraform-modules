#-------------------------------------------------------------------------------
data "aws_availability_zones" "available" {}
#-------------------------------------------------------------------------------
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = element(var.public_subnet_cidr, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-public-${count.index + 1}"
  }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env}-route-public-subnets"
  }
}
resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}
#-------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidr)
  vpc   = true
  tags = {
    Name = "${var.env}-nat-eip-${count.index + 1}"
  }
}
resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}
#-------------------------------------------------------------------------------
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(var.private_subnet_cidr, count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.env}-private-${count.index + 1}"
  }
}
resource "aws_route_table" "private_subnets" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env}-route-private-subnets"
  }
}
resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets.id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}
#-------------------------------------------------------------------------------
