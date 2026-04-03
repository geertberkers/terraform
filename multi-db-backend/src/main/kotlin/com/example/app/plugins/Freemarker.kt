package com.example.app.plugins

import io.ktor.server.application.*
import io.ktor.server.freemarker.*
import freemarker.cache.ClassTemplateLoader

fun Application.configureFreemarker() {
    install(FreeMarker) {
        templateLoader = ClassTemplateLoader(this::class.java.classLoader, "templates")
    }
}
