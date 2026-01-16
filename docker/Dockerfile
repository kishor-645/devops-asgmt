# Build Stage
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY app/sample-spring-boot-app/pom.xml .
COPY app/sample-spring-boot-app/src ./src
RUN mvn clean package -DskipTests

# Run Stage
FROM eclipse-temurin:17-jre-jammy
# Security Enhancement: Create a non-root user
RUN groupadd -g 1000 appuser && useradd -u 1000 -g appuser -m appuser
WORKDIR /app

# Optimization: Only copy the final jar
COPY --from=build --chown=appuser:appuser /app/target/*.jar app.jar

# Switch to the non-root user
USER appuser

EXPOSE 8080
# JVM tuning for containers
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]