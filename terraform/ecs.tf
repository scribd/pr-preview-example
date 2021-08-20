resource "aws_ecs_cluster" "pr-preview" {
  name = "pr-preview"
}


##
# ASG
# Clearly, Fargate is just as valid, and may even be preferred for your implementation.
# In our case, we use EC2 since we can better control for cache.
#

resource "aws_launch_configuration" "pr-preview" {
  name_prefix = "pr-preview-"

  iam_instance_profile = aws_iam_instance_profile.pr-preview-instance.name

  instance_type               = "c5.2xlarge" # 8GB RAM
  image_id                    = "ami-07fde2ae86109a2af"
  associate_public_ip_address = false
  security_groups             = [aws_security_group.pr-preview.id]

  root_block_device {
    volume_type = "standard"
    volume_size = 1024
  }


  user_data = <<EOF
#!/bin/bash
# The cluster this agent should check into.
echo 'ECS_CLUSTER=${aws_ecs_cluster.pr-preview.name}' >> /etc/ecs/ecs.config
# Disable privileged containers.
echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "pr-preview" {
  name = "pr-preview"

  launch_configuration = aws_launch_configuration.pr-preview.id
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier  = data.aws_subnet_ids.staging_private_subnets.ids

  desired_capacity = null
  max_size         = 18
  min_size         = 6

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}