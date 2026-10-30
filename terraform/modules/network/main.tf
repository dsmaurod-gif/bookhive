locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefijo}-vpc"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-igw"
  }
}

resource "aws_subnet" "publica" {
  count                   = length(var.zonas)
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.zonas[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefijo}-publica-${var.zonas[count.index]}"
  }
}

resource "aws_subnet" "aplicacion" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-aplicacion-${var.zonas[count.index]}"
  }
}

resource "aws_subnet" "datos" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 21)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-datos-${var.zonas[count.index]}"
  }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = {
    Name = "${local.prefijo}-rt-publica"
  }
}

resource "aws_route_table_association" "publica" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table" "aplicacion" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-rt-aplicacion"
  }
}

resource "aws_route_table_association" "aplicacion" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.aplicacion[count.index].id
  route_table_id = aws_route_table.aplicacion.id
}

resource "aws_route_table" "datos" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-rt-datos"
  }
}

resource "aws_route_table_association" "datos" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.datos[count.index].id
  route_table_id = aws_route_table.datos.id
}

resource "aws_security_group" "endpoints" {
  name        = "${local.prefijo}-sg-endpoints"
  description = "Permite HTTPS desde la VPC hacia los VPC endpoints"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  security_group_id = aws_security_group.endpoints.id
  description       = "HTTPS desde dentro de la VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(["dynamodb", "s3"])

  vpc_id            = aws_vpc.principal.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.aplicacion.id]

  tags = {
    Name = "${local.prefijo}-vpce-${each.key}"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["sns", "secretsmanager"])

  vpc_id              = aws_vpc.principal.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.aplicacion[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.prefijo}-vpce-${each.key}"
  }
}