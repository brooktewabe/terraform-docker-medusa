resource "aws_elasticache_subnet_group" "medusa_redis_subnet_group" {
  name       = "medusa-redis-subnet-group"
  subnet_ids = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id]
}

resource "aws_security_group" "medusa_redis_sg" {
  name        = "medusa-redis-sg"
  description = "Security group for Medusa Redis"
  vpc_id      = aws_vpc.medusa_vpc.id
 depends_on = [aws_security_group.medusa_sg]
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.medusa_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medusa-redis-sg"
  }
}

resource "aws_elasticache_cluster" "medusa_redis" {
  cluster_id           = "medusa-redis"
  engine               = "redis"
  engine_version       = 6.2
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.medusa_redis_subnet_group.name
  security_group_ids   = [aws_security_group.medusa_redis_sg.id]
  snapshot_retention_limit = 7
  apply_immediately        = true
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [engine_version]
  }
}
# # Store Redis URL in SSM Parameter Store
# resource "aws_ssm_parameter" "redis_url" {
#   name  = "/medusa/REDIS_URL"
#   type  = "SecureString"
#   value = "redis://${aws_elasticache_cluster.medusa_redis.cache_nodes[0].address}:${aws_elasticache_cluster.medusa_redis.port}"
# }