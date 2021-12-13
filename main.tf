provider "aws" {
 region = "eu-west-1"
 default_tags {
   tags = {
     Environment = "Test"
     Owner       = "TFProviders"
     Project     = "NetSPI_EIP"
   }
 }
}

resource "aws_s3_bucket" "b" {
  bucket = "my-tf-test-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Test"
  }
}

resource "tls_private_key" "my_key" {
algorithm = "RSA"
}

resource "aws_key_pair" "deployer" {
key_name   = "efs-key"
public_key = tls_private_key.my_key.public_key_openssh
}

resource "null_resource" "save_key_pair"  {
provisioner "local-exec" {
command = "echo  ${tls_private_key.my_key.private_key_pem} > mykey.pem"
}
}

resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"

  tags = {
    Name = "MyProduct"
  }
}

resource "aws_efs_mount_target" "mount" {
file_system_id = aws_efs_file_system.foo.id
subnet_id      = aws_instance.foo.subnet_id
security_groups = [aws_security_group.allow_tls.id]
}

resource "null_resource" "configure_nfs" {
depends_on = [aws_efs_mount_target.mount]
connection {
type     = "ssh"
user     = "ec2-user"
private_key = tls_private_key.my_key.private_key_pem
host     = aws_instance.web.public_ip
 }

provisioner "remote-exec" {
inline = [
"sudo yum install httpd php git -y -q ",
"sudo systemctl start httpd",
"sudo systemctl enable httpd",
"sudo yum install nfs-utils -y -q ",

"sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.efs.dns_name}:/  /data/test",

"echo ${aws_efs_file_system.efs.dns_name}:/ /data/test nfs4 defaults,_netdev 0 0  | sudo cat >> /etc/fstab " ,
"sudo chmod go+rw /data/test",

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "tf_test_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.default.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.default.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.default.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "foo" {
  # us-west-2
  ami           = "ami-5189a661"
  instance_type = "t2.micro"

  private_ip = "10.0.0.12"
  subnet_id  = aws_subnet.tf_test_subnet.id
}

resource "aws_eip" "bar" {
  vpc = true 
  instance                  = aws_instance.foo.id
  associate_with_private_ip = "10.0.0.12"
  depends_on                = [aws_internet_gateway.gw]
}