# Use the official .NET runtime as a parent image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Use the SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ObservabilityWorkshop.Sample.csproj", "."]
RUN dotnet restore "./ObservabilityWorkshop.Sample.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "ObservabilityWorkshop.Sample.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ObservabilityWorkshop.Sample.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Add labels for better observability
LABEL maintainer="Azure Observability Workshop"
LABEL version="1.0.0"
LABEL description="Sample .NET application for observability workshop"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "ObservabilityWorkshop.Sample.dll"]