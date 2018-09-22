
variable num_nodes {
  description = "Number of nodes"
  default = 3
}

variable env {
  description = "Environment prefix"
  default = "dev"
}

#
# Google Cloud provider (GCP)
# https://www.terraform.io/docs/providers/google/index.html
#
# List GCP projects: 
#
#  glcoud projects list
#

provider "google" {
  version        = "1.17.1"
#Step 1.Set crendentials in environment variable GOOGLE_APPLICATION_CREDENTIALS or below
#  credentials = "${file("gcp-account-creds.json")}"
#Step 2.Set Project in environment variable GOOGLE_PROJECT or below
#  project     = "project-id"
#Step 3. Set region
  region      = "us-west1"
}

#
# Step 4. Set GCP availabiltiy zones
#
variable "gcp-azs" {
  description = "Run the GCP Instances in these Availability Zones"
  type = "list"
  default = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

#
# Step 5. Set OS distribution Image to use
# For Step 6. See 'main.tf'
#
# Find latest distro images on GCP:
#
#   gcloud compute images list --filter="centos-"
#
#   gcloud compute images list --filter="ubuntu-"

#
variable "os_image" {
  description = "GCP os distribution image"
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20180912"
  #default = "projects/centos-cloud/global/images/centos-7-v20180911"
}

variable "machine_type" {
  description = "GCP machine type"
  default = "f1-micro" # g1-small, n1-standard-1
}

provider "aws" {
  version        = "v1.36.0"
# Step 1. set AWS keys below or as [default] in your '~/.aws/credentials' file
#  access_key = "<aws access key>"
#  secret_key = "<aws secret key>"
# Step 2. Set region
  region = "us-east-1"
}

#
# Step 3. Set AWS availabiltiy zones
#
variable "aws-azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

#
# Step 4. Set SSH Key pair to use
#
variable "key_name" {
  description = "AWS SSH Key pair"
  default = "dev"
}

#
# Step 5. Set CIDR block to internal subnet where nodes will be provisioned.
# For Step 6. See 'main.tf'
#
variable "internal_cidr_block" {
  description = "AWS internal CIDR block"
  default = "172.31.0.0/16"
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  default = "t2.micro"
}


# 
# Ubuntu 16.04 / xenial
#
data "aws_ami" "ubuntu_xenial" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# 
# Centos 7
#
data "aws_ami" "centos7" {
  most_recent       = true
  owners            = ["679593333241"]

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*"]
  }
}





