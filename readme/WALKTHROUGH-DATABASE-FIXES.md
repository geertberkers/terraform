# Walkthrough: Key Vault Integration & Database Testing

This document details the recent updates to secure the multi-database backend using Azure Key Vault and the addition of automated connectivity tests.

## Security Hardening (Key Vault Integration)

### 1. Database Module Update
- The `databases` module now exports **versionless secret URIs** for all database credentials instead of plaintext passwords.
- This ensures that sensitive information is managed centrally in Azure Key Vault.

### 2. App Service Module Update
- The `app_service` module now uses **Key Vault References** in its application settings.
- **Format**: `@Microsoft.KeyVault(SecretUri=...)`
- **Result**: The App Service automatically fetches these secrets at runtime using its Managed Identity.

### 3. Connection Mapping
- `POSTGRES_PASSWORD` -> Key Vault Secret
- `MYSQL_PASSWORD` -> Key Vault Secret
- `SQLSERVER_PASSWORD` -> Key Vault Secret
- `COSMOS_CONNECTION_STRING` -> Key Vault Connection Secret

---

## Database Connectivity Testing (Kotlin)

### 1. New Test Suite
- A new integration test has been added: `multi-db-backend/src/test/kotlin/com/example/app/database/DatabaseConnectionTest.kt`.
- This test verifies connectivity to **PostgreSQL**, **MySQL**, and **SQL Server**.

### 2. How to Run the Tests

#### Locally (using Docker Compose)
1. Start your local environment:
   ```powershell
   docker-compose up -d
   ```
2. Run the tests:
   ```powershell
   ./gradlew test
   ```

#### Remotely (Azure)
To test the live Azure databases from your local machine:
1. Ensure your local IP is added to the database firewall rules (via Azure Portal).
2. Set the environment variables in your local shell (e.g., `POSTGRES_HOST`, `POSTGRES_PASSWORD`).
3. Run `./gradlew test`.

---

## How to Apply These Changes
1. **Azure CLI**: Make sure you have the Azure CLI installed and you are logged in (`az login`).
2. **Terraform**:
   ```powershell
   terraform init
   ```
   *Note: If you see error about "az" not found, ensure Azure CLI is in your PATH.*
   ```powershell
   terraform apply
   ```
3. **App Restart**: Restart the App Service to refresh the Key Vault references:
   ```powershell
   az webapp restart --name <app-name> --resource-group <rg-name>
   ```
