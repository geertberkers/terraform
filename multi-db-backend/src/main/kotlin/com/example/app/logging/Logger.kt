package com.example.app.logging

import com.azure.storage.file.share.ShareFileClient
import com.azure.storage.file.share.ShareFileClientBuilder
import com.azure.identity.DefaultAzureCredentialBuilder
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

class AzureFileLogger(
    private val shareName: String,
    private val directoryName: String,
    private val accountName: String,
    private val accountKey: String? = null // Use managed identity if null
) : Logger {

    private val logger = KotlinLogging.logger {}
    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val timeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")

    private val shareClient by lazy {
        val credential = if (accountKey != null) {
            // Use account key if provided
            com.azure.storage.common.StorageSharedKeyCredential(accountName, accountKey)
        } else {
            // Use managed identity
            DefaultAzureCredentialBuilder().build()
        }

        ShareFileClientBuilder()
            .endpoint("https://$accountName.file.core.windows.net")
            .shareName(shareName)
            .credential(credential)
            .buildClient()
    }

    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        val timestamp = LocalDateTime.now().format(timeFormatter)
        val logMessage = "[$timestamp] [$level] $message${throwable?.let { "\n${it.stackTraceToString()}" } ?: ""}\n"

        try {
            val fileName = "${LocalDateTime.now().format(dateFormatter)}.log"
            val directoryClient = shareClient.getDirectoryClient(directoryName)
            val fileClient = directoryClient.getFileClient(fileName)

            // Create directory if it doesn't exist
            directoryClient.createIfNotExists()

            // Append to file
            fileClient.appendWithResponse(
                logMessage.toByteArray(Charsets.UTF_8),
                0,
                logMessage.length.toLong(),
                null,
                null,
                null
            )

        } catch (e: Exception) {
            // Fallback to console logging if Azure storage fails
            logger.error(e) { "Failed to write to Azure File Storage: $logMessage" }
        }

        // Also log to console
        when (level) {
            LogLevel.INFO -> logger.info { message }
            LogLevel.WARN -> logger.warn(throwable) { message }
            LogLevel.ERROR -> logger.error(throwable) { message }
        }
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
