# terraform-aws-web-stack

Módulos de Terraform para un stack web containerizado de 3 capas sobre AWS.
Es la forma que vengo usando en Socialnet para varios servicios chicos y
medianos en producción (como tech lead de DevOps). Lo saqué acá para que
la próxima cuenta que arranque no empiece desde un `main.tf` en blanco.

## Módulos

| módulo              | para qué sirve                                                     |
|---------------------|---------------------------------------------------------------------|
| `modules/vpc`       | VPC, 3 tiers de subnets (public / private / db-private), NAT (1 o 1 por AZ) |
| `modules/alb`       | ALB + listener HTTPS, validación ACM, alias R53, WAF opcional       |
| `modules/ecs-service`| Task def de Fargate, service, IAM roles, log group, target group, autoscaling |
| `modules/rds`       | Postgres, parameter group, subnet group, KMS, Multi-AZ              |

Cada módulo es chico y componible. `examples/simple` y `examples/production`
muestran cómo encajan.

## Quickstart -- `examples/simple`

```bash
cd examples/simple
cp terraform.tfvars.example terraform.tfvars   # editar para tu cuenta
terraform init
terraform validate       # chequeo de sintaxis, no hace falta AWS
terraform plan           # sí hace falta credenciales AWS
terraform apply
```

El ejemplo `simple` levanta un stack de dev de un solo AZ (~$50/mes a
list price con NAT incluído). Es el mínimo para ver los módulos hablando
entre sí. Para prod usar `examples/production` con NAT per-AZ y RDS Multi-AZ.

## Decisiones de diseño

### 1-NAT vs NAT-per-AZ (`nat_mode`)

El módulo VPC acepta `nat_mode = "single" | "per_az"`. El consejo "un NAT
por AZ para HA" es correcto para prod, pero se copia-pega en VPCs de dev
y staging donde tener que rehacer algo en 20 minutos está bien. Cada NAT
extra son ~$32/mes más tráfico. En la práctica: `per_az` para prod,
`single` para todo lo demás.

### Subnets separadas para RDS

Las `db-private` están separadas de las `private`. El security group de
RDS solo permite entrada desde el SG de ECS, nada más. Esa es la config
que más seguido queda demasiado abierta.

### ECS Fargate, no EC2

Fargate saca del medio la pregunta "quién patchea la AMI". Para la
escala que apunta este módulo (<50 tasks), la prima que cobra Fargate
vale la pena por el ahorro operativo.

### Sin hardcodear cantidad de AZs

El módulo VPC elige las primeras `az_count` AZs desde
`data.aws_availability_zones.available`. No asume us-east-1 con `a/b/c`.
Funciona en `sa-east-1`, `eu-central-1`, etc.

## Scope

Cosas que este repo no incluye, a propósito:

- Código de aplicación -- esto es infra, tu app es tuya.
- Pipeline de CI/CD -- usá GitHub Actions, CodePipeline, Atlantis, lo que entre.
- Observabilidad completa -- CloudWatch queda cableado; Datadog/Grafana es un bolt-on.
- Dashboards de costo -- para eso tengo [`aws-cost-optimizer-cli`](https://github.com/sarteta/aws-cost-optimizer-cli).

## Versionado

SemVer. Breaking changes bump major. Se usan git tags sobre `main`:

```hcl
module "web_stack_vpc" {
  source = "github.com/sarteta/terraform-aws-web-stack//modules/vpc?ref=v0.1.0"
  # ...
}
```

## Licencia

MIT © 2026 Santiago Arteta
