# Multi-Database Backend with Azure Managed Identity

A Kotlin Ktor backend that provides secure multi-database access using Azure Managed Identity, with a server-side rendered HTML dashboard.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│           Azure Web App (Managed Identity)          │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌────────────────────────────────────────────────┐ │
│  │         Kotlin Ktor Backend (Port 8080)       │ │
│  ├────────────────────────────────────────────────┤ │
│  │  • Dashboard (Server-side rendered HTML)       │ │
│  │  • REST APIs for CRUD operations               │ │
│  │  • Multi-database query engine                 │ │
│  └────────────────────────────────────────────────┘ │
│                       ↓                               │
│  ┌─────────────┬──────────────┬──────────────────┐  │
│  ↓             ↓              ↓                  ↓   │
│ PostgreSQL   MySQL       SQL Server         CosmosDB │
│ (Flexible)  (Flexible)   (Managed)          (NoSQL)  │
│                                                       │
└─────────────────────────────────────────────────────┘
```

## Features

✅ **Azure Managed Identity** - Secure authentication without storing credentials
✅ **Multi-Database Support** - PostgreSQL, MySQL, SQL Server, CosmosDB
✅ **CRUD Operations** - Full read/write capability for all databases
✅ **Server-Side Rendered** - Freemarker templates for dynamic HTML
✅ **REST APIs** - JSON endpoints for programmatic access
✅ **Docker Support** - Multi-stage builds for production-ready containers
✅ **CI/CD Pipeline** - GitHub Actions for automated deployment
✅ **Health Checks** - Kubernetes-ready health endpoints

## Prerequisites

- Java 17+
- Gradle 8.5+
- Docker & Docker Compose (for local development)
- Azure CLI (for Azure deployment)
- Git

## Local Development

### 1. Start all databases with Docker Compose

```bash
docker-compose up -d
```

This starts:
- PostgreSQL 15
- MySQL 8.0
- SQL Server 2022
- Watches all services with health checks

### 2. Set environment variables

```bash
cp .env.example .env
# Edit .env with local database credentials
```

### 3. Build and run the application

```bash
./gradlew run
```

Or build a JAR:

```bash
./gradlew fatJar
java -jar build/libs/multi-db-backend-*-all.jar
```

### 4. Access the dashboard

Open http://localhost:8080/dashboard in your browser

## API Endpoints

### Dashboard
- `GET /dashboard` - Interactive multi-database dashboard (HTML)
- `GET /dashboard/api/info` - Dashboard metadata (JSON)

### Database Operations
- `GET /api/database/list` - List available databases
- `POST /api/database/query` - Execute SELECT query
  ```json
  {
    "database": "postgresql",
    "query": "SELECT * FROM users LIMIT 10;"
  }
  ```
- `POST /api/database/execute` - Execute INSERT/UPDATE/DELETE
  ```json
  {
    "database": "postgresql",
    "sql": "INSERT INTO users (name, email) VALUES (?, ?);",
    "params": ["John Doe", "john@example.com"]
  }
  ```

### Health Check
- `GET /health` - Service health status

## Azure Deployment

### 1. Create Azure Resources

```bash
cd terraform

# Update main.tf with your configuration
terraform plan
terraform apply
```

This creates:
- Resource groups
- PostgreSQL, MySQL, SQL Server instances
- CosmosDB account
- Web App with Managed Identity
- Key Vault for secrets
- Network configuration

### 2. Set up GitHub Secrets

Required secrets for GitHub Actions:
```
AZURE_CREDENTIALS      - Service principal JSON
AZURE_WEBAPP_NAME      - Your web app name
AZURE_REGISTRY_LOGIN   - Container registry login
AZURE_REGISTRY_PASSWORD- Container registry password
```

### 3. Deploy via GitHub Actions

Push to main branch:
```bash
git push origin main
```

This triggers:
1. Build and unit tests
2. Docker image build and push
3. Automatic deployment to Azure Web App

### 4. Configure Environment Variables in Azure

In Azure Portal > App Service > Settings > Configuration:

```
POSTGRES_HOST     = pg-flex-global.postgres.database.azure.com
POSTGRES_DB       = appdb
POSTGRES_USER     = postgres@pg-flex-global

MYSQL_HOST        = mysql-global.mysql.database.azure.com
MYSQL_DB          = appdb
MYSQL_USER        = root@mysql-global

SQLSERVER_HOST    = sql-global.database.windows.net
SQLSERVER_DB      = master
SQLSERVER_USER    = sqladmin

PORT              = 8080
```

> **Note:** Passwords should NOT be stored as app settings. Use:
> - Azure Managed Identity for certificates/Azure AD auth
> - Azure Key Vault integrated with the app

## Authentication Methods

### PostgreSQL with Managed Identity

The app uses DefaultAzureCredential which attempts:
1. Environment Variables
2. Managed Identity (IMDS)
3. Azure CLI credentials
4. Visual Studio credentials

### MySQL & SQL Server

Since MySQL doesn't support Azure AD natively, use:
- App settings with encrypted connection strings
- Azure Key Vault for secure credential management

### Connection String Format for Azure

```
// PostgreSQL with AD
postgresql://user@server.postgres.database.azure.com:5432/database?sslmode=require

// MySQL with SSL
mysql://user@server.mysql.database.azure.com:3306/database?useSSL=true

// SQL Server with AD
sqlserver://server.database.windows.net:1433;database=master;authentication=ActiveDirectoryManagedIdentity
```

## Monitoring

### Azure Application Insights
```bash
# View logs
az webapp log tail --name your-app-name --resource-group your-rg
```

### Docker logs
```bash
docker-compose logs -f app
```

### Health check
```bash
curl http://localhost:8080/health
```

## Security Best Practices

✅ **Managed Identity** - No credentials in code
✅ **TLS/SSL** - All database connections encrypted
✅ **Network Security** - NSGs and virtual networks
✅ **Input Validation** - Parameterized queries prevent SQL injection
✅ **Secret Management** - Azure Key Vault integration
✅ **Access Control** - Role-based access via Azure AD
✅ **Audit Logging** - All operations logged

## Troubleshooting

### Connection Strings not working

If you see "FATAL: password authentication failed":
1. Verify managed identity has database permissions
2. Check that user is set to `<loginname>@<servername>`
3. Ensure TLS/SSL is properly configured

### Docker Compose fails

```bash
# Reset everything
docker-compose down -v
docker system prune -a

# Try again
docker-compose up --build
```

### Azure deployment fails

```bash
# Check logs
az webapp log tail --name your-app-name --resource-group your-rg

# Verify configuration
az webapp config appsettings list --name your-app-name --resource-group your-rg
```

## Project Structure

```
.
├── build.gradle.kts                 # Gradle configuration
├── docker-compose.yml               # Local dev database setup
├── Dockerfile                       # Production build
├── .github/workflows/
│   └── deploy.yml                  # CI/CD pipeline
├── src/main/kotlin/
│   └── com/example/app/
│       ├── Application.kt           # Entry point
│       ├── plugins/                 # Ktor plugins
│       │   ├── Serialization.kt
│       │   ├── StatusPages.kt
│       │   ├── Freemarker.kt
│       │   ├── Routing.kt
│       │   └── AzureAuth.kt
│       ├── database/                # Database layer
│       │   ├── DatabaseFactory.kt   # Connection management
│       │   └── DatabaseService.kt   # Query execution
│       ├── feature/
│       │   ├── routing/             # HTTP routes
│       │   │   ├── DatabaseRoutes.kt
│       │   │   └── DashboardRoutes.kt
│       │   └── dto/                 # Request/response models
│       └── common/                  # Shared utilities
│           └── AppError.kt          # Error types
└── src/main/resources/
    └── templates/
        └── dashboard.ftl            # Freemarker template

terraform/
├── main.tf                          # Main configuration
├── backend.tf                       # Terraform backend
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
└── modules/
    ├── app_service/                 # Web App module
    │   ├── main.tf
    │   ├── managed_identity.tf      # Managed Identity setup
    │   └── variables.tf
    └── databases/                   # Databases module
        ├── postgres.tf
        ├── mysql.tf
        ├── sql.tf
        ├── cosmos.tf
        ├── keyvault.tf
        ├── managed_identity.tf
        └── variables.tf
```

## Next Steps

1. **Testing** - Add unit tests with JUnit5 and integration tests with testcontainers
2. **Monitoring** - Set up Application Insights and custom metrics
3. **Performance** - Add query caching with Redis
4. **Authentication** - Implement Azure AD authentication for the dashboard
5. **Rate Limiting** - Add request throttling to prevent abuse
6. **Audit Logging** - Enhanced logging with ELK stack

## License

MIT
