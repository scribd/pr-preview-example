##
# Security Groups for ECS Cluster
#

resource "aws_security_group" "pr-preview" {
  name        = "asg-pr-preview"
  description = "ASG pr-preview security group"
  vpc_id      = data.aws_vpc.staging.id
}

resource "aws_security_group_rule" "pr-preview" {
  description       = "All outbound"
  security_group_id = aws_security_group.pr-preview.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "pr-preview_incoming_http" {
  description       = "http inbound"
  security_group_id = aws_security_group.pr-preview.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "pr-preview_incoming_https" {
  description       = "https inbound"
  security_group_id = aws_security_group.pr-preview.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "pr-preview_incoming_envoy_admin" {
  description       = "envoy admin inbound"
  security_group_id = aws_security_group.pr-preview.id

  type        = "ingress"
  from_port   = 9901
  to_port     = 9901
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}


##
# Security Groups for Virtual Gateway
# 

resource "aws_security_group" "pr-preview-example-com" {
  name        = "pr-preview-example-com"
  description = "Security group for HTTP service with port 80 open within VPC"
  vpc_id      = "vpc-12345"
}

resource "aws_security_group_rule" "pr-preview-example-com_outbound" {
  description       = "All outbound"
  security_group_id = aws_security_group.pr-preview-example-com.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "pr-preview-example-com_inbound_80" {
  description       = "pr-preview-example-com 80"
  security_group_id = aws_security_group.pr-preview-example-com.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "pr-preview-example-com_inbound_443" {
  description       = "pr-preview-example-com 443"
  security_group_id = aws_security_group.pr-preview-example-com.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "pr-preview-example-com_inbound_9901" {
  description       = "pr-preview-example-com 9901"
  security_group_id = aws_security_group.pr-preview-example-com.id

  type        = "ingress"
  from_port   = 9901
  to_port     = 9901
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}
