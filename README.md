# Infrastructure scripts for setting up Clair environments

These scripts create a working Clair v4 distributed infrastructre on AWS for development.

## Prerequisites

1. AWS Account
1. OSD or a ROSA cluster
1. Terraform


## Setup

Before running the infra scripts, you need to:

* Install the Openshift CLI
* Make sure you have access to an OSD or a ROSA cluster and are logged in as `Cluster Admin` (you can do this via the `oc login` command)
* Install the AWS CLI
* Login to the AWS account from the CLI

## Installation

1. (Optional) Create a terraform workspace that you will be working on. This is useful if you are creating multiple environments.

```
$ terraform workspace create clair-dev
```

2. You need to set the following **REQUIRED** variables (as environment variables prefixing with `TF_VAR_` or variables in `terraform.tfvars`)
    * `prefix` : Make sure it's unique else, it will clash with other envs
    * `rds_vpc_cidr` : Pick an unused CIDR (defaults to `172.33.0.0/16`)
    * `db_password` : The password that will be set on the quay and clair RDS DBs
    
3. You could optionally set the following variables if required
    * `aws_profile`: Set this if you are not using the default account set with AWS CLI
    * `clair_image`: Overrides the image that being used


## Running

The following gives an example of creating a new environment from scratch

```bash
$ terraform init 
$ terraform workspace new crozzy-test
$ export TF_VAR_prefix="crozzy-test"
$ export TF_VAR_rds_vpc_cidr="172.38.0.0/16"
$ export TF_VAR_db_password="mydbpassword"
$ export TF_VAR_openshift_vpc_id="vpc-xxxxxxxxxxx"
$ export TF_VAR_openshift_route_suffix="apps.xxxx-xx-1.xxxx.xx.openshiftapps.com"
$ terraform apply
```

This command generates a `<prefix>-clair-deployment.yaml` file which you can deploy to openshift

```
kubectl apply -f <prefix>-clair-deployment.yaml
```

This should generate all the deployments for clair.

**NOTE** Terraform also generates a statefile `terraform.tfstate`. DO NOT DELETE this file or commit it. This file keeps track of all the resources on AWS assosiated with your workspace.

## Cleaning up

You need to cleanup both openshift and terraform. 

```
$ kubectl delete namespace <prefix>-quay
$ terraform destroy
```

