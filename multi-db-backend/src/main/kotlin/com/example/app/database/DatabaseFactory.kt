package com.example.app.database

import com.azure.core.credential.TokenRequestContext
import com.azure.identity.DefaultAzureCredentialBuilder
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import com.example.app.appLogger
import javax.sql.DataSource

object DatabaseFactory {
    private var pgDataSource: DataSource? = null
    private var mysqlDataSource: DataSource? = null
    private var sqlServerDataSource: DataSource? = null
    private var cosmosDataSource: DataSource? = null

    fun init() {
        try {
            pgDataSource = initPostgres()
            appLogger.info("PostgreSQL connection initialized")
        } catch (e: Exception) {
            appLogger.warn("Failed to initialize PostgreSQL: ${e.message}")
        }

        try {
            mysqlDataSource = initMySQL()
            appLogger.info("MySQL connection initialized")
        } catch (e: Exception) {
            appLogger.warn("Failed to initialize MySQL: ${e.message}")
        }

        try {
            sqlServerDataSource = initSQLServer()
            appLogger.info("SQL Server connection initialized")
        } catch (e: Exception) {
            appLogger.warn("Failed to initialize SQL Server: ${e.message}")
        }

        try {
            cosmosDataSource = initCosmosDB()
            appLogger.info("CosmosDB connection initialized")
        } catch (e: Exception) {
            appLogger.warn("Failed to initialize CosmosDB: ${e.message}")
        }
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

        val config = HikariConfig().apply {
            driverClassName = "org.postgresql.Driver"
            jdbcUrl = "jdbc:postgresql://$postgresHost:$postgresPort/$postgresDb"
            username = postgresUser
            
            // Try managed identity first, then environment variable
            password = try {
                if (System.getProperty("azure.credential.initialized") == "true") {
                    getAzureTokenForPostgres()
                } else {
                    System.getenv("POSTGRES_PASSWORD") ?: ""
                }
            } catch (e: Exception) {
                appLogger.warn("Failed to get Azure token for PostgreSQL: ${e.message}")
                System.getenv("POSTGRES_PASSWORD") ?: ""
            }
            
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            appLogger.info("PostgreSQL connection pool initialized")
        }
    }

    private fun initMySQL(): DataSource {
        val mysqlHost = System.getenv("MYSQL_HOST") ?: "localhost"
        val mysqlPort = System.getenv("MYSQL_PORT") ?: "3306"
        val mysqlDb = System.getenv("MYSQL_DB") ?: "appdb"
        val mysqlUser = System.getenv("MYSQL_USER") ?: "root"

        val config = HikariConfig().apply {
            driverClassName = "com.mysql.cj.jdbc.Driver"
            jdbcUrl = "jdbc:mysql://$mysqlHost:$mysqlPort/$mysqlDb?useSSL=true&requireSSL=true"
            username = mysqlUser
            password = System.getenv("MYSQL_PASSWORD") ?: ""
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            appLogger.info("MySQL connection pool initialized")
        }
    }

    private fun initSQLServer(): DataSource {
        val sqlHost = System.getenv("SQL_SERVER_HOST") ?: "localhost"
        val sqlPort = System.getenv("SQLSERVER_PORT")?.toInt() ?: 1433
        val sqlDb = System.getenv("SQLSERVER_DB") ?: "master"
        val sqlUser = System.getenv("SQLSERVER_USER") ?: "sa"
        val sqlPassword = System.getenv("SQLSERVER_PASSWORD") ?: ""

        val config = HikariConfig().apply {
            driverClassName = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
            jdbcUrl = "jdbc:sqlserver://$sqlHost:$sqlPort;database=$sqlDb;encrypt=true;trustServerCertificate=false"
            username = sqlUser
            password = sqlPassword
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            appLogger.info("SQL Server connection pool initialized")
        }
    }

    private fun initCosmosDB(): DataSource? {
        // CosmosDB typically uses SDK, not JDBC
        // This is a placeholder for future SDK integration
        appLogger.info("CosmosDB integration prepared for SDK setup")
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
            appLogger.error("Failed to get Azure token", e)
            throw e
        }
    }
}
