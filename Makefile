# Multi-cloud Terraform driver.
#
# The Terraform workspace name *is* the cloud (aws | az | gcp); each cloud reads
# its inputs from envs/<cloud>-prod.tfvars. These targets keep the workspace and
# the -var-file lined up for you, so you never have to remember either.
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

VARFILE = envs/$(CLOUD)-prod.tfvars
ifeq ($(AUTO),1)
  APPROVE := -auto-approve
endif

.DEFAULT_GOAL := help

.PHONY: help init upgrade fmt validate guard-cloud workspace \
        plan apply destroy output show $(CLOUDS)

help:
	@echo "Multi-cloud Terraform (workspace = cloud)"
	@echo
	@echo "Usage:  make <verb> <cloud>      cloud = aws | az | gcp"
	@echo "  make plan aws       make apply az        make destroy gcp"
	@echo "  make output aws     make show gcp"
	@echo
	@echo "Options:  AUTO=1   skip the apply/destroy confirmation prompt"
	@echo "Setup:    make init | upgrade | fmt | validate"

# The cloud names are captured into CLOUD above; as goals they are no-ops so
# that 'make plan aws' doesn't complain about an unknown target 'aws'.
$(CLOUDS):
	@:

# Initialize once. The .terraform marker means init only re-runs when missing,
# and every state-touching target below depends on it.
.terraform:
	$(TF) init

init: .terraform

# Force a re-init to pull provider/version changes. Plain `init` skips this
# because the .terraform marker already exists; `upgrade` always runs and
# refreshes the marker + the lock file.
upgrade:
	$(TF) init -upgrade

fmt:
	$(TF) fmt -recursive

# --- internals -------------------------------------------------------------

guard-cloud:
	@if [ -z "$(CLOUD)" ]; then \
	  echo "Name a cloud: make $(firstword $(MAKECMDGOALS)) <aws|az|gcp>."; exit 1; fi
	@case "$(CLOUD)" in aws|az|gcp) ;; *) \
	  echo "cloud must be one of: aws, az, gcp (got '$(CLOUD)')."; exit 1;; esac

# Select the cloud's workspace, creating it on first use.
workspace: .terraform guard-cloud
	@$(TF) workspace select $(CLOUD) 2>/dev/null || $(TF) workspace new $(CLOUD)

# --- verbs -----------------------------------------------------------------

validate: .terraform
	$(TF) validate

plan: workspace
	$(TF) plan -var-file=$(VARFILE)

apply: workspace
	$(TF) apply $(APPROVE) -var-file=$(VARFILE)

destroy: workspace
	$(TF) destroy $(APPROVE) -var-file=$(VARFILE)

output: workspace
	$(TF) output

show: workspace
	$(TF) show
