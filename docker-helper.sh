#!/bin/bash

DOCKER_COMPOSE="docker compose"

case "$1" in
    up)
        $DOCKER_COMPOSE up -d
        echo "Docker containers started successfully!"
        ;;
    down)
        $DOCKER_COMPOSE down
        echo "Docker containers stopped and removed!"
        ;;
    artisan)
        shift
        $DOCKER_COMPOSE exec app php artisan "$@"
        ;;
    composer)
        shift
        $DOCKER_COMPOSE exec app composer "$@"
        ;;
    test)
        $DOCKER_COMPOSE exec app php artisan test
        ;;
    bash)
        $DOCKER_COMPOSE exec app bash
        ;;
    logs)
        $DOCKER_COMPOSE exec app bash
        ;;
    *)
        echo "Usage:"
        echo "  ./docker-helper.sh up        - Start the containers"
        echo "  ./docker-helper.sh down      - Stop the containers"
        echo "  ./docker-helper.sh artisan   - Run artisan commands"
        echo "  ./docker-helper.sh composer  - Run composer commands"
        echo "  ./docker-helper.sh test      - Run tests"
        echo "  ./docker-helper.sh bash      - Access bash in app container"
        echo "  ./docker-helper.sh logs      - View container logs"
        ;;
esac