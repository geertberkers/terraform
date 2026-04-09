package com.example.app.logging

import com.azure.storage.file.share.ShareFileClientBuilder
import com.azure.storage.file.share.ShareDirectoryClient
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
    private val accountName: String
) : Logger {

    private val logger = KotlinLogging.logger {}
    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val timeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
    private val directoryClient: ShareDirectoryClient by lazy {
        try {
            val credential = DefaultAzureCredentialBuilder().build()
            val shareClient = ShareFileClientBuilder()
                .endpoint("https://$accountName.file.core.windows.net")
                .shareName(shareName)
                .credential(credential)
                .buildClient()
                .getRootDirectoryClient()

            shareClient.getSubdirectoryClient(directoryName).also {
                it.createIfNotExists()
            }
        } catch (e: Exception) {
            logger.error(e) { "Failed to initialize Azure File Storage directory client" }
            throw e
        }
    }

    override fun log(level: LogLevel, message: String, throwable: Throwable?) {
        val timestamp = LocalDateTime.now().format(timeFormatter)
        val logMessage = "[$timestamp] [$level] $message${throwable?.let { "\n${it.stackTraceToString()}" } ?: ""}\n"

        try {
            val fileName = "${LocalDateTime.now().format(dateFormatter)}.log"
            val fileClient = directoryClient.getFileClient(fileName)
            
            if (!fileClient.exists()) {
                fileClient.create(1024 * 100) // 100KB initial size
            }

            // Get current file size to append at the end
            val properties = fileClient.getProperties()
            val currentSize = properties.contentLength

            // Append to file
            fileClient.uploadRange(
                logMessage.byteInputStream(),
                logMessage.length.toLong(),
                currentSize
            )

        } catch (e: Exception) {
            logger.error(e) { "Failed to write to Azure File Storage" }
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
