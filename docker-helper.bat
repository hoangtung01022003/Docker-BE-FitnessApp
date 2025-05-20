@echo off
SET DOCKER_COMPOSE=docker compose

IF "%1"=="up" (
    %DOCKER_COMPOSE% up -d
    echo Docker containers started successfully!
    exit /b 0
)

IF "%1"=="down" (
    %DOCKER_COMPOSE% down
    echo Docker containers stopped and removed!
    exit /b 0
)

IF "%1"=="artisan" (
    shift
    %DOCKER_COMPOSE% exec app php artisan %1 %2 %3 %4 %5
    exit /b 0
)

IF "%1"=="composer" (
    shift
    %DOCKER_COMPOSE% exec app composer %1 %2 %3 %4 %5
    exit /b 0
)

IF "%1"=="test" (
    %DOCKER_COMPOSE% exec app php artisan test
    exit /b 0
)

IF "%1"=="bash" (
    %DOCKER_COMPOSE% exec app bash
    exit /b 0
)

IF "%1"=="logs" (
    %DOCKER_COMPOSE% logs -f %2
    exit /b 0
)

echo Usage:
echo   docker-helper up        - Start the containers
echo   docker-helper down      - Stop the containers
echo   docker-helper artisan   - Run artisan commands
echo   docker-helper composer  - Run composer commands
echo   docker-helper test      - Run tests
echo   docker-helper bash      - Access bash in app container
echo   docker-helper logs      - View container logs