# shellcheck shell=bash
# Run by terraform_data.root_application (local-exec). Needs the Azure CLI
# signed in (az login locally, AzureCLI task in the pipeline) and jq.
#
# Starts the command with --no-wait and polls `az aks command result`
# instead of letting `az aks command invoke` wait: when the command fails
# before kubectl runs (for example its pod cannot be scheduled), the waiting
# form only says "Operation returned an invalid status 'OK'" (Azure CLI
# 2.93), while the result carries the real reason.
set -euo pipefail

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
printf '%s\n' "$MANIFEST" > "$workdir/root-app.yaml"
cd "$workdir"

aks=(--subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME")

# Prints the final result JSON of one run, or nothing if it never finished.
run_once() {
  local started command_id result state
  started="$(az aks command invoke "${aks[@]}" \
    --command "kubectl apply -f root-app.yaml" \
    --file root-app.yaml \
    --no-wait 2>&1)" || { echo "$started" >&2; return 0; }

  command_id="$(printf '%s\n' "$started" | sed -n 's/^[Cc]ommand id: \([0-9a-f]*\),.*/\1/p')"
  if [ -z "$command_id" ]; then
    echo "$started" >&2
    return 0
  fi

  # Up to 5 minutes per run (pulling the kubectl image takes a while).
  for _ in $(seq 60); do
    result="$(az aks command result "${aks[@]}" --command-id "$command_id" --output json)" || result='{}'
    state="$(printf '%s\n' "$result" | jq -r '.provisioningState // "Running"')"
    case "$state" in
      Succeeded | Failed | Canceled)
        printf '%s\n' "$result"
        return 0
        ;;
    esac
    sleep 5
  done
  echo "Command $command_id did not finish in 5 minutes." >&2
}

for attempt in 1 2 3 4 5 6 7 8; do
  result="$(run_once)"
  result="${result:-"{}"}"

  printf '%s\n' "$result" | jq -r '.logs // empty'
  state="$(printf '%s\n' "$result" | jq -r '.provisioningState // "Unknown"')"
  exit_code="$(printf '%s\n' "$result" | jq -r '.exitCode // 1')"
  if [ "$state" = "Succeeded" ] && [ "$exit_code" = "0" ]; then
    exit 0
  fi

  reason="$(printf '%s\n' "$result" | jq -r '.reason // empty')"
  echo "Attempt $attempt failed: state $state, exit code $exit_code${reason:+, reason: $reason}" >&2

  # Usual cause on the first apply: the namespace role assignment has not
  # reached the cluster yet, or the extension is still starting.
  # "Unschedulable" means the nodes are full: retrying will not help.
  case "$reason" in
    Unschedulable*) break ;;
  esac
  sleep 30
done

echo "Could not apply the Argo CD root Application." >&2
exit 1
