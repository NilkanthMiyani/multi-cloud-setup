# Multi-Cloud Kubernetes with a Single Terraform Setup

One flat Terraform codebase that provisions a managed Kubernetes cluster on
**AWS (EKS)**, **Azure (AKS)**, or **GCP (GKE)** — the target cloud is chosen
by which **Terraform workspace** you select.

## How it works

- The **workspace name** (`aws` | `az` | `gcp`) selects the target cloud.
- [locals.tf](locals.tf) reads `terraform.workspace` into `local.cloud` and
  turns it into `is_aws` / `is_azure` / `is_gcp` flags (`1` or `0`). Selecting
  an unknown workspace (including the `default` one) fails the run immediately.
- Every resource in [eks-cluster.tf](eks-cluster.tf),
  [aks-cluster.tf](aks-cluster.tf), and [gke-cluster.tf](gke-cluster.tf)
  carries a `count` gated on its flag, so only the selected cloud's resources
  are created. The other two clouds produce **zero** resources.
- State is isolated **per cloud** by the workspace — each lives under
  `terraform.tfstate.d/<cloud>/terraform.tfstate` automatically, no `-state`
  flag needed. There is **no remote backend** and **no modules** — everything
  is at the root.


## Layout

```
.
├── providers.tf          # required_providers + the three provider blocks
├── variables.tf          # cluster_name, k8s_version + per-cloud flat vars
├── locals.tf             # cloud (from workspace) + is_aws / is_azure / is_gcp
├── networking.tf         # AWS VPC, subnets, IGW/NAT, route tables (EKS only)
├── eks-cluster.tf        # EKS cluster, node group, launch template + IAM roles
├── aks-cluster.tf        # resource group + AKS cluster
├── gke-cluster.tf        # GKE cluster + node pool
├── outputs.tf            # cluster_name, cluster_endpoint (coalesce over clouds)
├── Makefile              # per-cloud shortcuts: make apply aws, plan gcp, ...
├── envs/
│   ├── aws-prod.tfvars
│   ├── az-prod.tfvars
│   └── gcp-prod.tfvars
└── terraform.tfstate.d/  # gitignored, one state dir per workspace
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) **>= 1.5**
- The CLI + credentials for whichever cloud(s) you target (see below).

## Authentication setup

> ⚠️ **All three providers are configured on every run.** Because the config
> contains resource blocks for all three clouds, Terraform configures all three
> providers regardless of `var.cloud` — and the **azurerm** provider
> authenticates *eagerly*, so a valid Azure session (`az login` or `ARM_*`
> credentials) is required even when you are deploying AWS or GCP. The `count`
> gate only suppresses *resources*, not provider authentication. The AWS and
> GCP providers authenticate lazily and don't block a run for another cloud.

### AWS

```bash
aws configure          # or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
aws sts get-caller-identity   # verify
```

The region comes from `envs/aws-prod.tfvars` (`region`).

Alternatively set `aws_access_key` and `aws_secret_key` in `envs/aws-prod.tfvars`.
Leave them blank (the default) to use the standard AWS credential chain shown
above.

### Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"   # required by the azurerm provider
```

Alternatively set `azure_subscription_id` in `envs/az-prod.tfvars`.

### GCP

```bash
gcloud auth application-default login
gcloud config set project "<PROJECT_ID>"
```

Set `gcp_project` in `envs/gcp-prod.tfvars` to the same project id.

## Usage

### With the Makefile (recommended)

The [Makefile](Makefile) keeps the workspace and the `-var-file` lined up for
you — give the verb, then the cloud as a plain word:

```bash
make init                 # once per checkout

make plan aws             # select aws workspace + plan with aws-prod.tfvars
make apply aws            # apply (prompts for confirmation)
make apply aws AUTO=1     # apply with -auto-approve
make output aws
make destroy aws

# swap the cloud for az / gcp: make plan az, make apply gcp, ...
```

The pattern is always `make <verb> <cloud>` (cloud = `aws` | `az` | `gcp`):

| Command | What it does |
|---------|--------------|
| `make init` | Initialize Terraform — run once per checkout (also auto-runs on first use). |
| `make upgrade` | Re-init with `-upgrade` to pull provider/version changes (`init` won't, once `.terraform/` exists). |
| `make plan <cloud>` | Select the cloud's workspace and show the plan. |
| `make apply <cloud>` | Apply (asks for confirmation). Add `AUTO=1` to skip the prompt. |
| `make destroy <cloud>` | Tear the cloud's cluster down. Add `AUTO=1` to skip the prompt. |
| `make output <cloud>` | Print the cloud's outputs. |
| `make show <cloud>` | Show the cloud's current state. |
| `make fmt` | `terraform fmt` across the tree. |
| `make validate` | Validate the configuration. |
| `make help` | List everything above. |

Under the hood these just run the raw commands below — nothing is hidden.

### Raw Terraform

Select the workspace for your target cloud (the workspace name *is* the cloud),
then run Terraform with that cloud's var-file:

```bash
terraform init                          # run once in the directory

# Create each workspace the first time (idempotent — skip once they exist):
terraform workspace new aws
terraform workspace new az
terraform workspace new gcp

# AWS
terraform workspace select aws
terraform plan    -var-file=envs/aws-prod.tfvars
terraform apply   -var-file=envs/aws-prod.tfvars

# Azure — swap aws → az
terraform workspace select az
terraform apply   -var-file=envs/az-prod.tfvars

# GCP — swap aws → gcp
terraform workspace select gcp
terraform apply   -var-file=envs/gcp-prod.tfvars
```

Read outputs and tear down against the selected workspace:

```bash
terraform workspace select aws
terraform output
terraform show
terraform destroy -var-file=envs/aws-prod.tfvars
```

`terraform workspace show` prints the workspace you're currently in.

## ⚠️ Match the workspace to the var-file

> The workspace picks the **state** and the **cloud**; the `-var-file` picks
> the matching **inputs**. Keep them aligned — select `aws`, pass
> `envs/aws-prod.tfvars`.
>
> `apply`/`plan`/`destroy` require the matching `-var-file`. `output`, `show`,
> and `init` don't. Running in the `default` workspace (or any name other than
> `aws`/`az`/`gcp`) fails fast via the guard in [locals.tf](locals.tf), so a
> bare `terraform apply` can't silently touch the wrong state.
