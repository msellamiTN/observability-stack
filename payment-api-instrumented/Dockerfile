# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY PaymentApi.csproj .
RUN dotnet restore

# Copy source code and build
COPY . .
RUN dotnet build -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

## Install curl for health checks
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Create log directory for shared volume (Loki)
RUN mkdir -p /var/log/payment-api \
    && chown -R appuser:appuser /var/log/payment-api

# Copy published app
COPY --from=publish /app/publish .

# Set ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose ports
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8888/health || exit 1

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8888
ENV ASPNETCORE_ENVIRONMENT=Production
ENV LOG_DIRECTORY=/var/log/payment-api
ENV ENABLE_FILE_LOGGING=false

# Volume for logs (to be mounted by Loki/Promtail)
VOLUME ["/var/log/payment-api"]

ENTRYPOINT ["dotnet", "PaymentApi.dll"]
