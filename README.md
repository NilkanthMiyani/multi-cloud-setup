# Multi-Cloud Kubernetes with Terraform

A managed Kubernetes cluster on **AWS (EKS)**, **Azure (AKS)**, or **GCP (GKE)**.
Each cloud is a **self-contained Terraform root module in its own directory**,
so a run only ever loads that cloud's provider — deploying AWS never touches
Azure or GCP credentials.

## How it works

- One directory per cloud: [aws/](aws/), [az/](az/), [gcp/](gcp/). Each holds
  its own `providers.tf` (a single provider), variables, resources, outputs,
  and an auto-loaded `terraform.tfvars`.
- Because the directories are independent, each has **its own state file** and
  its own `.terraform/` — no workspaces, no `-state` flag, no `count` gating.
- The [Makefile](Makefile) runs `terraform -chdir=<cloud> …` so you never have
  to `cd`. There is **no remote backend** — state is local to each directory.

## Layout

```
.
├── aws/                  # EKS: provider, VPC/subnets/NAT, cluster, node group, IAM
│   ├── providers.tf
│   ├── variables.tf
│   ├── networking.tf
│   ├── eks-cluster.tf
│   ├── outputs.tf
│   └── terraform.tfvars  # auto-loaded inputs for AWS
├── az/                   # AKS: provider, resource group, cluster
│   ├── providers.tf
│   ├── variables.tf
│   ├── aks-cluster.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── gcp/                  # GKE: provider, cluster, node pool
│   ├── providers.tf
│   ├── variables.tf
│   ├── locals.tf         # lowercase label normalization
│   ├── gke-cluster.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── Makefile              # make <verb> <cloud>, e.g. make apply aws
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) **>= 1.5**
- The CLI + credentials for whichever cloud(s) you target (see below). You only
  need creds for the cloud you're actually deploying.

## Authentication setup

### AWS

```bash
aws configure          # or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
aws sts get-caller-identity   # verify
```

The region comes from `aws/terraform.tfvars` (`region`). Alternatively set
`aws_access_key` / `aws_secret_key` there; leave them blank (the default) to use
the standard AWS credential chain shown above.

### Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"   # required by the azurerm provider
```

Alternatively set `azure_subscription_id` in `az/terraform.tfvars`.

### GCP

```bash
gcloud auth application-default login
gcloud config set project "<PROJECT_ID>"
```

Set `gcp_project` in `gcp/terraform.tfvars` to the same project id.

## Usage

### With the Makefile (recommended)

Give the verb, then the cloud as a plain word:

```bash
make init aws             # first time in a cloud dir (also auto-runs on first plan)

make plan aws             # terraform -chdir=aws plan
make apply aws            # apply (prompts for confirmation)
make apply aws AUTO=1     # apply with -auto-approve
make output aws
make destroy aws

# swap the cloud for az / gcp: make plan az, make apply gcp, ...
```

The pattern is always `make <verb> <cloud>` (cloud = `aws` | `az` | `gcp`):

| Command | What it does |
|---------|--------------|
| `make init <cloud>` | Initialize that cloud's dir — run once (also auto-runs on first use). |
| `make upgrade <cloud>` | Re-init with `-upgrade` to pull provider/version changes. |
| `make plan <cloud>` | Show the plan for that cloud. |
| `make apply <cloud>` | Apply (asks for confirmation). Add `AUTO=1` to skip the prompt. |
| `make destroy <cloud>` | Tear the cloud's cluster down. Add `AUTO=1` to skip the prompt. |
| `make output <cloud>` | Print the cloud's outputs. |
| `make show <cloud>` | Show the cloud's current state. |
| `make fmt` | `terraform fmt` across all directories. |
| `make validate <cloud>` | Validate that cloud's configuration. |
| `make help` | List everything above. |

Under the hood these just run the raw commands below — nothing is hidden.

### Raw Terraform

Run Terraform against a cloud's directory with `-chdir` (inputs auto-load from
that dir's `terraform.tfvars`):

```bash
terraform -chdir=aws init
terraform -chdir=aws plan
terraform -chdir=aws apply
terraform -chdir=aws output
terraform -chdir=aws destroy

# swap aws → az or gcp
terraform -chdir=gcp apply
```

Or just `cd aws && terraform apply`. Each directory is a normal, independent
Terraform root — nothing special required.
