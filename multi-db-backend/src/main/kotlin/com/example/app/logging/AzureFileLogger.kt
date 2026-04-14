package com.example.app.logging

import com.azure.storage.file.share.ShareClientBuilder
import com.azure.storage.common.StorageSharedKeyCredential
import com.azure.storage.file.share.models.ShareFileUploadRangeOptions
import java.io.ByteArrayInputStream
import java.nio.charset.StandardCharsets
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import mu.KotlinLogging

/**
 * Azure File Logger - Implementation using storage account access key
 * Optimized with metadata-based offset tracking to prevent null character corruption.
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
                // We use println here to avoid infinite recursion if consoleLogger also fails
                System.err.println("Fatal: Failed to log to Azure Storage: ${e.message}")
            }
        }
    }

    private fun logToAzureStorage(level: LogLevel, message: String, throwable: Throwable?) {
        val timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        val logLine = "[$timestamp] [$level] $message${throwable?.let { "\n${it.stackTraceToString()}" } ?: ""}\n"
        val data = logLine.toByteArray(StandardCharsets.UTF_8)

        try {
            val shareClient = ShareClientBuilder()
                .endpoint("https://$accountName.file.core.windows.net")
                .credential(StorageSharedKeyCredential(accountName, accountKey))
                .shareName(shareName)
                .buildClient()

            val dirClient = shareClient.getDirectoryClient(directoryName)
            if (!dirClient.exists()) {
                dirClient.create()
            }

            val fileClient = dirClient.getFileClient("app.log")
            
            // 1. Determine the actual data offset using metadata
            var currentOffset: Long = 0
            if (!fileClient.exists()) {
                fileClient.create(data.size.toLong())
            } else {
                val properties = fileClient.getProperties()
                val metadata = properties.getMetadata()
                
                currentOffset = metadata["current_offset"]?.toLongOrNull() ?: 0L
                
                // 2. Simple rotation: if log gets too big (> 2MB), start over
                if (currentOffset + data.size > 2 * 1024 * 1024) {
                    fileClient.delete()
                    fileClient.create(data.size.toLong())
                    currentOffset = 0
                } else {
                    // 3. Ensure file is large enough for the new data
                    val currentFileSize = properties.getContentLength()
                    if (currentOffset + data.size > currentFileSize) {
                        fileClient.setPropertiesWithResponse(currentOffset + data.size, null, null, null, null, null)
                    }
                }
            }

            // 4. Perform the upload at the tracked offset
            val options = ShareFileUploadRangeOptions(ByteArrayInputStream(data), data.size.toLong())
                .setOffset(currentOffset)
            
            fileClient.uploadRangeWithResponse(options, null, null)

            // 5. Update the metadata to track the new end-of-file
            val newMetadata = HashMap<String, String>()
            newMetadata["current_offset"] = (currentOffset + data.size).toString()
            fileClient.setMetadata(newMetadata)
            
        } catch (e: Exception) {
            System.err.println("Azure File Share write failed: ${e.message}")
        }
    }

    override fun info(message: String) = log(LogLevel.INFO, message)
    override fun warn(message: String, throwable: Throwable?) = log(LogLevel.WARN, message, throwable)
    override fun error(message: String, throwable: Throwable?) = log(LogLevel.ERROR, message, throwable)
}
