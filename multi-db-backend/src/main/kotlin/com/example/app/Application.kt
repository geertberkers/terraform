import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import com.example.app.plugins.*
import com.example.app.logging.AzureFileLogger
import com.example.app.logging.MultiLogger
import com.example.app.logging.Logger
import mu.KotlinLogging

private val consoleLogger = KotlinLogging.logger {}
private lateinit var appLogger: Logger

// Export logger for other modules
fun getAppLogger(): Logger = appLogger

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
    appLogger.info("Starting application...")
    
    // Initialize Azure authentication
    initializeAzureAuth()
    
    // Initialize database connections
    initializeDatabases()
    
    // Install plugins
    configureSerialization()
    configureStatusPages()
    configureFreemarker()
    configureRouting()
    
    appLogger.info("Application started successfully")
}

private fun initializeLogger() {
    val storageAccount = System.getenv("AZURE_STORAGE_ACCOUNT")
    val fileShare = System.getenv("AZURE_FILE_SHARE") ?: "logs"
    val logDirectory = System.getenv("AZURE_LOG_DIRECTORY") ?: "app-logs"

    if (storageAccount != null) {
        try {
            val azureLogger = AzureFileLogger(
                shareName = fileShare,
                directoryName = logDirectory,
                accountName = storageAccount
            )
            appLogger = MultiLogger(listOf(azureLogger))
            consoleLogger.info { "Azure File Logger initialized" }
        } catch (e: Exception) {
            consoleLogger.error(e) { "Failed to initialize Azure logger, using console only" }
            appLogger = object : Logger {
                override fun log(level: com.example.app.logging.LogLevel, message: String, throwable: Throwable?) {
                    when (level) {
                        com.example.app.logging.LogLevel.INFO -> consoleLogger.info { message }
                        com.example.app.logging.LogLevel.WARN -> consoleLogger.warn(throwable) { message }
                        com.example.app.logging.LogLevel.ERROR -> consoleLogger.error(throwable) { message }
                    }
                }
                override fun info(message: String) = consoleLogger.info { message }
                override fun warn(message: String, throwable: Throwable?) = consoleLogger.warn(throwable) { message }
                override fun error(message: String, throwable: Throwable?) = consoleLogger.error(throwable) { message }
            }
        }
    } else {
        consoleLogger.warn { "AZURE_STORAGE_ACCOUNT not set, using console logging only" }
        appLogger = object : Logger {
            override fun log(level: com.example.app.logging.LogLevel, message: String, throwable: Throwable?) {
                when (level) {
                    com.example.app.logging.LogLevel.INFO -> consoleLogger.info { message }
                    com.example.app.logging.LogLevel.WARN -> consoleLogger.warn(throwable) { message }
                    com.example.app.logging.LogLevel.ERROR -> consoleLogger.error(throwable) { message }
                }
            }
            override fun info(message: String) = consoleLogger.info { message }
            override fun warn(message: String, throwable: Throwable?) = consoleLogger.warn(throwable) { message }
            override fun error(message: String, throwable: Throwable?) = consoleLogger.error(throwable) { message }
        }
    }
}
