##
# Webapp Application
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
#
resource "aws_iam_role" "webapp-execution" {
  name = "webapp-execution"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
        "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "webapp-execution-attach-task-execution-role" {
  role       = aws_iam_role.webapp-execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "get-secrets" {
  name        = "get-secrets"
  path        = "/"
  description = "Enable resolving secrets"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
      "secretsmanager:GetSecretValue"
    ],
    "Resource": [
      "arn:aws:secretsmanager:us-east-1:1234567890:secret:my-app/mysql"
    ],
    "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "webapp-execution-attach-get-secrets" {
  role       = aws_iam_role.webapp-execution.name
  policy_arn = aws_iam_policy.get-secrets.arn
}


# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html


resource "aws_iam_role" "webapp-task" {
  name = "webapp-task"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
        "ecs-tasks.amazonaws.com"
        ]
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "webapp-task-attach-appmesh" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
  role       = aws_iam_role.webapp-task.name
}

resource "aws_iam_policy" "webapp-policy-staging" {
  name        = "webapp-policy-staging"
  path        = "/"
  description = "The webapp policy for staging"

  policy = "{}" // Whatever the webapp needs to access in AWS.
}

resource "aws_iam_role_policy_attachment" "webapp-policy-staging" {
  role       = aws_iam_role.webapp-task.name
  policy_arn = aws_iam_policy.webapp-policy-staging.arn
}