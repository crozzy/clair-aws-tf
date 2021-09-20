provider "aws" {
  region = var.region
  profile = var.aws_profile
}

data "aws_availability_zones" "available" {}

locals {
  clair_endpoint = "clair-app-${var.prefix}.${var.openshift_route_suffix}"
}

data "template_file" "clair_template" {
  template = "${file("${path.module}/clair_deployment.yaml.tpl")}"
  vars = {
    namespace = "${var.prefix}-clair"
    clair_image = "${var.clair_image}"
    clair_route_host = "${local.clair_endpoint}"

    clair_db_host = "${aws_db_instance.clair_db.address}"
    clair_db_port = "${aws_db_instance.clair_db.port}"
    clair_db_user = "${aws_db_instance.clair_db.username}"
    clair_db_password = "${var.db_password}"

    clair_auth_psk = base64encode("clairsharedpassword")
    indexer_replicas = 1
    matcher_replicas = 1
    notifier_replicas = 1
  }
}

resource "local_file" "clair_deployment" {
  content = data.template_file.clair_template.rendered
  filename = "${var.prefix}_clair_deployment.yaml"
}
