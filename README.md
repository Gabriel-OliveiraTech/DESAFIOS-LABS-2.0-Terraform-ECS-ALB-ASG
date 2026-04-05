# BIA AWS Lab Environment

> Infraestrutura AWS para a aplicação BIA 2026 — gerenciador de tarefas containerizado, provisionado com Terraform.

![Demo da aplicação](docs/images/demo.gif)

## Visão Geral

O **BIA 2026** é um gerenciador de tarefas com frontend web e backend containerizado. Toda a infraestrutura é provisionada na AWS via Terraform, utilizando ECS (EC2 launch type) para rodar os containers, RDS PostgreSQL como banco de dados, ALB para distribuição de carga entre duas zonas de disponibilidade e Secrets Manager para gerenciamento seguro de credenciais.

## Diagrama de Arquitetura

```mermaid
graph TD
    Internet -->|HTTP:80| ALB["ALB - bia-alb
    Internet-facing"]
    ALB -->|Forward| TG["Target Group
    bia-tg - HTTP"]
    TG --> ECS1["ECS Task 1
    bia-container:8080
    us-east-1a"]
    TG --> ECS2["ECS Task 2
    bia-container:8080
    us-east-1b"]
    ECS1 & ECS2 --> RDS[("RDS PostgreSQL
    bia-db-tf
    Multi-AZ")]
    ECS1 & ECS2 --> SM["Secrets Manager
    DB Credentials"]
    ECS1 & ECS2 --> CW["CloudWatch Logs
    /aws/ecs/bia"]
    EC2["EC2 Dev
    BIA-Dev-terraform
    t3a.micro"] --> RDS
    ASG["Auto Scaling Group
    bia-asg - 2x t3.micro"] -->|Hosts| ECS1 & ECS2
    ECR["ECR
    bia-ecr-repo"] -->|Image pull| ECS1 & ECS2

    subgraph VPC["VPC - 172.50.16.0/27"]
        subgraph AZ_A["us-east-1a — subnet-1"]
            ECS1
            EC2
        end
        subgraph AZ_B["us-east-1b — subnet-2"]
            ECS2
        end
        ALB
        RDS
    end
```

## Pré-requisitos

- Terraform >= 1.x
- AWS CLI configurado com profile
- Permissões de administrador na conta AWS

## Como Usar

```bash
# 1. Provisionar o backend S3 (apenas na primeira vez)
cd Comece-aqui
terraform init && terraform apply

# 2. Provisionar a infraestrutura principal
cd ..
terraform init
terraform plan
terraform apply
```

![Terraform Plan — 36 recursos](docs/images/terraform-plan-36-resources.png)

![Terraform Apply no VS Code](docs/images/terraform-apply-vscode.png)

---

## Componentes

### Rede (VPC)

- VPC `BIA-Dev-VPC` com CIDR `172.50.16.0/27`
- 2 subnets públicas: `subnet-1` (us-east-1a) e `subnet-2` (us-east-1b)
- Internet Gateway + Route Table com rota `0.0.0.0/0`
- Security Groups: `bia-alb`, `bia-ec2`, `bia-dev`, `bia-web`, `bia-db`

---

### EC2 — Máquina de Desenvolvimento

- Instância `BIA-Dev-terraform` — `t3a.micro`, Amazon Linux 2023, volume gp3 20GB
- Usada para desenvolvimento, testes e acesso direto ao banco via SSM
- IAM Instance Profile com permissões de ECS agent, SSM e ECR

![EC2 Instances Running](docs/images/ec2-instances-running.png)

---

### ECS — Elastic Container Service

- Cluster `bia-ecs-cluster` com capacity provider EC2 (Auto Scaling)
- Serviço `bia-service`: 2 tasks desejadas, distribuídas por AZ (spread strategy)
- Task definition `bia-task-family`:
  - Container `bia-container` na porta 8080 (host port dinâmico)
  - 1024 CPU units, 400MB memória reservada
  - Imagem provinda do ECR (`bia-ecr-repo:latest`)
  - Variáveis de ambiente: `DB_HOST`, `DB_PORT`, `DB_SECRET_NAME`, `DB_REGION`
  - Logs enviados ao CloudWatch via `awslogs` driver

![ECS Cluster Overview](docs/images/ecs-cluster-overview.png)

![ECS Service 2/2 Tasks Running](docs/images/ecs-service-running.png)

![ECS Cluster Infrastructure — Capacity Provider](docs/images/ecs-cluster-infrastructure.png)

![ECS Service Tasks — Estado Final](docs/images/ecs-service-tasks-final.png)

---

### Auto Scaling Group

- ASG `bia-asg`: min 2, max 2 instâncias `t3.micro`
- Launch template com AMI ECS-optimized obtida via SSM Parameter Store
- Capacity provider com managed scaling habilitado (target 100%)
- Instâncias registradas automaticamente no cluster ECS

![ASG Capacity Overview](docs/images/asg-capacity.png)

---

### Application Load Balancer (ALB)

- ALB `bia-alb`: internet-facing, HTTP:80, 2 Availability Zones
- Target group com health check em `GET /api/versao` (HTTP 200)
- 2 targets healthy — um container por instância EC2 do ASG

![ALB Resource Map](docs/images/alb-resource-map.png)

![ALB Resource Map — Estado Final](docs/images/alb-resource-map-final.png)

---

### RDS — Banco de Dados

- PostgreSQL 17.4, instância `db.m5.large`, Multi-AZ habilitado
- Banco `bia_db`, usuário `postgres`, 10GB alocado
- Credenciais gerenciadas automaticamente pelo Secrets Manager (`manage_master_user_password = true`)
- Subnet group abrangendo as 2 AZs

![RDS sendo criado](docs/images/rds-creating.png)

---

### ECR — Container Registry

- Repositório `bia-ecr-repo` para armazenar a imagem Docker da aplicação
- Tags mutáveis, `force_delete = true` para facilitar o teardown do lab

---

### Secrets Manager

- Secret criado automaticamente pelo RDS com as credenciais do banco
- ECS tasks acessam as credenciais via AWS SDK em runtime (sem expor senha em variáveis de ambiente)
- IAM policy `get-secret-value-policy` concede acesso apenas ao secret do RDS

![Logs do container buscando credenciais no Secrets Manager](docs/images/secrets-manager-logs.png)

![Variáveis de ambiente do container ECS](docs/images/container-env-vars.png)

---

### CloudWatch Logs

- Log group `/aws/ecs/bia` com retenção de 7 dias
- Todos os containers do serviço `bia-service` enviam logs automaticamente

---

### IAM

- **`bia-dev-role`** (EC2): `AmazonEC2ContainerServiceforEC2Role` + `AmazonSSMManagedInstanceCore` + `AmazonEC2ContainerRegistryPowerUser`
- **`bia-ecs-task-execution-role`** (ECS Tasks): `AmazonECSTaskExecutionRolePolicy` + policy customizada para `secretsmanager:GetSecretValue`

---

## Aplicação em Funcionamento

Evolução do deploy — da EC2 direta até o ALB com ECS:

| Etapa | Screenshot |
|---|---|
| App rodando direto na EC2 (sem ALB) | ![](docs/images/app-sem-alb-ec2.png) |
| App na EC2 porta 3001 com Secrets integrado | ![](docs/images/app-ec2-porta-3001.png) |
| App via DNS do ALB (estado final) | ![](docs/images/app-com-alb.png) |

---

## Outputs

| Output | Descrição |
|---|---|
| `alb_dns_name` | DNS público do ALB |
| `ec2_instance_id` | ID da instância EC2 de desenvolvimento |
| `ec2_instance_public_ip` | IP público da EC2 |
| `db_endpoint` | Endpoint do RDS |
| `ecr_repository_url` | URL do repositório ECR |
| `db_credentials_secret_name` | Nome do secret no Secrets Manager |

---

## Tags Padrão

Todos os recursos são tagueados com:

```hcl
Environment = "dev"
ManagedBy   = "terraform"
Owner       = "gabriel_oliveira"
```
