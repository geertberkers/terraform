package com.example.app.common

sealed class AppError(val message: String) {
    data class NotFound(val resource: String, val id: Any) :
        AppError("$resource with id '$id' not found")
    
    data class InvalidDatabase(override val message: String) : AppError(message)
    
    data class DatabaseError(override val message: String) : AppError(message)
    
    data class Unauthorized(override val message: String) : AppError(message)
}

@kotlinx.serialization.Serializable
data class ErrorResponse(
    val status: Int,
    val error: String,
    val message: String
)
