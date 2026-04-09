package com.example.app

import com.example.app.logging.Logger

// Global logger accessor - MUST be at top level for clean imports
internal lateinit var _appLogger: Logger

fun getAppLogger(): Logger = _appLogger

fun setAppLogger(logger: Logger) {
    _appLogger = logger
}
