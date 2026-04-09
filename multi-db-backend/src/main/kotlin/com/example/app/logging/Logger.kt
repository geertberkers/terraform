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

class AzureFileLogger(
    private val shareName: String,
    private val directoryName: String,
    private val accountName: String,
    private val accountKey: String? = null // Use managed identity if null
) : Logger {

    private val consoleLogger = ConsoleLogger()

    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        // For now, just delegate to console logging
        // TODO: Implement proper Azure File Storage logging
        consoleLogger.log(level, message, throwable)
    }

    override fun info(message: String) = consoleLogger.info(message)
    override fun warn(message: String, throwable: Throwable?) = consoleLogger.warn(message, throwable)
    override fun error(message: String, throwable: Throwable?) = consoleLogger.error(message, throwable)
}

class MultiLogger(private val loggers: List<Logger>) : Logger {
    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        loggers.forEach { it.log(level, message, throwable) }
    }

    override fun info(message: String) = loggers.forEach { it.info(message) }
    override fun warn(message: String, throwable: Throwable?) = loggers.forEach { it.warn(message, throwable) }
    override fun error(message: String, throwable: Throwable?) = loggers.forEach { it.error(message, throwable) }
}
