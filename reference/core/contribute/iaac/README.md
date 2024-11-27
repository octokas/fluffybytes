# FluffyBytes Infrastructure as Code: Complete Setup Guide

## Phase 0: Repository and Local Environment

### Initial Setup

```bash
# Clone and initialize repository
git clone git@github.com:your-org/fluffy-bytes.git
cd fluffy-bytes

# Initialize terraform directories
mkdir -p terraform/{bootstrap,github,organization,modules,environments}
```

### Bootstrap Terraform (terraform/bootstrap/main.tf)
```hcl
# bootstrap/main.tf
# Sets up initial S3 bucket and DynamoDB for Terraform state
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "awestomates-terraform-state"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## Phase 1: GitHub Repository Setup

GitHub Configuration (terraform/github)
```hcl
# github/main.tf
provider "github" {
  token = var.github_token
}

resource "github_repository" "fluffy_bytes" {
  name        = "fluffy-bytes"
  description = "Enterprise cloud storage with infrastructure control"

  visibility = "private"
  has_issues = true
  has_wiki   = true

  template {
    owner      = "awestomates"
    repository = "terraform-template"
  }
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.fluffy_bytes.node_id
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = ["ci/terraform-plan"]
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
  }
}
```

Phase 2: AWS Organization Setup
Root Organization (terraform/organization)

```hcl
# organization/main.tf
provider "aws" {
  region = "eu-central-1"
}

resource "aws_organizations_organization" "awestomates" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "cloudwatch.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com"
  ]
}

resource "aws_organizations_organizational_unit" "fluffy_bytes" {
  name      = "FluffyBytes"
  parent_id = aws_organizations_organization.awestomates.roots[0].id
}
```

Phase 3: Core Infrastructure Modules
Storage Module (terraform/modules/storage)

```hcl
# modules/storage/main.tf
resource "aws_ebs_volume" "storage_pool" {
  count             = var.volume_count
  availability_zone = var.availability_zone
  size              = 30
  type              = "gp3"

  tags = {
    Name = "fluffy-bytes-storage-${count.index}"
  }
}

resource "aws_eks_cluster" "storage_cluster" {
  name     = "fluffy-bytes-${var.client_name}"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}
```


Event Processing Module (terraform/modules/events)
```hcl
# modules/events/main.tf
resource "aws_cloudwatch_event_bus" "client" {
  name = "fluffy-bytes-${var.client_name}"
}

resource "aws_lambda_function" "event_processor" {
  filename         = "lambda/event_processor.zip"
  function_name    = "fluffy-bytes-event-processor-${var.client_name}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  runtime          = "provided.al2"
}
```

Phase 4: Client Account Setup
Client Template (terraform/modules/client-account)

```hcl
# modules/client-account/main.tf
module "storage" {
  source = "../storage"
  client_name = var.name
}

module "events" {
  source = "../events"
  client_name = var.name
}

module "monitoring" {
  source = "../monitoring"
  client_name = var.name
}
```

Deployment Steps

1. Bootstrap Terraform:
```bash
cd terraform/bootstrap
terraform init
terraform apply
```

2. Configure GitHub Repository:
```bash
cd ../github
terraform init
terraform apply
```

3. Setup AWS Organization:
```bash
cd ../organization
terraform init
terraform apply
```

4. Deploy Client Infrastructure:
```bash
cd ../environments/prod
terraform init
terraform apply -var="client_name=example"
```

## Monitoring and Maintenance

### Adding New Clients
```bash
# Create new client workspace
terraform workspace new client-name
terraform apply -var="client_name=client-name"
```

### Updating Infrastructure
```bash
## Basic
### Plan changes
terraform plan
### Apply updates
terraform apply
```

```bash
#### Advanced: With Variables
cd terraform/environments/prod
terraform plan -var="client_name=client-name"
terraform apply -var="client_name=client-name"
```

Monitoring
```bash
### View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace "FluffyBytes" \
  --metric-name "StorageUsage" \
  --dimensions Name=ClientId,Value=client-name \
  --start-time "2024-11-27T00:00:00" \
  --end-time "2024-11-27T23:59:59" \
  --period 3600 \
  --statistics Average
```
