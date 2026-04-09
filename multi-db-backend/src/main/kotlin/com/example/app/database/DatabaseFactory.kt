package com.example.app.database

import com.azure.core.credential.TokenRequestContext
import com.azure.identity.DefaultAzureCredentialBuilder
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import com.example.app.getAppLogger
import javax.sql.DataSource

object DatabaseFactory {
    private var pgDataSource: DataSource? = null
    private var mysqlDataSource: DataSource? = null
    private var sqlServerDataSource: DataSource? = null
    private var cosmosDataSource: DataSource? = null
    private lateinit var logger: com.example.app.logging.Logger

    fun init() {
        logger = getAppLogger()
        logger.info("=== DATABASE INITIALIZATION BEGIN ===")

        // PostgreSQL
        val postgresHost = System.getenv("POSTGRES_HOST")
        if (postgresHost != null && postgresHost.isNotEmpty()) {
            logger.info("Attempting PostgreSQL connection to: $postgresHost:${System.getenv("POSTGRES_PORT") ?: "5432"}")
            try {
                pgDataSource = initPostgres()
                logger.info("✓ PostgreSQL connection initialized successfully")
            } catch (e: Exception) {
                logger.warn("✗ Failed to initialize PostgreSQL: ${e.message}", e)
            }
        } else {
            logger.info("PostgreSQL not configured (POSTGRES_HOST not set)")
        }

        // MySQL
        val mysqlHost = System.getenv("MYSQL_HOST")
        if (mysqlHost != null && mysqlHost.isNotEmpty()) {
            logger.info("Attempting MySQL connection to: $mysqlHost:${System.getenv("MYSQL_PORT") ?: "3306"}")
            try {
                mysqlDataSource = initMySQL()
                logger.info("✓ MySQL connection initialized successfully")
            } catch (e: Exception) {
                logger.warn("✗ Failed to initialize MySQL: ${e.message}", e)
            }
        } else {
            logger.info("MySQL not configured (MYSQL_HOST not set)")
        }

        // SQL Server
        val sqlHost = System.getenv("SQL_SERVER_HOST")
        if (sqlHost != null && sqlHost.isNotEmpty()) {
            logger.info("Attempting SQL Server connection to: $sqlHost:${System.getenv("SQLSERVER_PORT") ?: "1433"}")
            try {
                sqlServerDataSource = initSQLServer()
                logger.info("✓ SQL Server connection initialized successfully")
            } catch (e: Exception) {
                logger.warn("✗ Failed to initialize SQL Server: ${e.message}", e)
            }
        } else {
            logger.info("SQL Server not configured (SQL_SERVER_HOST not set)")
        }

        // CosmosDB (placeholder)
        logger.info("CosmosDB integration prepared for SDK setup (not yet implemented)")
        cosmosDataSource = initCosmosDB()

        logger.info("=== DATABASE INITIALIZATION COMPLETE ===")
    }

    fun getPostgresDataSource(): DataSource? = pgDataSource
    fun getMySQLDataSource(): DataSource? = mysqlDataSource
    fun getSQLServerDataSource(): DataSource? = sqlServerDataSource
    fun getCosmosDataSource(): DataSource? = cosmosDataSource

    private fun initPostgres(): DataSource {
        val postgresHost = System.getenv("POSTGRES_HOST") ?: "localhost"
        val postgresPort = System.getenv("POSTGRES_PORT") ?: "5432"
        val postgresDb = System.getenv("POSTGRES_DB") ?: "appdb"
        val postgresUser = System.getenv("POSTGRES_USER") ?: "postgres"

        logger.info("PostgreSQL config: host=$postgresHost, port=$postgresPort, db=$postgresDb, user=$postgresUser")

        val config = HikariConfig().apply {
            driverClassName = "org.postgresql.Driver"
            jdbcUrl = "jdbc:postgresql://$postgresHost:$postgresPort/$postgresDb"
            username = postgresUser

            // Try managed identity first, then environment variable
            password = try {
                if (System.getProperty("azure.credential.initialized") == "true") {
                    logger.info("Attempting PostgreSQL connection with Azure Managed Identity")
                    getAzureTokenForPostgres()
                } else {
                    logger.info("Using PostgreSQL password from environment variable")
                    System.getenv("POSTGRES_PASSWORD") ?: ""
                }
            } catch (e: Exception) {
                logger.warn("Failed to get Azure token for PostgreSQL: ${e.message}, falling back to password", e)
                System.getenv("POSTGRES_PASSWORD") ?: ""
            }

            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info("PostgreSQL HikariCP pool created successfully")
        }
    }

    private fun initMySQL(): DataSource {
        val mysqlHost = System.getenv("MYSQL_HOST") ?: "localhost"
        val mysqlPort = System.getenv("MYSQL_PORT") ?: "3306"
        val mysqlDb = System.getenv("MYSQL_DB") ?: "appdb"
        val mysqlUser = System.getenv("MYSQL_USER") ?: "root"

        logger.info("MySQL config: host=$mysqlHost, port=$mysqlPort, db=$mysqlDb, user=$mysqlUser")

        val config = HikariConfig().apply {
            driverClassName = "com.mysql.cj.jdbc.Driver"
            jdbcUrl = "jdbc:mysql://$mysqlHost:$mysqlPort/$mysqlDb?useSSL=true&requireSSL=true"
            username = mysqlUser
            password = System.getenv("MYSQL_PASSWORD") ?: ""
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info("MySQL HikariCP pool created successfully")
        }
    }

    private fun initSQLServer(): DataSource {
        val sqlHost = System.getenv("SQL_SERVER_HOST") ?: "localhost"
        val sqlPort = System.getenv("SQLSERVER_PORT")?.toInt() ?: 1433
        val sqlDb = System.getenv("SQLSERVER_DB") ?: "master"
        val sqlUser = System.getenv("SQLSERVER_USER") ?: "sa"

        logger.info("SQL Server config: host=$sqlHost, port=$sqlPort, db=$sqlDb, user=$sqlUser")

        val config = HikariConfig().apply {
            driverClassName = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
            jdbcUrl = "jdbc:sqlserver://$sqlHost:$sqlPort;database=$sqlDb;encrypt=true;trustServerCertificate=false"
            username = sqlUser
            password = System.getenv("SQLSERVER_PASSWORD") ?: ""
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info("SQL Server HikariCP pool created successfully")
        }
    }

    private fun initCosmosDB(): DataSource? {
        // CosmosDB typically uses SDK, not JDBC
        // This is a placeholder for future SDK integration
        logger.info("CosmosDB integration prepared for SDK setup")
        return null
    }

    private fun getAzureTokenForPostgres(): String {
        return try {
            val credential = DefaultAzureCredentialBuilder().build()
            val token = credential.getToken(
                TokenRequestContext()
                    .addScopes("https://ossrdbms-aad.database.windows.net/.default")
            ).block()

            token?.token ?: throw IllegalStateException("Azure token retrieval returned null")
        } catch (e: Exception) {
            logger.error("Failed to get Azure token", e)
            throw e
        }
    }
}
