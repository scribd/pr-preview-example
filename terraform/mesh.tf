resource "aws_appmesh_mesh" "pr-preview-mesh" {
  name = "pr-preview-mesh"

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}