# Multi-Cloud Kubernetes with a Single Terraform Setup

One flat Terraform codebase that provisions a managed Kubernetes cluster on
**AWS (EKS)**, **Azure (AKS)**, or **GCP (GKE)** — the target cloud is chosen
by which tfvars file you pass at apply time.

## How it works

- `var.cloud` (`"aws" | "az" | "gcp"`) selects the target cloud.
- [locals.tf](locals.tf) turns that into `is_aws` / `is_azure` / `is_gcp`
  flags (`1` or `0`).
- Every resource in [eks-cluster.tf](eks-cluster.tf),
  [aks-cluster.tf](aks-cluster.tf), and [gke-cluster.tf](gke-cluster.tf)
  carries a `count` gated on its flag, so only the selected cloud's resources
  are created. The other two clouds produce **zero** resources.
- State is isolated **per cloud** with Terraform's `-state` flag — one state
  file per cloud under `state/`. There is **no remote backend**, **no
  workspaces**, and **no modules** — everything is at the root.


## Layout

```
.
├── providers.tf          # required_providers + the three provider blocks
├── variables.tf          # cloud, cluster_name, k8s_version + per-cloud flat vars
├── locals.tf             # is_aws / is_azure / is_gcp flags
├── networking.tf         # AWS VPC, subnets, IGW/NAT, route tables (EKS only)
├── eks-cluster.tf        # EKS cluster, node group, launch template + IAM roles
├── aks-cluster.tf        # resource group + AKS cluster
├── gke-cluster.tf        # GKE cluster + node pool
├── outputs.tf            # cluster_name, cluster_endpoint (coalesce over clouds)
├── tf.sh                 # wrapper that pins -state and -var-file
├── envs/
│   ├── aws-prod.tfvars
│   ├── az-prod.tfvars
│   └── gcp-prod.tfvars
└── state/                # gitignored, created by tf.sh
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

Everything goes through **`tf.sh`**, which appends the correct `-state` and
`-var-file` flags for the chosen cloud:

```bash
chmod +x tf.sh        # first time only

terraform init        # run once in the directory

./tf.sh aws   plan
./tf.sh aws   apply

./tf.sh az    plan
./tf.sh az    apply

./tf.sh gcp   plan
./tf.sh gcp   apply
```

Read outputs and tear down the same way:

```bash
./tf.sh aws output
./tf.sh aws show
./tf.sh aws destroy
```

Extra flags pass straight through, e.g.:

```bash
./tf.sh aws apply -auto-approve
./tf.sh gcp plan  -out=gcp.tfplan
```

### Without tf.sh

`tf.sh` is just a wrapper that appends `-state` and `-var-file` for the chosen
cloud. To run Terraform directly, pass those two flags yourself — the state
file is `state/<cloud>.tfstate` and the var file is `envs/<cloud>-prod.tfvars`
(where `<cloud>` is `aws`, `az`, or `gcp`):

```bash
mkdir -p state   # tf.sh does this for you; needed once when running bare

# AWS
terraform plan    -state="state/aws.tfstate" -var-file="envs/aws-prod.tfvars"
terraform apply   -state="state/aws.tfstate" -var-file="envs/aws-prod.tfvars"
terraform output  -state="state/aws.tfstate" -var-file="envs/aws-prod.tfvars"
terraform destroy -state="state/aws.tfstate" -var-file="envs/aws-prod.tfvars"

# Azure — swap aws → az
terraform apply   -state="state/az.tfstate"  -var-file="envs/az-prod.tfvars"

# GCP — swap aws → gcp
terraform apply   -state="state/gcp.tfstate" -var-file="envs/gcp-prod.tfvars"
```

Both flags are mandatory on **every** state-touching command. Omitting `-state`
falls back to the default `terraform.tfstate` and reads/writes the **wrong**
state — which is exactly what `tf.sh` exists to prevent.

## ⚠️ Always use tf.sh

> **Every** Terraform command that touches state — `plan`, `apply`,
> `destroy`, `output`, `show` — **must** go through `./tf.sh <cloud> ...`.
>
> Running bare `terraform apply` (or `output`, `show`, `destroy`, …) uses the
> default `terraform.tfstate` instead of the per-cloud state file. That reads
> the **wrong state**, and an `apply`/`destroy` can corrupt or orphan real
> infrastructure. `init` is the only command you run bare.
