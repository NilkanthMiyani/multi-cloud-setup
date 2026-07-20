# Multi-cloud Terraform driver.
#
# Each cloud is a self-contained root module in its own directory (aws/, az/,
# gcp/), so a run only ever loads that cloud's provider — no cross-cloud auth.
# Inputs come from each dir's auto-loaded terraform.tfvars.
#
# Usage — give the verb, then the cloud as a plain word:
#   make plan aws      make apply az      make destroy gcp      make output aws
#
# Skip the apply/destroy confirmation prompt with AUTO=1:
#   make apply aws AUTO=1

TF     := terraform
CLOUDS := aws az gcp

# The cloud is passed as a bare goal (make plan aws). Pick it out of the goals
# make was invoked with; CLOUD=aws on the command line still works and wins.
CLOUD ?= $(firstword $(filter $(CLOUDS),$(MAKECMDGOALS)))

ifeq ($(AUTO),1)
  APPROVE := -auto-approve
endif

.DEFAULT_GOAL := help

.PHONY: help init upgrade fmt validate guard-cloud ensure-init \
        plan apply destroy output show $(CLOUDS)

help:
	@echo "Multi-cloud Terraform (one directory per cloud)"
	@echo
	@echo "Usage:  make <verb> <cloud>      cloud = aws | az | gcp"
	@echo "  make plan aws       make apply az        make destroy gcp"
	@echo "  make output aws     make show gcp"
	@echo
	@echo "Options:  AUTO=1   skip the apply/destroy confirmation prompt"
	@echo "Setup:    make init <cloud> | upgrade <cloud> | validate <cloud> | fmt"

# The cloud names are captured into CLOUD above; as goals they are no-ops so
# that 'make plan aws' doesn't complain about an unknown target 'aws'.
$(CLOUDS):
	@:

guard-cloud:
	@if [ -z "$(CLOUD)" ]; then \
	  echo "Name a cloud: make $(firstword $(MAKECMDGOALS)) <aws|az|gcp>."; exit 1; fi

# Auto-init a cloud's directory on first use; every state target depends on it.
ensure-init: guard-cloud
	@[ -d $(CLOUD)/.terraform ] || $(TF) -chdir=$(CLOUD) init

# --- setup -----------------------------------------------------------------

init: guard-cloud
	$(TF) -chdir=$(CLOUD) init

# Re-init with -upgrade to pull provider/version changes.
upgrade: guard-cloud
	$(TF) -chdir=$(CLOUD) init -upgrade

# fmt is repo-wide; no cloud needed.
fmt:
	$(TF) fmt -recursive

validate: ensure-init
	$(TF) -chdir=$(CLOUD) validate

# --- verbs -----------------------------------------------------------------

plan: ensure-init
	$(TF) -chdir=$(CLOUD) plan

apply: ensure-init
	$(TF) -chdir=$(CLOUD) apply $(APPROVE)

destroy: ensure-init
	$(TF) -chdir=$(CLOUD) destroy $(APPROVE)

output: ensure-init
	$(TF) -chdir=$(CLOUD) output

show: ensure-init
	$(TF) -chdir=$(CLOUD) show
