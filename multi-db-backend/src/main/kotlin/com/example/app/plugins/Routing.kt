package com.example.app.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import com.example.app.feature.routing.databaseRoutes
import com.example.app.feature.routing.dashboardRoutes

fun Application.configureRouting() {
    routing {
        // Root endpoint
        get("/") {
            call.respondText("Multi-Database Backend - Kotlin Ktor", ContentType.Text.Html)
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
