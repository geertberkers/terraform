package com.example.app.common

sealed class AppError(message: String) : Throwable(message) {
    data class NotFound(val resource: String, val id: Any) :
        AppError("$resource with id '$id' not found")

    data class InvalidDatabase(val detail: String) : AppError(detail)

    data class DatabaseError(val detail: String) : AppError(detail)

    data class Unauthorized(val detail: String) : AppError(detail)
}

@kotlinx.serialization.Serializable
data class ErrorResponse(
    val status: Int,
    val error: String,
    val message: String
)
