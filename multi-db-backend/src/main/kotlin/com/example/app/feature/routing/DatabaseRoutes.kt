package com.example.app.feature.routing

import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import com.example.app.database.DatabaseService
import com.example.app.database.DatabaseType
import com.example.app.feature.dto.QueryRequest
import com.example.app.feature.dto.ExecuteUpdateRequest
import com.example.app.feature.dto.QueryResponse
import com.example.app.feature.dto.ExecuteUpdateResponse
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}
private val dbService = DatabaseService()

fun Route.databaseRoutes() {
    route("/api/database") {
        // List available databases
        get("/list") {
            val available = dbService.getAvailableDatabases()
            call.respond(mapOf("databases" to available))
        }

        // Execute query
        post("/query") {
            try {
                val request = call.receive<QueryRequest>()
                logger.info { "Executing query on ${request.database}" }

                val dbType = parseDatabase(request.database)
                val results: List<Map<String, String?>> = if (dbType == DatabaseType.CosmosDB) {
                    dbService.executeCosmosQuery(request.query).map { row ->
                        row.mapValues { (_, value) -> value?.toString() }
                    }
                } else {
                    dbService.executeQuery(dbType, request.query) { rs ->
                        val metadata = rs.metaData
                        val row = mutableMapOf<String, String?>()
                        for (i in 1..metadata.columnCount) {
                            row[metadata.getColumnName(i)] = rs.getObject(i)?.toString()
                        }
                        row
                    }
                }

                val columns = if (results.isNotEmpty()) {
                    results[0].keys.toList()
                } else {
                    emptyList()
                }

                call.respond(QueryResponse(
                    database = request.database,
                    rowCount = results.size,
                    columns = columns,
                    rows = results
                ))
            } catch (e: Exception) {
                call.respond(io.ktor.http.HttpStatusCode.BadRequest, mapOf("message" to (e.message ?: "Unknown error")))
            }
        }

        // Execute update/insert/delete
        post("/execute") {
            try {
                val request = call.receive<ExecuteUpdateRequest>()
                logger.info { "Executing update on ${request.database}" }

                val dbType = parseDatabase(request.database)
                val affectedRows = dbService.executeUpdate(dbType, request.sql, request.params.map { it as Any })

                call.respond(ExecuteUpdateResponse(
                    database = request.database,
                    affectedRows = affectedRows,
                    message = "Successfully executed. Affected rows: $affectedRows"
                ))
            } catch (e: Exception) {
                call.respond(io.ktor.http.HttpStatusCode.BadRequest, mapOf("message" to (e.message ?: "Unknown error")))
            }
        }

        // Example query to show some real data
        get("/example-data") {
            val results = mutableMapOf<String, DatabaseStatus>()

            // Try to get a basic check from Postgres
             try {
                val pgResult = dbService.executeQuery(DatabaseType.PostgreSQL, "SELECT 1 as is_alive, version() as db_version") { rs ->
                    DatabaseStatus(
                        isAlive = rs.getObject("is_alive")?.toString() == "1" || rs.getObject("is_alive")?.toString() == "true",
                        dbVersion = rs.getObject("db_version")?.toString(),
                        error = null
                    )
                }
                results["postgres"] = if (pgResult.isNotEmpty()) pgResult[0] else DatabaseStatus(false, null, "No data")
            } catch (e: Exception) {
                results["postgres"] = DatabaseStatus(false, null, "Error: ${e.message}")
            }

            // Try MySQL
            try {
                val mysqlResult = dbService.executeQuery(DatabaseType.MySQL, "SELECT 1 as is_alive, version() as db_version") { rs ->
                    DatabaseStatus(
                        isAlive = rs.getObject("is_alive")?.toString() == "1",
                        dbVersion = rs.getObject("db_version")?.toString(),
                        error = null
                    )
                }
                results["mysql"] = if (mysqlResult.isNotEmpty()) mysqlResult[0] else DatabaseStatus(false, null, "No data")
            } catch (e: Exception) {
                results["mysql"] = DatabaseStatus(false, null, "Error: ${e.message}")
            }

            // Try SQL Server
            try {
                val sqlResult = dbService.executeQuery(DatabaseType.SQLServer, "SELECT 1 as is_alive, @@VERSION as db_version") { rs ->
                    DatabaseStatus(
                        isAlive = rs.getObject("is_alive")?.toString() == "1",
                        dbVersion = rs.getObject("db_version")?.toString(),
                        error = null
                    )
                }
                results["sqlserver"] = if (sqlResult.isNotEmpty()) sqlResult[0] else DatabaseStatus(false, null, "No data")
            } catch (e: Exception) {
                results["sqlserver"] = DatabaseStatus(false, null, "Error: ${e.message}")
            }

            // Try CosmosDB
            try {
                val cosmosEndpoint = System.getenv("COSMOS_ENDPOINT")
                if (!cosmosEndpoint.isNullOrEmpty()) {
                    results["cosmosdb"] = DatabaseStatus(
                        isAlive = true,
                        dbVersion = "CosmosDB (endpoint: ${cosmosEndpoint.take(40)}...)",
                        error = null
                    )
                } else {
                    results["cosmosdb"] = DatabaseStatus(false, null, "COSMOS_ENDPOINT not configured")
                }
            } catch (e: Exception) {
                results["cosmosdb"] = DatabaseStatus(false, null, "Error: ${e.message}")
            }

            call.respond(ExampleDataResponse(results))
        }
    }
}

@kotlinx.serialization.Serializable
data class DatabaseStatus(
    val isAlive: Boolean,
    val dbVersion: String?,
    val error: String?
)

@kotlinx.serialization.Serializable
data class ExampleDataResponse(
    val example_data: Map<String, DatabaseStatus>
)

private fun parseDatabase(name: String): DatabaseType {
    return when (name.lowercase()) {
        "postgresql", "postgres", "pg" -> DatabaseType.PostgreSQL
        "mysql" -> DatabaseType.MySQL
        "sqlserver", "sql" -> DatabaseType.SQLServer
        "cosmosdb", "cosmos" -> DatabaseType.CosmosDB
        else -> throw IllegalArgumentException("Unknown database: $name")
    }
}
