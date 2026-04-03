package com.example.app.database

import com.azure.identity.DefaultAzureCredential
import com.microsoft.sqlserver.jdbc.SQLServerDataSource
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import mu.KotlinLogging
import javax.sql.DataSource

private val logger = KotlinLogging.logger {}

object DatabaseFactory {
    private var pgDataSource: DataSource? = null
    private var mysqlDataSource: DataSource? = null
    private var sqlServerDataSource: DataSource? = null
    private var cosmosDataSource: DataSource? = null

    fun init() {
        pgDataSource = initPostgres()
        mysqlDataSource = initMySQL()
        sqlServerDataSource = initSQLServer()
        cosmosDataSource = initCosmosDB()
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
                logger.warn { "Failed to get Azure token for PostgreSQL: ${e.message}" }
                System.getenv("POSTGRES_PASSWORD") ?: ""
            }
            
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info { "PostgreSQL connection pool initialized" }
        }
    }

    private fun initMySQL(): DataSource {
        val mysqlHost = System.getenv("MYSQL_HOST") ?: "localhost"
        val mysqlPort = System.getenv("MYSQL_PORT") ?: "3306"
        val mysqlDb = System.getenv("MYSQL_DB") ?: "appdb"
        val mysqlUser = System.getenv("MYSQL_USER") ?: "root"

        val config = HikariConfig().apply {
            jdbcUrl = "jdbc:mysql://$mysqlHost:$mysqlPort/$mysqlDb?useSSL=true&requireSSL=true"
            username = mysqlUser
            password = System.getenv("MYSQL_PASSWORD") ?: ""
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info { "MySQL connection pool initialized" }
        }
    }

    private fun initSQLServer(): DataSource {
        val sqlHost = System.getenv("SQLSERVER_HOST") ?: "localhost"
        val sqlPort = System.getenv("SQLSERVER_PORT")?.toInt() ?: 1433
        val sqlDb = System.getenv("SQLSERVER_DB") ?: "master"
        val sqlUser = System.getenv("SQLSERVER_USER") ?: "sa"
        val sqlPassword = System.getenv("SQLSERVER_PASSWORD") ?: ""

        val config = HikariConfig().apply {
            jdbcUrl = "jdbc:sqlserver://$sqlHost:$sqlPort;database=$sqlDb;encrypt=true;trustServerCertificate=false"
            username = sqlUser
            password = sqlPassword
            maximumPoolSize = 10
            minimumIdle = 2
        }

        return HikariDataSource(config).also {
            logger.info { "SQL Server connection pool initialized" }
        }
    }

    private fun initCosmosDB(): DataSource {
        // CosmosDB typically uses SDK, not JDBC
        // This is a placeholder for future SDK integration
        logger.info { "CosmosDB integration prepared for SDK setup" }
        return null
    }

    private fun getAzureTokenForPostgres(): String {
        return try {
            val credential = DefaultAzureCredential()
            val token = credential.getToken(
                com.azure.core.credential.TokenRequestContext()
                    .addScopes("https://ossrdbms-aad.database.windows.net/.default")
            )
            token.token
        } catch (e: Exception) {
            logger.error("Failed to get Azure token", e)
            throw e
        }
    }
}
