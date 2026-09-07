# Laravel React Docker Template

Reusable development template for building applications with **Laravel**, **React**, **PostgreSQL** and **Docker**.

The template generates fresh Laravel and React applications during initialization, so framework source code is not stored directly in the template repository.

## Stack

* PHP 8.4
* Laravel
* React
* Vite
* Node.js 22
* PostgreSQL 17
* Nginx
* Docker Compose

## Requirements

Before creating a project, make sure you have:

* Docker or OrbStack
* Git

Optional:

* GitHub CLI (`gh`)

## Creating a new project

Create a new repository using this repository as a GitHub template.

Clone the newly created repository:

```bash
git clone <repository-url>
cd <project-directory>
```

Run the initializer:

```bash
./scripts/init.sh MyProject
```

For example:

```bash
./scripts/init.sh EventManager
```

The project name is normalized to lowercase and used to configure the Docker project and PostgreSQL database.

For `EventManager`, the generated configuration will contain values similar to:

```env
PROJECT_NAME=eventmanager
POSTGRES_DB=eventmanager
POSTGRES_USER=eventmanager
```

## What the initializer does

The initialization script:

1. Creates the root `.env` from `.env.example`
2. Configures project-specific environment variables
3. Creates the `backend/` and `frontend/` directories
4. Builds the PHP Docker image
5. Installs a fresh Laravel application
6. Installs a fresh React + Vite application
7. Installs frontend dependencies
8. Configures Laravel to use PostgreSQL
9. Starts Docker services
10. Generates the Laravel application key
11. Runs Laravel database migrations

After successful initialization, the project is ready for development.

## Application URLs

Default development URLs:

| Service         | URL                     |
| --------------- | ----------------------- |
| Laravel / Nginx | `http://localhost:8000` |
| React / Vite    | `http://localhost:5173` |
| PostgreSQL      | `localhost:5432`        |

The host ports can be changed in the root `.env`.

## Project structure

After initialization:

```text
.
├── backend/                 # Laravel application
├── frontend/                # React + Vite application
├── docker/
│   ├── nginx/
│   │   └── default.conf
│   └── php/
│       └── Dockerfile
├── scripts/
│   └── init.sh
├── docker-compose.yml
├── .env
├── .env.example
└── README.md
```

## Docker commands

Start the application:

```bash
docker compose up -d
```

Stop the application:

```bash
docker compose down
```

Check container status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

View logs for a specific service:

```bash
docker compose logs -f php
docker compose logs -f nginx
docker compose logs -f node
docker compose logs -f postgres
```

## Laravel commands

Run Artisan commands inside the PHP container:

```bash
docker compose exec php php artisan migrate
```

Examples:

```bash
docker compose exec php php artisan make:model Event -m
docker compose exec php php artisan make:controller EventController
docker compose exec php php artisan test
```

Run Composer:

```bash
docker compose exec php composer install
```

Install a Composer package:

```bash
docker compose exec php composer require vendor/package
```

## React / Node commands

Install dependencies:

```bash
docker compose exec node npm install
```

Install a package:

```bash
docker compose exec node npm install axios
```

Run other npm commands in the same way:

```bash
docker compose exec node npm run build
```

## Environment configuration

The root `.env.example` contains default development configuration:

```env
PROJECT_NAME=app

POSTGRES_DB=app
POSTGRES_USER=app
POSTGRES_PASSWORD=secret
POSTGRES_PORT=5432

BACKEND_PORT=8000
FRONTEND_PORT=5173
```

During initialization, project-specific values are written to the root `.env`.

For example:

```bash
./scripts/init.sh ShopApp
```

produces configuration similar to:

```env
PROJECT_NAME=shopapp

POSTGRES_DB=shopapp
POSTGRES_USER=shopapp
POSTGRES_PASSWORD=secret

POSTGRES_PORT=5432
BACKEND_PORT=8000
FRONTEND_PORT=5173
```

The `.env` file is local configuration and should not be committed to Git.

## PostgreSQL configuration

Laravel connects to PostgreSQL through the internal Docker network.

The Laravel `backend/.env` uses:

```env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=<project-name>
DB_USERNAME=<project-name>
DB_PASSWORD=secret
```

`DB_HOST=postgres` refers to the PostgreSQL service name defined in `docker-compose.yml`.

### Host port vs container port

The root configuration:

```env
POSTGRES_PORT=5432
```

controls the PostgreSQL port exposed on the **host machine**.

Laravel uses:

```env
DB_PORT=5432
```

because Laravel and PostgreSQL communicate through the **Docker network**, where PostgreSQL listens on its standard port `5432`.

For example, the host port can be changed to:

```env
POSTGRES_PORT=5433
```

while Laravel should still use:

```env
DB_HOST=postgres
DB_PORT=5432
```

## Running multiple projects

Multiple projects created from this template can run simultaneously, but their exposed host ports must be unique.

For example, the first project may use:

```env
POSTGRES_PORT=5432
BACKEND_PORT=8000
FRONTEND_PORT=5173
```

and another project:

```env
POSTGRES_PORT=5433
BACKEND_PORT=8001
FRONTEND_PORT=5174
```

After changing Docker port configuration, recreate the containers:

```bash
docker compose down
docker compose up -d
```

## Resetting the database

To remove containers and delete the PostgreSQL Docker volume:

```bash
docker compose down -v
```

Then start the application again:

```bash
docker compose up -d
```

> **Warning:** `docker compose down -v` permanently deletes the local PostgreSQL data stored in the Docker volume.

Do not use this command if the local database contains data you want to keep.

## Git

Generated environment files and dependencies should not be committed.

In particular:

```text
.env
backend/.env
backend/vendor/
frontend/node_modules/
```

should remain ignored by Git.

You can verify ignored files with:

```bash
git status
```

## Template philosophy

This repository contains infrastructure and initialization scripts rather than a pre-generated Laravel and React application.

Laravel and React are generated when:

```bash
./scripts/init.sh <project-name>
```

is executed.

This keeps the template reusable and allows new projects to start from fresh framework installations instead of copying an old Laravel or Vite project skeleton.

## Development only

The included Docker configuration is intended primarily for **local development**.

Production deployment may require additional configuration such as:

* production PHP settings
* optimized Docker images
* HTTPS
* secrets management
* production database configuration
* frontend production build
* Laravel cache optimization
* queue workers
* monitoring and logging
* backup strategy
