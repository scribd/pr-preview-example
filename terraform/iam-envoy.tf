# ------------------------------------------------ #
# Envoy Role
#   * AWSAppMeshEnvoyAccess
#   * AmazonEC2ContainerRegistryReadOnly
# ------------------------------------------------ #
data "aws_iam_policy_document" "assume_envoy_role" {
  statement {
    sid    = "AssumeRolePolicy"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "eks.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "envoy" {
  name               = "envoy"
  assume_role_policy = data.aws_iam_policy_document.assume_envoy_role.json
}

resource "aws_iam_role_policy_attachment" "AWS_app_mesh_envoy_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
  role       = aws_iam_role.envoy.name
}

resource "aws_iam_role_policy_attachment" "Amazon_EC2_Container_Registry_RO_envoy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.envoy.name
}

resource "aws_iam_instance_profile" "envoy_ec2_profile" {
  name = "envoy-ec2-profile"
  role = aws_iam_role.envoy.name
}
