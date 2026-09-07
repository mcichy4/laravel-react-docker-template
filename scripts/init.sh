#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="${1:-}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Usage: ./scripts/init.sh <project-name>"
    exit 1
fi

PROJECT_NAME=$(echo "$PROJECT_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9-' '-' \
    | sed 's/^-//; s/-$//')

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Invalid project name."
    exit 1
fi

if [[ -f .env ]]; then
    echo ".env already exists. Project appears to be initialized."
    exit 1
fi

if [[ -n "$(ls -A backend 2>/dev/null)" ]]; then
    echo "backend directory is not empty."
    exit 1
fi

if [[ -n "$(ls -A frontend 2>/dev/null)" ]]; then
    echo "frontend directory is not empty."
    exit 1
fi

echo "Initializing project: $PROJECT_NAME"

cp .env.example .env

sed -i.bak \
    -e "s/^PROJECT_NAME=.*/PROJECT_NAME=$PROJECT_NAME/" \
    -e "s/^POSTGRES_DB=.*/POSTGRES_DB=$PROJECT_NAME/" \
    -e "s/^POSTGRES_USER=.*/POSTGRES_USER=$PROJECT_NAME/" \
    .env

rm -f .env.bak

echo "Building Docker images..."
docker compose build

echo "Creating Laravel backend..."
docker compose run --rm php \
    composer create-project laravel/laravel .

echo "Creating React frontend..."
docker compose run --rm node \
    npm create vite@latest . -- --template react

echo "Installing frontend dependencies..."
docker compose run --rm node npm install

echo "Configuring Laravel..."

cp backend/.env.example backend/.env

sed -i.bak \
    -e 's/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/' \
    -e 's/^# DB_HOST=.*/DB_HOST=postgres/' \
    -e 's/^# DB_PORT=.*/DB_PORT=5432/' \
    -e "s/^# DB_DATABASE=.*/DB_DATABASE=$PROJECT_NAME/" \
    -e "s/^# DB_USERNAME=.*/DB_USERNAME=$PROJECT_NAME/" \
    -e 's/^# DB_PASSWORD=.*/DB_PASSWORD=secret/' \
    backend/.env

rm -f backend/.env.bak

echo "Starting containers..."
docker compose up -d

echo "Generating Laravel application key..."
docker compose exec php php artisan key:generate

echo "Running database migrations..."
docker compose exec php php artisan migrate --force

echo
echo "Project initialized successfully."
echo "Backend:  http://localhost:$(grep '^BACKEND_PORT=' .env | cut -d= -f2)"
echo "Frontend: http://localhost:$(grep '^FRONTEND_PORT=' .env | cut -d= -f2)"