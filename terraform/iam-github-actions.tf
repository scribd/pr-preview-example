#--------------------------------------------------------------------
# IAM User `github-actions-user` to allow access from github actions
#           but in a modestly restricted way.
#--------------------------------------------------------------------
resource "aws_iam_user" "ci_cd_github_actions" {
  name = "github-actions-user"
}

#--------------------------------------------------------------------
# IAM policy to grant ECR read/write
#--------------------------------------------------------------------
resource "aws_iam_user_policy_attachment" "ci_cd_github_actions_ecr_read_write_role_policy" {
  user       = aws_iam_user.ci_cd_github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

#--------------------------------------------------------------------
# IAM policy to allow for deployment to ECS
#--------------------------------------------------------------------
data "aws_iam_policy_document" "ci_cd_github_actions_ecs_deploy_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:CreateService",
      "ecs:DescribeServices",
      "ecs:DeleteService"
    ]
    resources = [
      "arn:aws:ecs:us-east-1:1234567890:service/pr-preview/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:ListServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "servicediscovery:GetService",
      "servicediscovery:ListServices",
      "servicediscovery:CreateService",
      "servicediscovery:DeleteService",
      "servicediscovery:TagResource",
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "appmesh:CreateGatewayRoute",
      "appmesh:CreateVirtualNode",
      "appmesh:CreateVirtualService",
      "appmesh:CreateVirtualRouter",
      "appmesh:CreateRoute",
      "appmesh:DeleteGatewayRoute",
      "appmesh:DeleteRoute",
      "appmesh:DeleteVirtualNode",
      "appmesh:DeleteVirtualService",
      "appmesh:DeleteVirtualRouter",
      "appmesh:DescribeGatewayRoute",
      "appmesh:DescribeRoute",
      "appmesh:DescribeVirtualNode",
      "appmesh:DescribeVirtualService",
      "appmesh:DescribeVirtualRouter"
    ]
    resources = [
      "arn:aws:appmesh:us-east-1:1234567890:mesh/pr-preview-mesh/**/*"
    ]
  }
}

resource "aws_iam_policy" "ci_cd_github_actions_ecs_deploy_policy" {
  name        = "ci-cd-github_actions-ecs-deploy-policy"
  path        = "/"
  description = "Deployment policy for updating ECS services to trigger deployments."

  policy = data.aws_iam_policy_document.ci_cd_github_actions_ecs_deploy_policy.json
}

resource "aws_iam_user_policy_attachment" "ci_cd_github_actions_ecs_deploy_policy" {
  user       = aws_iam_user.ci_cd_github_actions.name
  policy_arn = aws_iam_policy.ci_cd_github_actions_ecs_deploy_policy.arn
}

