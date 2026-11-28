output "id" {
  description = "ID of the vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the vault (used in SecretProviderClass manifests)."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Data-plane URI of the vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_names" {
  description = "Names of the generated secrets (names only, no values)."
  value       = sort([for s in azurerm_key_vault_secret.generated : s.name])
}

output "signing_key_uri" {
  description = "Cosign key reference: cosign sign --key <this> ..."
  value       = "azurekms://${trimprefix(trimsuffix(azurerm_key_vault.this.vault_uri, "/"), "https://")}/${azurerm_key_vault_key.signing.name}"
}

output "signing_public_key_pem" {
  description = "Public half of the Cosign key, for Kyverno verifyImages (not a secret)."
  value       = azurerm_key_vault_key.signing.public_key_pem
}
