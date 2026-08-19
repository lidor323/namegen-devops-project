resource "aws_vpc" "namegen" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "namegen-vpc"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.namegen.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "namegen-public-a"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.namegen.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "namegen-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.namegen.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "namegen-private-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.namegen.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                              = "namegen-private-b"
    "kubernetes.io/role/internal-elb" = "1"
  }

}

resource "aws_internet_gateway" "namegen" {
  vpc_id = aws_vpc.namegen.id

  tags = {
    Name = "namegen-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.namegen.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.namegen.id
  }

  tags = {
    Name = "namegen-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "namegen-nat-eip"
  }
}
resource "aws_nat_gateway" "namegen" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.namegen]

  tags = {
    Name = "namegen-nat"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.namegen.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.namegen.id
  }

  tags = {
    Name = "namegen-private-rt"
  }
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
