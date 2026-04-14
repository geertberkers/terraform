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
            val request = call.receive<QueryRequest>()
            logger.info { "Executing query on ${request.database}" }

            val dbType = parseDatabase(request.database)
            val results = dbService.executeQuery(dbType, request.query) { rs ->
                val metadata = rs.metaData
                val row = mutableMapOf<String, String?>()
                for (i in 1..metadata.columnCount) {
                    row[metadata.getColumnName(i)] = rs.getObject(i)?.toString()
                }
                row
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
        }

        // Execute update/insert/delete
        post("/execute") {
            val request = call.receive<ExecuteUpdateRequest>()
            logger.info { "Executing update on ${request.database}" }

            val dbType = parseDatabase(request.database)
            val affectedRows = dbService.executeUpdate(dbType, request.sql, request.params.map { it as Any })

            call.respond(ExecuteUpdateResponse(
                database = request.database,
                affectedRows = affectedRows,
                message = "Successfully executed. Affected rows: $affectedRows"
            ))
        }

        // Example query to show some real data
        get("/example-data") {
            val results = mutableMapOf<String, Any>()

            // Try to get a basic check from Postgres
             try {
                val pgResult = dbService.executeQuery(DatabaseType.PostgreSQL, "SELECT 1 as is_alive, version() as db_version") { rs ->
                    mapOf(
                        "is_alive" to rs.getObject("is_alive")?.toString(),
                        "db_version" to rs.getObject("db_version")?.toString()
                    )
                }
                results["postgres"] = if (pgResult.isNotEmpty()) pgResult[0] else "No data"
            } catch (e: Exception) {
                results["postgres"] = "Error connecting/querying: ${e.message}"
            }

            // Try MySQL
            try {
                val mysqlResult = dbService.executeQuery(DatabaseType.MySQL, "SELECT 1 as is_alive, version() as db_version") { rs ->
                    mapOf(
                        "is_alive" to rs.getObject("is_alive")?.toString(),
                        "db_version" to rs.getObject("db_version")?.toString()
                    )
                }
                results["mysql"] = if (mysqlResult.isNotEmpty()) mysqlResult[0] else "No data"
            } catch (e: Exception) {
                results["mysql"] = "Error connecting/querying: ${e.message}"
            }

            // Try SQL Server
            try {
                val sqlResult = dbService.executeQuery(DatabaseType.SQLServer, "SELECT 1 as is_alive, @@VERSION as db_version") { rs ->
                    mapOf(
                        "is_alive" to rs.getObject("is_alive")?.toString(),
                        "db_version" to rs.getObject("db_version")?.toString()
                    )
                }
                results["sqlserver"] = if (sqlResult.isNotEmpty()) sqlResult[0] else "No data"
            } catch (e: Exception) {
                results["sqlserver"] = "Error connecting/querying: ${e.message}"
            }

            call.respond(mapOf("example_data" to results))
        }
    }
}

private fun parseDatabase(name: String): DatabaseType {
    return when (name.lowercase()) {
        "postgresql", "postgres", "pg" -> DatabaseType.PostgreSQL
        "mysql" -> DatabaseType.MySQL
        "sqlserver", "sql" -> DatabaseType.SQLServer
        "cosmosdb", "cosmos" -> DatabaseType.CosmosDB
        else -> throw IllegalArgumentException("Unknown database: $name")
    }
}
