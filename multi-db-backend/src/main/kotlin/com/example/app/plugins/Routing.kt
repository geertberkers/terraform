package com.example.app.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import com.example.app.feature.routing.databaseRoutes
import com.example.app.feature.routing.dashboardRoutes

fun Application.configureRouting() {
    routing {
        // Root endpoint - show deployment info
        get("/") {
            val dockerImage = System.getenv("DOCKER_IMAGE") ?: "unknown"
            val dockerTag = System.getenv("DOCKER_TAG") ?: "unknown"
            val timestamp = java.time.LocalDateTime.now()
            
            val html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Multi-Database Backend</title>
                    <style>
                        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }
                        h1 { color: #333; }
                        .info { margin: 15px 0; padding: 10px; background: #f0f0f0; border-left: 4px solid #007bff; }
                        .label { font-weight: bold; color: #555; }
                        .value { color: #007bff; font-family: monospace; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h1>🚀 Multi-Database Backend</h1>
                        <div class="info">
                            <div class="label">Docker Image:</div>
                            <div class="value">$dockerImage</div>
                        </div>
                        <div class="info">
                            <div class="label">Docker Tag:</div>
                            <div class="value">$dockerTag</div>
                        </div>
                        <div class="info">
                            <div class="label">App Version:</div>
                            <div class="value">${System.getenv("APP_VERSION_NAME") ?: "unknown"} (Build: ${System.getenv("APP_VERSION_CODE") ?: "0"})</div>
                        </div>
                        <div class="label">App Build Code:</div>
                            <div class="value">${System.getenv("APP_VERSION_CODE") ?: "0"}
                        </div>
                        <div class="info">
                            <div class="label">Kotlin Version:</div>
                            <div class="value">${KotlinVersion.CURRENT}</div>
                        </div>
                        <div class="info">
                            <div class="label">Started at:</div>
                            <div class="value">$timestamp</div>
                        </div>
                        <hr>
                        <p><a href="/health">Health Check</a> | <a href="/dashboard">Dashboard</a></p>
                    </div>
                </body>
                </html>
            """.trimIndent()
            
            call.respondText(html, ContentType.Text.Html)
        }

        // Health check
        get("/health") {
            call.respond(mapOf("status" to "healthy"))
        }

        // Dashboard HTML
        dashboardRoutes()

        // Database API routes
        databaseRoutes()
    }
}
