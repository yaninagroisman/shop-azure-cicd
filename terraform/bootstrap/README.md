# Bootstrap stack

Run **once**, locally, by the subscription owner. It creates what must exist
before the main stack and must survive its `terraform destroy`:

| Resource | Purpose |
|---|---|
| `rg-shop-bootstrap-swc` | Resource group for everything below |
| `stshoptfstate<suffix>` / container `tfstate` | Remote state for all stacks. ZRS, Entra ID only (no keys), versioning, 30-day soft delete, `prevent_destroy` + `CanNotDelete` lock. Locking uses blob leases |
| `id-shop-tf-plan`, `id-shop-tf-apply`, `id-shop-ci` | Managed identities for Azure Pipelines, federated with the service connections (no secrets) |
| Role assignments | `tf-plan`: Reader + state. `tf-apply`: Contributor + RBAC Administrator limited by an ABAC condition to an allow-list of roles + state. `ci`: nothing yet (the main stack grants AcrPush) |
| Azure DevOps project `shop` | Pipelines only; WIF service connections `sc-azure-*`; environment `dev` with approval; `tf-apply` connection: approval + main branch only; `ci` connection: main branch only |
| Budget | Subscription-wide, monthly; email at 25/50/80 % actual and 100 % forecast |
| Resource providers | Registered explicitly (`resource_providers_to_register`) |

## Prerequisites (manual, one time)

1. Tools: Terraform >= 1.11, Azure CLI.
2. `az login` with the account that owns the subscription, then
   `az account set --subscription <id>`.
3. An Azure DevOps organization (https://aex.dev.azure.com) that this account
   belongs to with permission to create projects.
4. Request the free Microsoft-hosted parallel job for the organization
   (https://aka.ms/azpipelines-parallelism-request). Approval takes a few days.

## Steps

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in real values (git-ignored)

# 1. First apply with local state (the backend does not exist yet)
terraform init
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan

# 2. Move this stack's own state into the storage account it created
terraform output -raw backend_config > backend.hcl
cp backend.tf.example backend.tf
terraform init -migrate-state -backend-config=backend.hcl
rm -f terraform.tfstate terraform.tfstate.backup bootstrap.tfplan   # local copies are no longer needed
```

After step 2, connect GitHub in Azure DevOps (Project settings → GitHub
connections → install the Azure Pipelines app for the repository).

## Changing the bootstrap

Edit, `terraform plan`, `terraform apply` as usual (state is remote).
Never run `terraform destroy` here during the project: `prevent_destroy` will
refuse anyway.

## Removing the bootstrap (end of the project)

The bootstrap costs only cents per month, but it is not removed by destroying
the main stack. Removal is deliberate, in this order:

1. Destroy every other stack first (`environments/dev`): their state lives in
   this storage account.
2. In `main.tf`, delete both `lifecycle { prevent_destroy = true }` blocks
   (storage account and container).
3. Bring this stack's state back to the local disk, because the backend is
   about to be deleted:

   ```bash
   rm backend.tf
   terraform init -migrate-state     # answer "yes"
   ```

4. `terraform destroy`. Terraform deletes the `CanNotDelete` lock before the
   storage account, so no manual unlock is needed.
5. Optional clean-up outside this stack: the Azure DevOps organization, and the
   local `terraform.tfstate*` files.

Note: a deleted Azure DevOps project stays restorable for 28 days, a deleted
storage account for 14 days.

## Security notes

- `sensitive = true` would not keep values out of state; that is why this stack
  creates no secrets at all, and why state access is restricted to Entra ID.
- The pipeline identities cannot grant themselves more rights: the ABAC
  condition on `tf-apply` only allows the roles in `assignable_role_names`, and
  validation forbids adding Owner, Contributor or the RBAC admin roles there.
- The Azure DevOps resources are managed here, not by a pipeline, so no
  pipeline can change its own approvals or service connections.

## Accepted risks (Checkov findings suppressed in code)

Each suppression is an inline `#checkov:skip` with its reason in `main.tf`.

| Check | Why it is accepted |
|---|---|
| CKV_AZURE_59 public network access | Microsoft-hosted agents use changing IPs (AD-29). Access needs an Entra ID token and a data role on the container; shared keys are disabled. |
| CKV2_AZURE_33 private endpoint | Private endpoints are deferred (AD-14); they would also need a self-hosted agent inside the VNet. |
| CKV_AZURE_33 queue logging | The account has no queues. |
| CKV2_AZURE_21 blob read logging | Needs a Log Analytics workspace that outlives the main stack; not worth a separate one for a learning project. |
| CKV_AZURE_206 replication | ZRS keeps three copies across availability zones. The check only accepts geo-redundant SKUs (GRS/GZRS); a second region is not needed here. |
| CKV2_AZURE_1 customer-managed key | Microsoft-managed keys plus infrastructure (double) encryption. A CMK needs its own Key Vault in the bootstrap. |
