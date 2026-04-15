# PSK ERP

A Ruby on Rails ERP system for order management, inventory, and customer tracking.

## Prerequisites

| Requirement | Version |
|---|---|
| Ruby | 3.3.6 |
| Rails | 8.1.3 |
| PostgreSQL | 14+ |
| Node.js | 20+ (for asset compilation) |
| Redis | 7+ (for Sidekiq and Action Cable) |

## Environment Variables

| Variable | Description | Required |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection URL | Production |
| `SECRET_KEY_BASE` | Rails secret key base | Production |
| `REDIS_URL` | Redis connection URL | Production |
| `ADMIN_DEFAULT_PASSWORD` | Initial admin user password (default: `Admin@12345!`) | Optional |
| `AWS_ACCESS_KEY_ID` | AWS credentials for Active Storage S3 | Production |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for Active Storage S3 | Production |
| `AWS_REGION` | AWS region (default: `ap-southeast-1`) | Production |
| `AWS_BUCKET` | S3 bucket name (default: `psk-erp-<env>`) | Production |
| `RAILS_LOG_LEVEL` | Log level (default: `info`) | Optional |

## Setup

```bash
# 1. Install Ruby dependencies
bundle install

# 2. Create the database
bin/rails db:create

# 3. Run migrations
bin/rails db:migrate

# 4. Seed initial data (countries, admin user, main branch)
bin/rails db:seed
```

Default admin credentials after seeding:
- Email: `admin@psk.com`
- Password: `Admin@12345!` (override via `ADMIN_DEFAULT_PASSWORD` env var)

## Development Server

```bash
# Start Rails server, Sidekiq worker, and Tailwind watcher in one command
bin/dev
```

Or start each process individually:

```bash
bin/rails server              # Rails app on port 3000
bundle exec sidekiq           # Background job worker
bin/rails tailwindcss:watch   # Tailwind CSS watcher
```

## Running Tests

```bash
# Full test suite with coverage (minimum 90%)
bundle exec rspec --exclude-pattern "spec/integration/**/*"

# Generate OpenAPI docs from integration specs
bundle exec rails rswag:specs:swaggerize

# View API documentation
# Start the server, then open http://localhost:3000/api-docs
```

## Code Quality

```bash
# Linting
bin/rubocop

# Security scan
bin/brakeman --no-pager

# Dependency vulnerability check
bin/bundler-audit
```

## Background Jobs

Background jobs use Sidekiq. The job queue requires Redis.

```bash
# Monitor jobs via web UI (requires authentication)
# http://localhost:3000/admin/queues
```

## API Documentation

The REST API is documented with OpenAPI 3.0 (via rswag). View the interactive docs at `/api-docs` when the server is running.

All API endpoints require Bearer token authentication (JWT). Obtain a token via:

```
POST /api/v1/auth/sign_in
Content-Type: application/json

{ "email": "admin@psk.com", "password": "Admin@12345!" }
```

## Deployment

The application is Kamal-ready. See `config/deploy.yml` for deployment configuration.

```bash
kamal setup    # First-time setup
kamal deploy   # Deploy new version
```
