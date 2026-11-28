# Run by terraform_data.root_application (local-exec). Needs the Azure CLI
# signed in (az login locally, AzureCLI task in the pipeline) and jq.
set -euo pipefail

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
printf '%s\n' "$MANIFEST" > "$workdir/root-app.yaml"
cd "$workdir"

for attempt in 1 2 3 4 5 6 7 8; do
  result="$(az aks command invoke \
    --subscription "$SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --command "kubectl apply -f root-app.yaml" \
    --file root-app.yaml \
    --output json)" || result='{}'

  printf '%s\n' "$result" | jq -r '.logs // empty'
  exit_code="$(printf '%s\n' "$result" | jq -r '.exitCode // 1')"
  if [ "$exit_code" = "0" ]; then
    exit 0
  fi

  # Usual cause on the first apply: the namespace role assignment has not
  # reached the cluster yet, or the extension is still starting.
  echo "Attempt $attempt failed (exit code $exit_code); retrying in 30 s." >&2
  sleep 30
done

echo "Could not apply the Argo CD root Application." >&2
exit 1
