package com.example.app

import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import com.example.app.plugins.*
import com.example.app.logging.AzureFileLogger
import com.example.app.logging.MultiLogger
import com.example.app.logging.Logger
import com.example.app.logging.ConsoleLogger
import com.example.app.getAppLogger
import com.example.app.setAppLogger

private val consoleLogger = ConsoleLogger()

fun main() {
    println("Starting Kotlin application...")

    // Initialize logger first - this is critical
    try {
        initializeLogger()
        getAppLogger().info("Logger initialized successfully")
    } catch (e: Exception) {
        consoleLogger.error("CRITICAL: Failed to initialize logger, using console fallback", e)
        setAppLogger(consoleLogger)
    }

    getAppLogger().info("Starting embedded server on port ${System.getenv("PORT")?.toInt() ?: 8080}")

    embeddedServer(
        factory = Netty,
        port = System.getenv("PORT")?.toInt() ?: 8080,
        host = "0.0.0.0",
        module = Application::module
    ).start(wait = true)
}

fun Application.module() {
    val logger = getAppLogger()
    logger.info("=== APPLICATION STARTUP BEGIN ===")
    logger.info("Environment: PORT=${System.getenv("PORT")}, HOST=0.0.0.0")
    logger.info("Docker Image: ${System.getenv("DOCKER_IMAGE") ?: "not set"}")
    logger.info("Docker Tag: ${System.getenv("DOCKER_TAG") ?: "not set"}")

    // Initialize Azure authentication - non-critical
    try {
        logger.info("Initializing Azure authentication...")
        initializeAzureAuth()
        logger.info("✓ Azure authentication initialized successfully")
    } catch (e: Exception) {
        logger.warn("✗ Azure authentication failed, continuing without it", e)
    }

    // Initialize database connections - non-critical for startup
    try {
        logger.info("Initializing database connections...")
        initializeDatabases()
        logger.info("✓ Database connections initialized successfully")
    } catch (e: Exception) {
        logger.error("✗ Database initialization failed, application will continue without database connectivity", e)
    }

    // Install plugins - these are critical
    try {
        logger.info("Installing Ktor plugins...")
        configureSerialization()
        logger.info("✓ Serialization plugin configured")

        configureStatusPages()
        logger.info("✓ Status pages plugin configured")

        configureFreemarker()
        logger.info("✓ Freemarker plugin configured")

        configureRouting()
        logger.info("✓ Routing plugin configured")

        logger.info("✓ All plugins installed successfully")
    } catch (e: Exception) {
        logger.error("CRITICAL: Failed to install plugins, application may not function properly", e)
        throw e // This is critical, re-throw
    }

    logger.info("=== APPLICATION STARTUP COMPLETE ===")
    logger.info("Server is ready to accept connections")
}

private fun initializeLogger() {
    val storageAccount = System.getenv("AZURE_STORAGE_ACCOUNT")
    val fileShare = System.getenv("AZURE_FILE_SHARE") ?: "logs"
    val logDirectory = System.getenv("AZURE_LOG_DIRECTORY") ?: "app-logs"
    val storageKey = System.getenv("AZURE_STORAGE_KEY")

    val logger = if (storageAccount != null && storageAccount.isNotEmpty()) {
        try {
            val azureLogger = AzureFileLogger(
                shareName = fileShare,
                directoryName = logDirectory,
                accountName = storageAccount,
                accountKey = storageKey
            )
            MultiLogger(listOf(ConsoleLogger(), azureLogger))
        } catch (e: Exception) {
            consoleLogger.warn("Failed to initialize Azure logger: ${e.message}, using console only", e)
            ConsoleLogger()
        }
    } else {
        consoleLogger.warn("AZURE_STORAGE_ACCOUNT not set, using console logging only")
        ConsoleLogger()
    }

    setAppLogger(logger)
}
