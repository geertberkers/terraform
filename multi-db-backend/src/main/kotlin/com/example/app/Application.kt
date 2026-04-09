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
    // Initialize logger
    initializeLogger()

    embeddedServer(
        factory = Netty,
        port = System.getenv("PORT")?.toInt() ?: 8080,
        host = "0.0.0.0",
        module = Application::module
    ).start(wait = true)
}

fun Application.module() {
    getAppLogger().info("Starting application...")
    
    // Initialize Azure authentication
    initializeAzureAuth()
    
    // Initialize database connections
    initializeDatabases()
    
    // Install plugins
    configureSerialization()
    configureStatusPages()
    configureFreemarker()
    configureRouting()
    
    getAppLogger().info("Application started successfully")
}

private fun initializeLogger() {
    val storageAccount = System.getenv("AZURE_STORAGE_ACCOUNT")
    val fileShare = System.getenv("AZURE_FILE_SHARE") ?: "logs"
    val logDirectory = System.getenv("AZURE_LOG_DIRECTORY") ?: "app-logs"

    val logger = if (storageAccount != null && storageAccount.isNotEmpty()) {
        try {
            val azureLogger = AzureFileLogger(
                shareName = fileShare,
                directoryName = logDirectory,
                accountName = storageAccount
            )
            MultiLogger(listOf(azureLogger))
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
