package com.example.app.database

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import java.sql.DriverManager
import java.sql.Connection
import java.util.Properties

class DatabaseConnectionTest {

    @Test
    fun testPostgresConnection() {
        val host = System.getenv("POSTGRES_HOST") ?: "localhost"
        val port = System.getenv("POSTGRES_PORT") ?: "5432"
        val db = System.getenv("POSTGRES_DB") ?: "appdb"
        val user = System.getenv("POSTGRES_USER") ?: "postgres"
        val pass = System.getenv("POSTGRES_PASSWORD")

        if (pass == null) {
            println("Skipping PostgreSQL test: POSTGRES_PASSWORD not set")
            return
        }

        val url = "jdbc:postgresql://$host:$port/$db"
        println("Testing PostgreSQL connection to $url...")

        try {
            DriverManager.getConnection(url, user, pass).use { conn ->
                assertNotNull(conn, "Connection should not be null")
                println("✓ PostgreSQL connection successful!")
            }
        } catch (e: Exception) {
            fail("PostgreSQL connection failed: ${e.message}")
        }
    }

    @Test
    fun testMySQLConnection() {
        val host = System.getenv("MYSQL_HOST") ?: "localhost"
        val port = System.getenv("MYSQL_PORT") ?: "3306"
        val db = System.getenv("MYSQL_DB") ?: "appdb"
        val user = System.getenv("MYSQL_USER") ?: "root"
        val pass = System.getenv("MYSQL_PASSWORD")

        if (pass == null) {
            println("Skipping MySQL test: MYSQL_PASSWORD not set")
            return
        }

        val url = "jdbc:mysql://$host:$port/$db?useSSL=false"
        println("Testing MySQL connection to $url...")

        try {
            DriverManager.getConnection(url, user, pass).use { conn ->
                assertNotNull(conn, "Connection should not be null")
                println("✓ MySQL connection successful!")
            }
        } catch (e: Exception) {
            fail("MySQL connection failed: ${e.message}")
        }
    }

    @Test
    fun testSQLServerConnection() {
        val host = System.getenv("SQL_SERVER_HOST") ?: "localhost"
        val port = System.getenv("SQLSERVER_PORT") ?: "1433"
        val db = System.getenv("SQLSERVER_DB") ?: "master"
        val user = System.getenv("SQLSERVER_USER") ?: "sa"
        val pass = System.getenv("SQLSERVER_PASSWORD")

        if (pass == null) {
            println("Skipping SQL Server test: SQLSERVER_PASSWORD not set")
            return
        }

        val url = "jdbc:sqlserver://$host:$port;databaseName=$db;encrypt=true;trustServerCertificate=true"
        println("Testing SQL Server connection to $url...")

        try {
            DriverManager.getConnection(url, user, pass).use { conn ->
                assertNotNull(conn, "Connection should not be null")
                println("✓ SQL Server connection successful!")
            }
        } catch (e: Exception) {
            fail("SQL Server connection failed: ${e.message}")
        }
    }
}
