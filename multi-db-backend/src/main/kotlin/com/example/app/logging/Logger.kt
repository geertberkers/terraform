package com.example.app.logging

import mu.KotlinLogging
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

interface Logger {
    fun log(level: LogLevel, message: String, throwable: Throwable? = null)
    fun info(message: String)
    fun warn(message: String, throwable: Throwable? = null)
    fun error(message: String, throwable: Throwable? = null)
}

enum class LogLevel {
    INFO, WARN, ERROR
}

class ConsoleLogger : Logger {
    private val logger = KotlinLogging.logger {}
    private val timeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")

    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        val timestamp = LocalDateTime.now().format(timeFormatter)
        val logMessage = "[$timestamp] [$level] $message${throwable?.let { "\n${it.stackTraceToString()}" } ?: ""}"

        when (level) {
            LogLevel.INFO -> logger.info { logMessage }
            LogLevel.WARN -> logger.warn(throwable) { logMessage }
            LogLevel.ERROR -> logger.error(throwable) { logMessage }
        }
    }

    override fun info(message: String) = log(LogLevel.INFO, message)
    override fun warn(message: String, throwable: Throwable?) = log(LogLevel.WARN, message, throwable)
    override fun error(message: String, throwable: Throwable?) = log(LogLevel.ERROR, message, throwable)
}

/**
 * Azure File Logger - Implementation using storage account access key
 * This avoids the need for managed identity role assignments in CI/CD
 */
class AzureFileLogger(
    private val shareName: String,
    private val directoryName: String,
    private val accountName: String,
    private val accountKey: String? = null
) : Logger {
    private val consoleLogger = ConsoleLogger()
    private val logger = KotlinLogging.logger {}

    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        // Always log to console first
        consoleLogger.log(level, message, throwable)

        // Try to log to Azure Storage if configured
        if (accountKey != null && accountKey.isNotEmpty()) {
            try {
                logToAzureStorage(level, message, throwable)
            } catch (e: Exception) {
                logger.error(e) { "Failed to log to Azure Storage: ${e.message}" }
            }
        }
    }

    private fun logToAzureStorage(level: LogLevel, message: String, throwable: Throwable?) {
        // TODO: Implement Azure Storage File Share logging with access key
        // For now, just log that we'd write to Azure
        logger.info { "Would log to Azure Storage: [$level] $message" }
    }

    override fun info(message: String) = log(LogLevel.INFO, message)
    override fun warn(message: String, throwable: Throwable?) = log(LogLevel.WARN, message, throwable)
    override fun error(message: String, throwable: Throwable?) = log(LogLevel.ERROR, message, throwable)
}

class MultiLogger(private val loggers: List<Logger>) : Logger {
    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        loggers.forEach { it.log(level, message, throwable) }
    }

    override fun info(message: String) = loggers.forEach { it.info(message) }
    override fun warn(message: String, throwable: Throwable?) = loggers.forEach { it.warn(message, throwable) }
    override fun error(message: String, throwable: Throwable?) = loggers.forEach { it.error(message, throwable) }
}
