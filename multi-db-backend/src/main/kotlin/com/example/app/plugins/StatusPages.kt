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
            logger.warn { "Not found: ${cause.message}" }
            call.respond(
                HttpStatusCode.NotFound,
                ErrorResponse(404, "Not Found", cause.message)
            )
        }
        exception<AppError.InvalidDatabase> { call, cause ->
            logger.warn { "Invalid database: ${cause.message}" }
            call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse(400, "Invalid Database", cause.message)
            )
        }
        exception<AppError.DatabaseError> { call, cause ->
            logger.error { "Database error: ${cause.message}" }
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(500, "Database Error", cause.message)
            )
        }
        exception<AppError.Unauthorized> { call, cause ->
            logger.warn { "Unauthorized: ${cause.message}" }
            call.respond(
                HttpStatusCode.Unauthorized,
                ErrorResponse(401, "Unauthorized", cause.message)
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
