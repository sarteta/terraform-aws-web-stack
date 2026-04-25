# Architecture notes

## Module boundaries

Each module owns exactly one AWS concern:

- `vpc` owns subnets, routing, NAT. Outputs: IDs only.
- `alb` owns the load balancer + cert. Outputs: listener ARN + ALB SG ID.
- `ecs-service` owns the task def, service, SG, autoscaling, target group,
  listener-rule. Knows nothing about VPC structure beyond "give me a VPC
  ID and some private subnet IDs."
- `rds` owns the DB + its own SG. Trusts caller to pass the SG ID of
  whoever's allowed to connect.

This separation comes from running several accounts where I found myself
wanting to re-use the ALB for two unrelated services, or swap Fargate for
EC2 under the same ALB, etc. Modules that own too much infra make those
swaps painful.

## Why `nat_mode` is a knob, not a decision

Many Terraform modules hardcode `one NAT per AZ`. That's correct for
prod -- a NAT AZ outage takes down the apps in that AZ. But for dev
and staging, paying ~$100/mo for 3 NATs to protect a workload that
doesn't even have an SLA is waste. The module exposes this as a knob
so you can have:

```hcl
module "prod_vpc" { source = "..."  nat_mode = "per_az" }
module "dev_vpc"  { source = "..."  nat_mode = "single" }
```

Same code path, different cost profile.

## Why DB and app subnets are separate

An app subnet has a default route to NAT. A DB subnet has NO default
route -- RDS never needs to reach the internet during runtime. Separating
them means a misconfigured RT or SG can't accidentally expose the DB.

## ECS service ignores `desired_count`

```hcl
lifecycle {
  ignore_changes = [desired_count]
}
```

This is critical. Without it, every `terraform apply` will reset the
service to `desired_count=2` or whatever's in variables, fighting the
autoscaler during a traffic spike. With this, the autoscaler owns
runtime sizing; Terraform owns the shape.

## Why the ALB listener rule is in `ecs-service`, not `alb`

In a multi-service setup the same ALB hosts N services, each with its
own host-header or path rule. Putting the rule inside each service
module means:

- Each service PR is self-contained -- VPC + ALB are unchanged
- Deleting a service cleanly removes its rule
- You can't accidentally leave an orphan rule pointing at a deleted TG

## Production tips

See `examples/production/main.tf` for the shape we deploy:

1. Remote state in S3 + DynamoDB lock
2. `nat_mode = per_az` + Multi-AZ RDS
3. `deletion_protection = true` on RDS
4. Secrets via Secrets Manager, not plain-text env
5. Performance Insights + enhanced monitoring on RDS
6. Container Insights on ECS
7. Flow logs enabled (filtered to REJECTs to save cost)

## Known limitations

- No WAF module yet (on roadmap)
- No Aurora module -- we use plain Postgres RDS
- No EventBridge / SQS / SNS modules -- integration infra is per-product
- No CI/CD: use GitHub Actions, CodePipeline, or Atlantis
- Fargate only; no EC2 launch type
