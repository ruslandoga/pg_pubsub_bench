resource "aws_service_discovery_private_dns_namespace" "pg_pubsub_bench" {
  name = "svc.pg_pubsub_bench.cluster"
  vpc  = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "pg_pubsub_bench" {
  name = "pg_pubsub_bench"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.pg_pubsub_bench.id

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }
}
