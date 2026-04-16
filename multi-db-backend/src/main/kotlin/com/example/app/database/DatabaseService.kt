package com.example.app.database

import com.azure.cosmos.CosmosClientBuilder
import com.azure.cosmos.models.CosmosItemRequestOptions
import com.azure.cosmos.models.CosmosQueryRequestOptions
import com.azure.cosmos.models.PartitionKey
import com.example.app.common.AppError
import com.fasterxml.jackson.databind.JsonNode
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import mu.KotlinLogging
import javax.sql.DataSource

private val logger = KotlinLogging.logger {}

sealed class DatabaseType {
    object PostgreSQL : DatabaseType()
    object MySQL : DatabaseType()
    object SQLServer : DatabaseType()
    object CosmosDB : DatabaseType()
}

class DatabaseService {
    private val json = Json { ignoreUnknownKeys = true }

    private fun toJsonString(value: String): String {
        // Minimal JSON escaping for query log JSON.
        val escaped = value
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
        return "\"$escaped\""
    }

    fun <T> executeQuery(
        dbType: DatabaseType,
        query: String,
        mapper: (java.sql.ResultSet) -> T
    ): List<T> {
        logger.info("ACTION: executeQuery | DB: $dbType | QUERY: $query")

        if (dbType == DatabaseType.CosmosDB) {
            throw AppError.InvalidDatabase("Use executeCosmosQuery for CosmosDB operations")
        }

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

        if (dbType == DatabaseType.CosmosDB) {
            return executeCosmosUpdate(sql)
        }

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
        if (isCosmosConfigured()) available.add("CosmosDB")
        return available
    }

    fun executeCosmosQuery(query: String): List<Map<String, Any?>> {
        logger.info("ACTION: executeCosmosQuery | QUERY: $query")
        val container = getCosmosContainer()

        return try {
            val pagedResults = container
                .queryItems(
                    query,
                    CosmosQueryRequestOptions(),
                    JsonNode::class.java
                )

            val results = mutableListOf<Map<String, Any?>>()
            for (item in pagedResults) {
                results.add(itemToMap(item))
            }

            val resultStr = "Success | Retrieved ${results.size} document(s)"
            logger.info("RESULT: $resultStr")
            logQueryToFile("CosmosDB", query, resultStr)
            results
        } catch (e: Exception) {
            val resultStr = "Error | Cosmos query failed: ${e.message}"
            logger.error("RESULT: $resultStr", e)
            logQueryToFile("CosmosDB", query, resultStr)
            throw AppError.DatabaseError("Failed to execute Cosmos query: ${e.message}")
        }
    }

    private fun executeCosmosUpdate(rawPayload: String): Int {
        logger.info("ACTION: executeCosmosUpdate | PAYLOAD: $rawPayload")
        val container = getCosmosContainer()

        return try {
            val operationHint = rawPayload.trim().substringBefore("\n").lowercase()

            // Cosmos container lifecycle is managed by Terraform in this project.
            if (operationHint.contains("create table")) {
                logger.info("RESULT: Success | Cosmos create table skipped (container already managed)")
                logQueryToFile("CosmosDB", rawPayload, "Success | Create table skipped (managed by Terraform)")
                return 1
            }
            if (operationHint.contains("drop table")) {
                logger.info("RESULT: Success | Cosmos drop table skipped (container retained)")
                logQueryToFile("CosmosDB", rawPayload, "Success | Drop table skipped (managed by Terraform)")
                return 1
            }

            val payload = parsePayloadJson(rawPayload)

            if (operationHint.contains("delete")) {
                val id = (payload["id"] as? JsonPrimitive)?.content
                    ?: throw AppError.DatabaseError("Cosmos delete requires JSON body with 'id'")
                container.deleteItem(id, PartitionKey(id), CosmosItemRequestOptions())
                logger.info("RESULT: Success | Deleted document with id=$id")
                logQueryToFile("CosmosDB", rawPayload, "Success | Deleted document with id=$id")
                1
            } else {
                val document = jsonObjectToAnyMap(payload)
                if (document["id"] == null) {
                    throw AppError.DatabaseError("Cosmos upsert requires document field 'id'")
                }
                container.upsertItem(document)
                logger.info("RESULT: Success | Upserted document with id=${document["id"]}")
                logQueryToFile("CosmosDB", rawPayload, "Success | Upserted document with id=${document["id"]}")
                1
            }
        } catch (e: Exception) {
            val resultStr = "Error | Cosmos update failed: ${e.message}"
            logger.error("RESULT: $resultStr", e)
            logQueryToFile("CosmosDB", rawPayload, resultStr)
            throw AppError.DatabaseError("Failed to execute Cosmos update: ${e.message}")
        }
    }

    private fun getCosmosContainer() =
        try {
            val connectionString = System.getenv("COSMOS_CONNECTION_STRING")
            val endpoint = System.getenv("COSMOS_ENDPOINT")
                ?: extractConnectionStringValue(connectionString, "AccountEndpoint")
                ?: throw AppError.InvalidDatabase("COSMOS_ENDPOINT not configured")
            val key = extractConnectionStringValue(connectionString, "AccountKey")
                ?: throw AppError.InvalidDatabase("COSMOS_CONNECTION_STRING missing AccountKey")
            val databaseName = System.getenv("COSMOS_DATABASE") ?: "appdbcosmos"
            val containerName = System.getenv("COSMOS_CONTAINER") ?: "items"

            CosmosClientBuilder()
                .endpoint(endpoint)
                .key(key)
                .buildClient()
                .getDatabase(databaseName)
                .getContainer(containerName)
        } catch (e: AppError.InvalidDatabase) {
            throw e
        } catch (e: Exception) {
            throw AppError.DatabaseError("Unable to initialize Cosmos container: ${e.message}")
        }

    private fun parsePayloadJson(rawPayload: String): JsonObject {
        val start = rawPayload.indexOf('{')
        val end = rawPayload.lastIndexOf('}')
        if (start == -1 || end == -1 || end < start) {
            throw AppError.DatabaseError("Cosmos update requires a JSON object payload")
        }
        val jsonPart = rawPayload.substring(start, end + 1)
        val parsed = json.parseToJsonElement(jsonPart)
        return parsed as? JsonObject
            ?: throw AppError.DatabaseError("Cosmos payload must be a JSON object")
    }

    private fun extractConnectionStringValue(connectionString: String?, key: String): String? {
        if (connectionString.isNullOrBlank()) return null
        return connectionString
            .split(";")
            .mapNotNull {
                val idx = it.indexOf("=")
                if (idx <= 0) null else it.substring(0, idx) to it.substring(idx + 1)
            }
            .firstOrNull { it.first.equals(key, ignoreCase = true) }
            ?.second
            ?.takeIf { it.isNotBlank() }
    }

    private fun isCosmosConfigured(): Boolean {
        val endpoint = System.getenv("COSMOS_ENDPOINT")
        val connectionString = System.getenv("COSMOS_CONNECTION_STRING")
        return !endpoint.isNullOrBlank() && !connectionString.isNullOrBlank()
    }

    private fun jsonElementToAny(element: JsonElement): Any? =
        when (element) {
            is JsonNull -> null
            is JsonObject -> jsonObjectToAnyMap(element)
            is JsonArray -> element.map { jsonElementToAny(it) }
            is JsonPrimitive -> {
                if (element.isString) element.content else element.content
            }
        }

    private fun jsonObjectToAnyMap(obj: JsonObject): Map<String, Any?> =
        obj.entries.associate { (key, value) -> key to jsonElementToAny(value) }

    private fun itemToMap(node: JsonNode): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        val fields = node.fields()
        while (fields.hasNext()) {
            val entry = fields.next()
            result[entry.key] = jsonNodeToAny(entry.value)
        }
        return result
    }

    private fun jsonNodeToAny(node: JsonNode): Any? =
        when {
            node.isNull -> null
            node.isObject -> itemToMap(node)
            node.isArray -> node.map { jsonNodeToAny(it) }
            node.isBoolean -> node.booleanValue()
            node.isLong || node.isInt -> node.longValue()
            node.isDouble || node.isFloat || node.isBigDecimal -> node.doubleValue()
            else -> node.asText()
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
        val baseLogDirectory = System.getenv("AZURE_LOG_DIRECTORY") ?: "app-logs"
        
        if (accountKey.isNullOrEmpty() || accountName.isNullOrEmpty()) return

        val now = java.time.LocalDateTime.now()
        val year = now.year.toString()
        val month = now.monthValue.toString().padStart(2, '0')
        val day = now.dayOfMonth.toString().padStart(2, '0')
        val timePart = now.format(java.time.format.DateTimeFormatter.ofPattern("HHmmss_SSS"))
        val specificFileName = "${timePart}.json"
        
        val logJson = buildString {
            append("{")
            append("\"timestamp\":").append(toJsonString(now.toString())).append(',')
            append("\"database\":").append(toJsonString(dbName)).append(',')
            append("\"query\":").append(toJsonString(query)).append(',')
            append("\"result\":").append(toJsonString(resultStr))
            append("}\n")
        }
        val data = logJson.toByteArray(java.nio.charset.StandardCharsets.UTF_8)

        try {
            val shareClient = com.azure.storage.file.share.ShareClientBuilder()
                .endpoint("https://$accountName.file.core.windows.net")
                .credential(com.azure.storage.common.StorageSharedKeyCredential(accountName, accountKey))
                .shareName(shareName)
                .buildClient()

            val rootDirClient = shareClient.getDirectoryClient(baseLogDirectory)
            if (!rootDirClient.exists()) rootDirClient.create()

            val yearDirClient = rootDirClient.getSubdirectoryClient(year)
            if (!yearDirClient.exists()) yearDirClient.create()

            val monthDirClient = yearDirClient.getSubdirectoryClient(month)
            if (!monthDirClient.exists()) monthDirClient.create()

            val dayDirClient = monthDirClient.getSubdirectoryClient(day)
            if (!dayDirClient.exists()) dayDirClient.create()

            val fileClient = dayDirClient.getFileClient(specificFileName)
            fileClient.create(data.size.toLong())

            val options = com.azure.storage.file.share.models.ShareFileUploadRangeOptions(java.io.ByteArrayInputStream(data), data.size.toLong()).setOffset(0)
            fileClient.uploadRangeWithResponse(options, null, null)
        } catch (e: Exception) {
            logger.error("Failed to write query log to Azure: ${e.message}")
        }
    }
}
