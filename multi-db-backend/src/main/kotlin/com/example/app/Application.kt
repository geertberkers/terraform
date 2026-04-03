package com.example.app

import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import com.example.app.plugins.*
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

fun main() {
    embeddedServer(
        factory = Netty,
        port = System.getenv("PORT")?.toInt() ?: 8080,
        host = "0.0.0.0",
        module = Application::module
    ).start(wait = true)
}

fun Application.module() {
    logger.info { "Starting application..." }
    
    // Initialize Azure authentication
    initializeAzureAuth()
    
    // Initialize database connections
    initializeDatabases()
    
    // Install plugins
    configureSerialization()
    configureStatusPages()
    configureFreemarker()
    configureRouting()
    
    logger.info { "Application started successfully" }
}
