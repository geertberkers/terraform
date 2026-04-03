package com.example.app.feature.routing

import io.ktor.server.application.*
import io.ktor.server.freemarker.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import com.example.app.database.DatabaseService

private val dbService = DatabaseService()

fun Route.dashboardRoutes() {
    route("/dashboard") {
        get {
            val databases = dbService.getAvailableDatabases()
            call.respond(FreeMarkerContent("dashboard.ftl", mapOf(
                "databases" to databases,
                "title" to "Multi-Database Dashboard"
            )))
        }

        get("/api/info") {
            val databases = dbService.getAvailableDatabases()
            call.respond(mapOf(
                "databases" to databases,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }
}
