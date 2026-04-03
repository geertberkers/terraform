package com.example.app.plugins

import com.azure.identity.DefaultAzureCredentialBuilder
import com.example.app.database.DatabaseFactory
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

fun initializeAzureAuth() {
    try {
        val credential = DefaultAzureCredentialBuilder().build()
        logger.info { "Azure Managed Identity authentication initialized successfully" }
        // Store credential for later use if needed
        System.setProperty("azure.credential.initialized", "true")
    } catch (e: Exception) {
        logger.warn { "Azure Managed Identity not available, falling back to connection string auth: ${e.message}" }
    }
}

fun initializeDatabases() {
    try {
        DatabaseFactory.init()
        logger.info { "Database connections initialized" }
    } catch (e: Exception) {
        logger.error("Failed to initialize databases", e)
        throw e
    }
}
