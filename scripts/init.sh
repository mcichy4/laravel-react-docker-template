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

mkdir -p backend frontend

if [[ -n "$(ls -A backend 2>/dev/null)" ]]; then
    echo "backend directory is not empty."
    exit 1
fi

if [[ -n "$(ls -A frontend 2>/dev/null)" ]]; then
    echo "frontend directory is not empty."
    exit 1
fi

set_env() {
    local file="$1"
    local key="$2"
    local value="$3"

    if grep -qE "^[# ]*${key}=" "$file"; then
        sed -i.bak -E "s|^[# ]*${key}=.*|${key}=${value}|" "$file"
        rm -f "${file}.bak"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

readonly USER_ID="$(id -u)"
readonly GROUP_ID="$(id -g)"

echo "Initializing project: $PROJECT_NAME"

cp .env.example .env

set_env .env PROJECT_NAME "$PROJECT_NAME"
set_env .env POSTGRES_DB "$PROJECT_NAME"
set_env .env POSTGRES_USER "$PROJECT_NAME"

set_env .env USER_ID "$USER_ID"
set_env .env GROUP_ID "$GROUP_ID"

echo "Building Docker images..."
docker compose build

echo "Creating Laravel backend..."
docker compose run --rm php \
    composer create-project --no-scripts laravel/laravel .

echo "Configuring Laravel backend..."
cp backend/.env.example backend/.env

echo "Creating React frontend..."
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$(pwd)/frontend:/app" \
    -w /app \
    node:22-alpine \
    npm create vite@latest . -- --template react

echo "Installing frontend dependencies..."
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$(pwd)/frontend:/app" \
    -w /app \
    node:22-alpine \
    npm install

echo "Configuring Laravel..."

set_env backend/.env DB_CONNECTION pgsql
set_env backend/.env DB_HOST postgres
set_env backend/.env DB_PORT 5432
set_env backend/.env DB_DATABASE "$PROJECT_NAME"
set_env backend/.env DB_USERNAME "$PROJECT_NAME"
set_env backend/.env DB_PASSWORD secret

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