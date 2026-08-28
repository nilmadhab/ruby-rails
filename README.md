# Blog Application

A full-stack blog application with Ruby on Rails API backend and Vue.js frontend.

## Project Structure

```
ruby/
├── blog_service/      # Rails API backend
├── blog_frontend/     # Vue.js frontend
└── docs/              # Documentation files
    ├── RAILS_INTERVIEW_PREP.md
    ├── RSPEC_TESTING_GUIDE.md
    ├── THREADING_CONCURRENCY_GUIDE.md
    └── ...
```

---

## Prerequisites

- Ruby 3.4+
- Node.js 18+
- PostgreSQL 14+

---

## Backend Setup (Rails API)

### 1. Navigate to backend directory

```bash
cd blog_service
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Setup database

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# (Optional) Seed data
bin/rails db:seed
```

### 4. Start the server

```bash
bin/rails server
# or
bin/rails s
```

Backend runs at: **http://localhost:3000**

### 5. Run tests

```bash
bundle exec rspec
```

---

## Frontend Setup (Vue.js)

### 1. Navigate to frontend directory

```bash
cd blog_frontend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Start development server

```bash
npm run dev
```

Frontend runs at: **http://localhost:5173**

### 4. Build for production

```bash
npm run build
```

---

## Running Both Services

Open two terminal windows:

**Terminal 1 - Backend:**
```bash
cd blog_service
bin/rails server
```

**Terminal 2 - Frontend:**
```bash
cd blog_frontend
npm run dev
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login user |
| GET | `/api/v1/auth/me` | Get current user |

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/posts` | List all posts |
| GET | `/api/v1/posts/:id` | Get single post |
| POST | `/api/v1/posts` | Create post (auth required) |
| PATCH | `/api/v1/posts/:id` | Update post (auth required) |
| DELETE | `/api/v1/posts/:id` | Delete post (auth required) |

### Comments

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/posts/:post_id/comments` | Add comment (auth required) |

### Likes

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/posts/:post_id/like` | Like a post (auth required) |
| DELETE | `/api/v1/posts/:post_id/like` | Unlike a post (auth required) |

### Categories

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/categories` | List all categories |
| POST | `/api/v1/categories` | Create category |

---

## Environment Variables

### Backend (.env)

```bash
# Database
DATABASE_URL=postgres://user:password@localhost:5432/blog_service

# JWT Secret (optional - uses Rails credentials by default)
JWT_SECRET_KEY=your-secret-key
```

### Frontend (.env)

```bash
VITE_API_URL=http://localhost:3000/api/v1
```

---

## Common Commands

### Backend

```bash
# Start server
bin/rails server

# Start console
bin/rails console

# Run tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# View routes
bin/rails routes

# Generate model
bin/rails generate model ModelName field:type

# Generate controller
bin/rails generate controller ControllerName action1 action2
# Example: bin/rails generate controller Api::V1::Likes create destroy

# Generate migration
bin/rails generate migration AddFieldToTable field:type
# Example: bin/rails generate migration AddLikesCountToPosts likes_count:integer

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback
```

### Frontend

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Lint code
npm run lint
```

---

## Troubleshooting

### Port already in use

```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Database connection issues

```bash
# Check PostgreSQL is running
pg_isready

# Start PostgreSQL (macOS)
brew services start postgresql
```

### Clear Rails cache

```bash
bin/rails tmp:clear
```

### Reset database

```bash
bin/rails db:drop db:create db:migrate
```

---

## Tech Stack

**Backend:**
- Ruby 3.4
- Rails 8.1 (API mode)
- PostgreSQL
- JWT Authentication
- RSpec + FactoryBot

**Frontend:**
- Vue 3
- Vite
- Vue Router
- Axios

---

## License

MIT
