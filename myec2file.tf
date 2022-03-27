provider "aws" {
    region = "eu-west-2"
    access_key = "AKIAWCVX6L2FUFCFV736"
    secret_key = "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"
}


resource aws_vpc "firstvpc" {

cidr_block = "172.0.0.0/16"
tags = {
Name = "HomeCloud"

}

}

resource aws_subnet "devsubnet"{
vpc_id = aws_vpc.firstvpc.id
cidr_block = "172.0.1.0/24"
tags = {

    Name="Dev Subnet"
}

}


