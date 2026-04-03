# Multi-Database Kotlin Ktor Backend

A production-ready backend system written in Kotlin using Ktor framework, providing secure access to multiple databases (PostgreSQL, MySQL, SQL Server, CosmosDB) via Azure Managed Identity.

## Quick Start

### Local Development
```bash
# Start all databases
docker-compose up -d

# Run the backend
./gradlew run

# Open dashboard
open http://localhost:8080/dashboard
```

### Azure Deployment
```bash
cd terraform
terraform apply

git push origin main  # Triggers GitHub Actions deployment
```

## Key Features

- 🔐 **Azure Managed Identity** - Zero-trust authentication
- 🗄️ **Multi-Database** - Kotlin Exposed ORM with JDBC drivers
- 🎨 **Server-Side Templates** - Freemarker for dynamic HTML dashboard
- ⚡ **REST APIs** - JSON endpoints for CRUD operations
- 🐳 **Docker Ready** - Multi-stage builds, health checks
- 🚀 **CI/CD** - GitHub Actions with Azure deployment
- 📊 **Query Builder** - Interactive SQL interface

## Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Complete setup and deployment instructions
- [API Reference](#api-reference) - Available endpoints
- [Architecture](#architecture) - System design

## API Reference

### Dashboard
```
GET  /dashboard              # HTML dashboard
GET  /dashboard/api/info     # Dashboard metadata
```

### Database Operations
```
GET  /api/database/list              # List available databases
POST /api/database/query             # Execute SELECT
POST /api/database/execute           # Execute INSERT/UPDATE/DELETE
```

### Health
```
GET  /health                 # Service health check
```

## Architecture

```
┌────────────────────────────────────────────────┐
│         Azure Web App (Managed Identity)       │
├────────────────────────────────────────────────┤
│  Kotlin Ktor Backend                           │
│  ├─ REST API Layer                             │
│  ├─ Service Layer (Business Logic)             │
│  ├─ Database Layer (Multi-DB Support)          │
│  └─ Freemarker Template Engine                 │
├────────────────────────────────────────────────┤
│  PostgreSQL │ MySQL │ SQL Server │ CosmosDB   │
└────────────────────────────────────────────────┘
```

## Environment Variables

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=appdb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DB=appdb
MYSQL_USER=root
MYSQL_PASSWORD=your_password

SQLSERVER_HOST=localhost
SQLSERVER_PORT=1433
SQLSERVER_DB=master
SQLSERVER_USER=sa
SQLSERVER_PASSWORD=your_password

PORT=8080
```

## Technologies

- **Runtime**: Kotlin 2.0, JDK 17
- **Framework**: Ktor 2.3
- **ORM**: Jetbrains Exposed 0.52
- **Authentication**: Azure Identity SDK
- **Templates**: Freemarker
- **Databases**: PostgreSQL, MySQL, SQL Server, CosmosDB
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **IaC**: Terraform

## Getting Started

### Prerequisites
- Java 17+
- Gradle 8.5+
- Docker (for local dev)
- Azure account (for cloud deployment)

### Installation

1. Clone and navigate to project:
```bash
cd multi-db-backend
```

2. Copy environment template:
```bash
cp .env.example .env
```

3. Start local databases:
```bash
docker-compose up -d
```

4. Build and run:
```bash
./gradlew run
```

5. Visit dashboard:
```
http://localhost:8080/dashboard
```

## Database Configuration

### PostgreSQL
Uses Azure AD token for authentication when Managed Identity is available, falls back to password.

### MySQL
Connection via SSL/TLS with username/password authentication.

### SQL Server
Supports both SQL authentication and Azure AD (via connection string changes).

### CosmosDB
SDK integration prepared for MongoDB or SQL API.

## Security

- ✅ No hardcoded credentials
- ✅ Azure Managed Identity authentication
- ✅ TLS/SSL encrypted connections
- ✅ Parameterized queries (SQL injection prevention)
- ✅ Azure Key Vault integration
- ✅ Role-based access control

## Monitoring & Logging

- Application Insights integration
- Structured logging with SLF4J/Logback
- Health check endpoints
- Docker compose health checks
- Azure Web App diagnostics

## Troubleshooting

### "Connection refused"
- Verify database containers are running: `docker-compose ps`
- Check credentials in `.env`

### "Azure authentication failed"
- Ensure you're logged in: `az login`
- Check Managed Identity permissions in Azure

### "Port already in use"
- Change port in `.env` or docker-compose.yml
- Check what's using the port: `lsof -i :8080`

## Contributing

1. Create feature branch
2. Make changes
3. Run tests: `./gradlew test`
4. Submit PR

## Support

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed troubleshooting and advanced configuration.

## License

MIT License - See LICENSE file for details
