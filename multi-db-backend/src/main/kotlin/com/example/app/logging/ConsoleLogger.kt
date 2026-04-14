package com.example.app.logging

import mu.KotlinLogging
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

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
