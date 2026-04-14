package com.example.app.database

import com.example.app.common.AppError
import mu.KotlinLogging
import java.sql.Connection
import javax.sql.DataSource

private val logger = KotlinLogging.logger {}

sealed class DatabaseType {
    object PostgreSQL : DatabaseType()
    object MySQL : DatabaseType()
    object SQLServer : DatabaseType()
    object CosmosDB : DatabaseType()
}

class DatabaseService {
    fun <T> executeQuery(
        dbType: DatabaseType,
        query: String,
        mapper: (java.sql.ResultSet) -> T
    ): List<T> {
        logger.info("ACTION: executeQuery | DB: $dbType | QUERY: $query")
        
        val dataSource = getDataSource(dbType)
            ?: throw AppError.InvalidDatabase("Database type not configured: $dbType").also {
                logger.warn("RESULT: Failed - ${it.message}")
            }

        return try {
            dataSource.connection.use { connection ->
                connection.createStatement().use { statement ->
                    val resultSet = statement.executeQuery(query)
                    val results = mutableListOf<T>()
                    while (resultSet.next()) {
                        results.add(mapper(resultSet))
                    }
                    val resultStr = "Success | Retrieved ${results.size} row(s)"
                    logger.info("RESULT: $resultStr")
                    logQueryToFile(dbType.javaClass.simpleName, query, resultStr)
                    results
                }
            }
        } catch (e: Exception) {
            val resultStr = "Error | Query execution failed: ${e.message}"
            logger.error("RESULT: $resultStr", e)
            logQueryToFile(dbType.javaClass.simpleName, query, resultStr)
            throw AppError.DatabaseError("Failed to execute query: ${e.message}")
        }
    }

    fun executeUpdate(
        dbType: DatabaseType,
        sql: String,
        params: List<Any> = emptyList()
    ): Int {
        logger.info("ACTION: executeUpdate | DB: $dbType | SQL: $sql | PARAMS: $params")
        
        val dataSource = getDataSource(dbType)
            ?: throw AppError.InvalidDatabase("Database type not configured: $dbType").also {
                logger.warn("RESULT: Failed - ${it.message}")
            }

        return try {
            val affectedRows = dataSource.connection.use { connection ->
                connection.prepareStatement(sql).use { statement ->
                    params.forEachIndexed { index, param ->
                        when (param) {
                            is String -> statement.setString(index + 1, param)
                            is Int -> statement.setInt(index + 1, param)
                            is Long -> statement.setLong(index + 1, param)
                            is Double -> statement.setDouble(index + 1, param)
                            is Boolean -> statement.setBoolean(index + 1, param)
                            else -> statement.setObject(index + 1, param)
                        }
                    }
                    statement.executeUpdate()
                }
            }
            val resultStr = "Success | Affected $affectedRows row(s)"
            logger.info("RESULT: $resultStr")
            logQueryToFile(dbType.javaClass.simpleName, sql, resultStr)
            affectedRows
        } catch (e: Exception) {
            val resultStr = "Error | Update execution failed: ${e.message}"
            logger.error("RESULT: $resultStr", e)
            logQueryToFile(dbType.javaClass.simpleName, sql, resultStr)
            throw AppError.DatabaseError("Failed to execute update: ${e.message}")
        }
    }

    fun getAvailableDatabases(): List<String> {
        val available = mutableListOf<String>()
        if (DatabaseFactory.getPostgresDataSource() != null) available.add("PostgreSQL")
        if (DatabaseFactory.getMySQLDataSource() != null) available.add("MySQL")
        if (DatabaseFactory.getSQLServerDataSource() != null) available.add("SQLServer")
        val cosmosEndpoint = System.getenv("COSMOS_ENDPOINT")
        if (!cosmosEndpoint.isNullOrEmpty()) available.add("CosmosDB")
        return available
    }

    private fun getDataSource(dbType: DatabaseType): DataSource? {
        return when (dbType) {
            DatabaseType.PostgreSQL -> DatabaseFactory.getPostgresDataSource()
            DatabaseType.MySQL -> DatabaseFactory.getMySQLDataSource()
            DatabaseType.SQLServer -> DatabaseFactory.getSQLServerDataSource()
            DatabaseType.CosmosDB -> DatabaseFactory.getCosmosDataSource()
        }
    }

    private fun logQueryToFile(dbName: String, query: String, resultStr: String) {
        val accountName = System.getenv("AZURE_STORAGE_ACCOUNT")
        val accountKey = System.getenv("AZURE_STORAGE_KEY")
        val shareName = System.getenv("AZURE_FILE_SHARE") ?: "logs"
        val directoryName = System.getenv("AZURE_LOG_DIRECTORY") ?: "app-logs"
        
        if (accountKey.isNullOrEmpty() || accountName.isNullOrEmpty()) return

        val timestampSafe = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS"))
        val specificFileName = "query_${dbName}_${timestampSafe}.log"
        
        val logLine = "Timestamp: ${java.time.LocalDateTime.now()}\nDatabase: $dbName\nQuery: $query\nResult:\n$resultStr\n"
        val data = logLine.toByteArray(java.nio.charset.StandardCharsets.UTF_8)

        try {
            val shareClient = com.azure.storage.file.share.ShareClientBuilder()
                .endpoint("https://$accountName.file.core.windows.net")
                .credential(com.azure.storage.common.StorageSharedKeyCredential(accountName, accountKey))
                .shareName(shareName)
                .buildClient()

            val rootDirClient = shareClient.getDirectoryClient(directoryName)
            if (!rootDirClient.exists()) rootDirClient.create()
            
            val queriesDirClient = rootDirClient.getSubdirectoryClient("queries")
            if (!queriesDirClient.exists()) queriesDirClient.create()
            
            val dbDirClient = queriesDirClient.getSubdirectoryClient(dbName.lowercase())
            if (!dbDirClient.exists()) dbDirClient.create()

            val fileClient = dbDirClient.getFileClient(specificFileName)
            fileClient.create(data.size.toLong())

            val options = com.azure.storage.file.share.models.ShareFileUploadRangeOptions(java.io.ByteArrayInputStream(data), data.size.toLong()).setOffset(0)
            fileClient.uploadRangeWithResponse(options, null, null)
        } catch (e: Exception) {
            logger.error("Failed to write query log to Azure: ${e.message}")
        }
    }
}
