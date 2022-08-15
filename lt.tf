resource "aws_launch_template" "this" {
  name                                  = "lt-${lower(var.aws_region_code)}-${lower(var.tag_env)}-tableau-linux"
  description                           = "Launch Template for a RHEL Tableau Server"
  update_default_version                = true
  block_device_mappings {
    device_name                         = "/dev/sda1"
    ebs {
      volume_size                       = 64
      delete_on_termination             = true
      encrypted                         = true
      volume_type                       = "gp3"
      throughput                        = 150
      iops                              = 3000
    }
  }
  disable_api_termination               = false
  ebs_optimized                         = true
  image_id                              = data.aws_ami.redhat.image_id
  instance_initiated_shutdown_behavior  = "terminate"
  instance_type                         = "r6id.2xlarge"
  key_name                              = "KP-${upper(local.account_data.tag_env)}"
  metadata_options {
    http_endpoint                       = "enabled"
    http_tokens                         = "optional"
    instance_metadata_tags              = "enabled"
  }
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    name = "rt-ec2-tableau"
  }
  network_interfaces {
    delete_on_termination               = true
    security_groups                     = [ data.aws_security_group.inbound-linux-devops.id, data.aws_security_group.inbound-linux-app-management.id, data.aws_security_group.inbound-web-public.id, data.aws_security_group.outbound-linux-app.id ]
    associate_public_ip_address         = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      ServerType = "git"
      OS = "Linux"
    }
  }
  user_data = filebase64("${path.module}/userdata.sh")
}