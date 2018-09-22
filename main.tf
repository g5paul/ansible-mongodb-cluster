
#
# GCP GCE instances
#

#
# GCP GCE Instance provisioning
#
#  terraform plan --target=google_compute_instance.gce-mongo-1
#  terraform apply --target=google_compute_instance.gce-mongo-1
#  terraform destroy --target=google_compute_instance.gce-mongo-1
#  terraform destroy --target=google_compute_disk.disk-sdb-mongo-1
#  
resource "google_compute_disk" "disk-sdb-mongo-1" {
  count = "${var.num_nodes}"
  name  = "data-disk-sdb-mongo-${var.env}-priv-${element(var.gcp-azs, count.index)}-${count.index}"
  type  = "pd-standard"
  zone = "${element(var.gcp-azs, count.index)}"
  size  = "10"
  labels {
    app = "mongodb"
    role = "db"
    cluster = "mongo-${var.env}-1"
    environ = "${var.env}"
  }
}

resource "google_compute_instance" "gce-mongo-1" {
  # Required
  count = "${var.num_nodes}"
  name         = "gce-mongo-${var.env}-priv-${element(var.gcp-azs, count.index)}-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${element(var.gcp-azs, count.index)}"

  boot_disk {
    initialize_params {
      # OS distribution Image to use
      image = "${var.os_image}"
      size = "10"
      type = "pd-standard"
    }
  }
  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  # Optional

  // Local SSD disk
  #scratch_disk {
  #}
  depends_on = ["google_compute_disk.disk-sdb-mongo-1"]
  attached_disk {
     source = "data-disk-sdb-mongo-${var.env}-priv-${element(var.gcp-azs, count.index)}-${count.index}"
  }

  # Step 6 (Optional). Set tag to corresponding network tag to allow external access if needed
  tags = ["allow-external-mongos"]

  metadata {
    Name = "gce-mongo-${var.env}-priv-${element(var.gcp-azs, count.index)}-${count.index}"
    App = "mongodb"
    Role = "db"
    Cluster = "mongo-${var.env}-1"
    Environ = "${var.env}"
    startup-script = "${file("${path.module}/startup-script.sh")}"
  }

  #metadata_startup_script = "echo hi > /test.txt"

  #service_account {
  #  scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  #}
}

#
# AWS EC2 Instances
#

resource "aws_security_group" "ssh" {
  name        = "${var.env}_ssh_sg"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name        = "${var.env}_mongo_db_sg"
  description = "Allow MongoDB access"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# allow all internal subnet access where nodes will be provisioned.
resource "aws_security_group" "internal_all" {
  name        = "${var.env}_internal_all_sg"
  description = "Allow internal all access"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.internal_cidr_block}"]
  }
}

# AWS EC2 Instance provisioning
#
#  terraform plan --target=aws_instance.ec2-mongo-1
#  terraform apply --target=aws_instance.ec2-mongo-1
#  terraform destroy --target=aws_instance.ec2-mongo-1
#  
resource "aws_instance" "ec2-mongo-1" {
  count = "${var.num_nodes}"
  # Step 6. Set OS distribution AMI
  ami = "${data.aws_ami.ubuntu_xenial.id}"
  #ami = "${data.aws_ami.centos7.id}"
  availability_zone = "${element(var.aws-azs, count.index)}"
  instance_type = "${var.instance_type}"

  depends_on = ["aws_security_group.db","aws_security_group.ssh",  "aws_security_group.internal_all"]

  # SSH Key pair to use
  key_name = "${var.key_name}"

  # Security group to allow external ssh, mongos and internal all
  vpc_security_group_ids = [
    "${aws_security_group.internal_all.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.db.id}"
   ]

  # public IP
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 10
    volume_type = "gp2"
    delete_on_termination = true
  }

  user_data = "${file("${path.module}/startup-script.sh")}"

  tags {
    Name = "ec2-mongo-${var.env}-priv-${element(var.aws-azs, count.index)}-${count.index}"
    App = "mongodb"
    Role = "db"
    Cluster = "mongo-${var.env}-1"
    Environ = "${var.env}"
  }
}
