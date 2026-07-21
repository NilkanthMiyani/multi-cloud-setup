# GCP / GKE — standalone Terraform for this cloud only.
#
# For when you only care about GCP: run these from inside this directory.
# Inputs auto-load from terraform.tfvars; state is local to this directory.
#
#   make init | plan | apply | destroy | output | show
#   make apply AUTO=1     # skip the confirmation prompt

TF := terraform

ifeq ($(AUTO),1)
  APPROVE := -auto-approve
endif

.DEFAULT_GOAL := help

.PHONY: help init upgrade fmt validate plan apply destroy output show

help:
	@echo "GCP / GKE Terraform — run from inside this directory"
	@echo "  make init | plan | apply | destroy | output | show"
	@echo "  make fmt | validate | upgrade"
	@echo "  AUTO=1   skip the apply/destroy confirmation prompt"

# Initialize once; the .terraform marker means init only re-runs when missing,
# and every state target depends on it (so a fresh checkout self-inits).
.terraform:
	$(TF) init

init: .terraform

# Force a re-init to pull provider/version changes.
upgrade:
	$(TF) init -upgrade

fmt:
	$(TF) fmt

validate: .terraform
	$(TF) validate

plan: .terraform
	$(TF) plan

apply: .terraform
	$(TF) apply $(APPROVE)

destroy: .terraform
	$(TF) destroy $(APPROVE)

output: .terraform
	$(TF) output

show: .terraform
	$(TF) show
