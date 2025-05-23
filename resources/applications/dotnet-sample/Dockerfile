# Multi-stage Dockerfile for .NET application with observability

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY ["dotnet-sample.csproj", "./"]
RUN dotnet restore "dotnet-sample.csproj"

# Copy source code
COPY . .

# Build application
RUN dotnet build "dotnet-sample.csproj" -c Release -o /app/build

# Publish application
FROM build AS publish
RUN dotnet publish "dotnet-sample.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install prerequisites for Datadog APM (if needed)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy published application
COPY --from=publish /app/publish .

# Set up environment variables for observability
ENV ASPNETCORE_URLS=http://+:80 \
    ASPNETCORE_ENVIRONMENT=Production \
    # OpenTelemetry settings
    OTEL_SERVICE_NAME=dotnet-sample \
    OTEL_RESOURCE_ATTRIBUTES="service.name=dotnet-sample,service.version=1.0.0" \
    OTEL_EXPORTER_OTLP_ENDPOINT="http://otel-collector:4317" \
    OTEL_EXPORTER_OTLP_PROTOCOL="grpc" \
    # Jaeger settings
    JAEGER_AGENT_HOST="jaeger-agent" \
    JAEGER_AGENT_PORT="6831" \
    # Datadog APM settings (optional)
    DD_ENV="production" \
    DD_SERVICE="dotnet-sample" \
    DD_VERSION="1.0.0" \
    DD_TRACE_AGENT_PORT="8126" \
    DD_RUNTIME_METRICS_ENABLED="true" \
    DD_PROFILING_ENABLED="true" \
    DD_APPSEC_ENABLED="true" \
    DD_LOGS_INJECTION="true" \
    # Prometheus metrics
    PROMETHEUS_METRICS_ENABLED="true" \
    PROMETHEUS_METRICS_PORT="9090"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose ports
EXPOSE 80
EXPOSE 9090

# Switch to non-root user
USER appuser

# Add labels for better container management
LABEL maintainer="Observability Workshop Team" \
      version="1.0.0" \
      description="Sample .NET application with full observability features" \
      org.opencontainers.image.source="https://github.com/observability-workshop/dotnet-sample" \
      org.opencontainers.image.documentation="https://github.com/observability-workshop/docs"

# Build arguments for compile-time configuration
ARG BUILD_DATE
ARG BUILD_NUMBER
ARG APP_INSIGHTS_KEY

# Set build-time labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${BUILD_NUMBER}" \
      com.microsoft.applicationinsights.key="${APP_INSIGHTS_KEY}"

# Run the application
ENTRYPOINT ["dotnet", "ObservabilityWorkshop.DotNetSample.dll"]