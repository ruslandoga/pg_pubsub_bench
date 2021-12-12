module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "pg_pubsub_bench"
  cidr = "10.0.0.0/16"

  azs            = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway = false
  single_nat_gateway = false
}
