package com.example.app.feature.dto

import kotlinx.serialization.Serializable

@Serializable
data class DatabaseInfoResponse(
    val database: String,
    val tables: List<String>
)

@Serializable
data class QueryRequest(
    val database: String,
    val query: String
)

@Serializable
data class QueryResponse(
    val database: String,
    val rowCount: Int,
    val columns: List<String>,
    val rows: List<Map<String, String?>>
)

@Serializable
data class ExecuteUpdateRequest(
    val database: String,
    val sql: String,
    val params: List<String> = emptyList()
)

@Serializable
data class ExecuteUpdateResponse(
    val database: String,
    val affectedRows: Int,
    val message: String
)

@Serializable
data class DashboardData(
    val availableDatabases: List<String>,
    val databaseInfo: List<DatabaseInfoResponse>
)
