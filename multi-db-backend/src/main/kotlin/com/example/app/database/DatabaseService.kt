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
        val dataSource = getDataSource(dbType)
            ?: throw AppError.InvalidDatabase("Database type not configured: $dbType")

        return try {
            dataSource.connection.use { connection ->
                connection.createStatement().use { statement ->
                    val resultSet = statement.executeQuery(query)
                    val results = mutableListOf<T>()
                    while (resultSet.next()) {
                        results.add(mapper(resultSet))
                    }
                    results
                }
            }
        } catch (e: Exception) {
            logger.error("Query execution failed", e)
            throw AppError.DatabaseError("Failed to execute query: ${e.message}")
        }
    }

    fun executeUpdate(
        dbType: DatabaseType,
        sql: String,
        params: List<Any> = emptyList()
    ): Int {
        val dataSource = getDataSource(dbType)
            ?: throw AppError.InvalidDatabase("Database type not configured: $dbType")

        return try {
            dataSource.connection.use { connection ->
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
        } catch (e: Exception) {
            logger.error("Update execution failed", e)
            throw AppError.DatabaseError("Failed to execute update: ${e.message}")
        }
    }

    fun getAvailableDatabases(): List<String> {
        val available = mutableListOf<String>()
        if (DatabaseFactory.getPostgresDataSource() != null) available.add("PostgreSQL")
        if (DatabaseFactory.getMySQLDataSource() != null) available.add("MySQL")
        if (DatabaseFactory.getSQLServerDataSource() != null) available.add("SQLServer")
        if (DatabaseFactory.getCosmosDataSource() != null) available.add("CosmosDB")
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
}
