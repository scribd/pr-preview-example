# The IAM profile that ECS EC2 instances will assume.
resource "aws_iam_instance_profile" "pr-preview-instance" {
  name = "pr-preview-ecsInstanceRole"
  path = "/"
  role = aws_iam_role.pr-preview-instance.name
}

##
# The IAM role for the ECS cluster instances
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
#
resource "aws_iam_role" "pr-preview-instance" {
  name = "pr-preview-ecsInstanceRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Let ECS do ECS things on EC2
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerServiceforEC2Role
resource "aws_iam_role_policy_attachment" "pr-preview-instance-attach-ecs" {
  role       = aws_iam_role.pr-preview-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Pull AppMesh configuration data
resource "aws_iam_role_policy_attachment" "pr-preview-instance-attach-appmesh" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
  role       = aws_iam_role.pr-preview-instance.name
}

# Pull containers
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "pr-preview-instance-attach-ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.pr-preview-instance.name
}


resource "aws_iam_policy" "pull-envoy" {
  name        = "pull-envoy"
  path        = "/"
  description = "Enable pulling Amazon managed aws-appmesh-envoy container"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ],
    "Resource": "arn:aws:ecr:us-east-1:840364872350:repository/aws-appmesh-envoy",
    "Effect": "Allow"
    },
    {
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pr-preview-instance-attach-pull-envoy" {
  role       = aws_iam_role.pr-preview-instance.name
  policy_arn = aws_iam_policy.pull-envoy.arn
}

##
# The Service IAM Role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_IAM_role.html
#
resource "aws_iam_role" "pr-preview-service" {
  name = "ecsServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecsServiceRole-attach" {
  role       = aws_iam_role.pr-preview-service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
