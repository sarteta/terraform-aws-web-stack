# Changelog

All notable changes to this module set.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).
This project uses [semver](https://semver.org/) — breaking changes bump major.

## [Unreleased]

## [0.1.0] — 2026-04-20

First tagged version. Contents are what I've been running at Socialnet, lifted
out of the internal repo and cleaned up so the next account can bootstrap
without copy-pasting from a live TF state.

### Modules

- `modules/vpc` — VPC with 3 subnet tiers (public / private / db-private),
  NAT gateway in `single` or `per_az` mode.
- `modules/alb` — ALB + HTTPS listener, ACM-validated cert, Route53 alias,
  optional WAF association.
- `modules/ecs-service` — Fargate task definition, service, IAM roles, log
  group, target group, autoscaling policy.
- `modules/rds` — Postgres instance, parameter group, subnet group,
  KMS-encrypted, Multi-AZ toggle.

### Examples

- `examples/simple` — single-AZ NAT, single RDS. Dev/staging shape.
- `examples/production` — Multi-AZ NAT per AZ, Multi-AZ RDS.

### Known gaps

- No KMS key rotation check in CI yet (on the list).
- `modules/alb` WAF support is an `enable` flag only; no managed rule set
  wiring. Will add when I need it in prod.
