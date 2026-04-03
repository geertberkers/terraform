package com.example.app.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.response.*
import com.example.app.common.AppError
import com.example.app.common.ErrorResponse
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<AppError.NotFound> { call, cause ->
            val message = cause.message ?: "Resource not found"
            logger.warn { "Not found: $message" }
            call.respond(
                HttpStatusCode.NotFound,
                ErrorResponse(404, "Not Found", message)
            )
        }
        exception<AppError.InvalidDatabase> { call, cause ->
            val message = cause.message ?: "Invalid database"
            logger.warn { "Invalid database: $message" }
            call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse(400, "Invalid Database", message)
            )
        }
        exception<AppError.DatabaseError> { call, cause ->
            val message = cause.message ?: "Database error"
            logger.error { "Database error: $message" }
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(500, "Database Error", message)
            )
        }
        exception<AppError.Unauthorized> { call, cause ->
            val message = cause.message ?: "Unauthorized"
            logger.warn { "Unauthorized: $message" }
            call.respond(
                HttpStatusCode.Unauthorized,
                ErrorResponse(401, "Unauthorized", message)
            )
        }
        exception<Throwable> { call, cause ->
            logger.error("Unhandled exception", cause)
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(500, "Internal Server Error", "An unexpected error occurred")
            )
        }
    }
}
