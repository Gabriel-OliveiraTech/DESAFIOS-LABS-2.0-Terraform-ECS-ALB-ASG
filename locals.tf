locals {
  vpc_bia = aws_vpc.bia_dev_vpc.id
}


locals {
  sub_net-1 = aws_subnet.sub_1.id
  sub_net-2 = aws_subnet.sub_2.id
}
