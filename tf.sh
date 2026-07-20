#!/usr/bin/env bash
#
# Wrapper that pins the correct -state file and -var-file for a given cloud so
# they can never be forgotten. Every terraform command MUST go through here.
#
# Usage:
#   ./tf.sh <aws|az|gcp> <terraform-subcommand> [extra args...]
#
# Examples:
#   ./tf.sh aws plan
#   ./tf.sh az apply
#   ./tf.sh gcp destroy
#   ./tf.sh aws output
#
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <aws|az|gcp> <terraform-subcommand> [args...]" >&2
  exit 1
fi

T="$1"
shift

case "$T" in
  aws | az | gcp) ;;
  *)
    echo "Error: first argument must be one of: aws, az, gcp (got '$T')." >&2
    exit 1
    ;;
esac

mkdir -p state

exec terraform "$@" \
  -state="state/${T}.tfstate" \
  -var-file="envs/${T}-prod.tfvars"
