# Multi-stage build
FROM gradle:8.5-jdk17 as builder

WORKDIR /src

# Copy build files
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle gradle/
COPY src src/

# Build JAR
RUN gradle fatJar --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /src/build/libs/*.jar app.jar

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
