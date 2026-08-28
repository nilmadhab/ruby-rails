# Senior Ruby on Rails Interview Preparation Guide

A comprehensive preparation plan for live coding interviews.

---

## 1. Ruby Fundamentals (Must Know)

### Core Concepts
- [ ] Blocks, Procs, and Lambdas
- [ ] Closures and scope
- [ ] `yield` keyword
- [ ] Symbol vs String
- [ ] `attr_accessor`, `attr_reader`, `attr_writer`
- [ ] Instance variables (`@`) vs Class variables (`@@`)
- [ ] `self` in different contexts

### Object-Oriented Programming
- [ ] Classes and inheritance
- [ ] Modules and Mixins (`include` vs `extend` vs `prepend`)
- [ ] Method visibility (`public`, `private`, `protected`)
- [ ] Duck typing
- [ ] `super` keyword
- [ ] Method lookup chain

### Metaprogramming
- [ ] `method_missing`
- [ ] `define_method`
- [ ] `send` and `public_send`
- [ ] `class_eval` and `instance_eval`
- [ ] Dynamic method definition

### Common Methods to Master
```ruby
# Enumerable
.map, .select, .reject, .find, .reduce, .each_with_object
.group_by, .sort_by, .partition, .flat_map, .compact

# Array
.flatten, .uniq, .zip, .take, .drop, .sample

# Hash
.merge, .slice, .except, .transform_keys, .transform_values
.dig, .fetch, .default

# String
.split, .gsub, .match, .scan, .strip, .parameterize
```

---

## 2. Rails MVC Architecture

### Models (ActiveRecord)
- [ ] Associations (`has_many`, `belongs_to`, `has_one`, `has_many :through`)
- [ ] Polymorphic associations
- [ ] Self-referential associations
- [ ] Validations (built-in and custom)
- [ ] Callbacks (lifecycle hooks)
- [ ] Scopes (named and default)
- [ ] Transactions
- [ ] Optimistic vs Pessimistic locking

### Controllers
- [ ] RESTful actions (index, show, new, create, edit, update, destroy)
- [ ] Strong parameters
- [ ] Filters (`before_action`, `after_action`, `around_action`)
- [ ] `respond_to` for multiple formats
- [ ] Error handling and rescue

### Views (for API interviews, less focus)
- [ ] Partials
- [ ] Helpers
- [ ] JSON rendering (`jbuilder`, `as_json`)

---

## 3. Database & ActiveRecord Queries

### Query Interface
```ruby
# Basic
User.find(id)
User.find_by(email: "test@example.com")
User.where(active: true)
User.where.not(role: "admin")
User.order(created_at: :desc)
User.limit(10).offset(20)

# Chaining
User.where(active: true).order(:name).limit(10)

# Pluck vs Select
User.pluck(:id, :name)  # Returns array of arrays
User.select(:id, :name) # Returns AR relation

# Exists and counting
User.exists?(email: "test@example.com")
User.count
User.where(active: true).count
```

### N+1 Query Problem
```ruby
# BAD - N+1
posts = Post.all
posts.each { |p| puts p.user.name }  # Queries user for each post

# GOOD - Eager loading
posts = Post.includes(:user)
posts = Post.eager_load(:user)   # LEFT OUTER JOIN
posts = Post.preload(:user)      # Separate query
```

### Joins vs Includes
```ruby
# includes - for reading associated data
Post.includes(:comments).where(published: true)

# joins - for filtering by association
Post.joins(:comments).where(comments: { approved: true })

# Left outer join
Post.left_joins(:comments).where(comments: { id: nil })  # Posts with no comments
```

### Raw SQL When Needed
```ruby
User.find_by_sql("SELECT * FROM users WHERE...")
ActiveRecord::Base.connection.execute("...")
User.where("created_at > ?", 1.week.ago)
User.where("name ILIKE ?", "%john%")
```

---

## 4. API Design

### RESTful Conventions
| Action  | HTTP Verb | Path              | Purpose        |
|---------|-----------|-------------------|----------------|
| index   | GET       | /posts            | List all       |
| show    | GET       | /posts/:id        | Show one       |
| create  | POST      | /posts            | Create new     |
| update  | PATCH/PUT | /posts/:id        | Update         |
| destroy | DELETE    | /posts/:id        | Delete         |

### Nested Routes
```ruby
resources :posts do
  resources :comments, only: [:index, :create, :destroy]
end
# POST /posts/:post_id/comments
```

### API Versioning
```ruby
namespace :api do
  namespace :v1 do
    resources :users
  end
end
```

### Response Codes
- `200` - OK
- `201` - Created
- `204` - No Content (successful delete)
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Unprocessable Entity (validation failed)
- `500` - Internal Server Error

---

## 5. Authentication & Authorization

### Authentication (Who are you?)
- [ ] Session-based auth
- [ ] Token-based auth (JWT)
- [ ] `has_secure_password` with bcrypt
- [ ] OAuth basics

### JWT Flow
```ruby
# Encode
JWT.encode({ user_id: user.id, exp: 24.hours.from_now.to_i }, secret_key)

# Decode
JWT.decode(token, secret_key)
```

### Authorization (What can you do?)
- [ ] Role-based access control (RBAC)
- [ ] Pundit policies
- [ ] CanCanCan abilities
- [ ] Checking ownership (`@post.user == current_user`)

---

## 6. Testing (RSpec)

### Model Specs
```ruby
RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe "associations" do
    it { should have_many(:posts) }
    it { should belong_to(:organization) }
  end

  describe "#full_name" do
    it "returns first and last name" do
      user = User.new(first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
end
```

### Request Specs
```ruby
RSpec.describe "Posts API", type: :request do
  describe "GET /api/v1/posts" do
    it "returns all posts" do
      create_list(:post, 3)
      get "/api/v1/posts"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end
end
```

### FactoryBot
```ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "password123" }
  end
end
```

---

## 7. Performance Optimization

### Database Level
- [ ] Indexing (when and what to index)
- [ ] Eager loading (avoid N+1)
- [ ] `select` only needed columns
- [ ] Pagination (`limit`, `offset`, or gems like Kaminari)
- [ ] Counter cache
- [ ] Database-level constraints

### Application Level
- [ ] Caching (fragment, Russian doll, low-level)
- [ ] Background jobs (Sidekiq, ActiveJob)
- [ ] Lazy loading
- [ ] Batch processing (`find_each`, `in_batches`)

### Counter Cache Example
```ruby
# Migration
add_column :posts, :comments_count, :integer, default: 0

# Model
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end
```

---

## 8. Common Interview Patterns

### Service Objects
```ruby
class CreateOrder
  def initialize(user, cart)
    @user = user
    @cart = cart
  end

  def call
    Order.transaction do
      order = Order.create!(user: @user)
      @cart.items.each do |item|
        order.line_items.create!(product: item.product, quantity: item.quantity)
      end
      order
    end
  end
end

# Usage
CreateOrder.new(current_user, cart).call
```

### Query Objects
```ruby
class PublishedPostsQuery
  def initialize(relation = Post.all)
    @relation = relation
  end

  def call
    @relation
      .where(published: true)
      .where("published_at <= ?", Time.current)
      .order(published_at: :desc)
  end
end
```

### Form Objects
```ruby
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :name, :email, :password, :company_name

  validates :name, :email, :password, :company_name, presence: true

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name)
      User.create!(name: name, email: email, password: password, company: company)
    end
  end
end
```

---

## 9. Live Coding Topics

### Likely Challenges
1. **Build a RESTful API** - CRUD for a resource with associations
2. **Implement authentication** - Login/signup with JWT
3. **Fix N+1 queries** - Given slow code, optimize it
4. **Write a service object** - Extract complex logic
5. **Add a feature** - Comments, likes, follows, etc.
6. **Implement search/filter** - Query params to filter results
7. **Pagination** - Add pagination to an endpoint
8. **Background job** - Move slow operation to background

### Practice Problems
1. Build a URL shortener
2. Build a simple Twitter clone (posts, follows, feed)
3. Implement a rating/review system
4. Build a tagging system (polymorphic)
5. Implement soft delete
6. Build a notification system

---

## 10. System Design Considerations

### Scalability Questions
- [ ] Database indexing strategy
- [ ] Caching strategy (Redis)
- [ ] Background job processing
- [ ] Database sharding basics
- [ ] Read replicas

### Common Patterns
- [ ] Pub/Sub with ActionCable
- [ ] Webhooks
- [ ] Rate limiting
- [ ] Idempotency

---

## 11. Quick Reference Commands

### Rails Console
```ruby
# Reload changes
reload!

# See SQL queries
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Sandbox mode (rollback on exit)
rails console --sandbox

# Find last query
ActiveRecord::Base.connection.execute("SELECT 1")
```

### Debugging
```ruby
# In code
binding.pry      # With pry-byebug
debugger         # With debug gem

# Print SQL
User.where(active: true).to_sql
User.where(active: true).explain
```

---

## 12. Day-Before Checklist

- [ ] Review MVC request lifecycle
- [ ] Practice 2-3 coding problems from scratch
- [ ] Review your past Rails projects
- [ ] Know how to set up a new Rails API quickly
- [ ] Be ready to explain your code decisions
- [ ] Prepare questions about their tech stack

---

## 13. Study Schedule (2 Weeks)

### Week 1: Fundamentals
| Day | Topic |
|-----|-------|
| 1-2 | Ruby fundamentals, OOP, metaprogramming |
| 3-4 | ActiveRecord queries, associations, N+1 |
| 5-6 | Controllers, routing, API design |
| 7   | Authentication & authorization |

### Week 2: Advanced & Practice
| Day | Topic |
|-----|-------|
| 1-2 | Testing with RSpec |
| 3-4 | Performance, caching, background jobs |
| 5-6 | Practice problems (build mini projects) |
| 7   | Mock interview, review weak areas |

---

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Docs](https://ruby-doc.org/)
- [RSpec Documentation](https://rspec.info/)
- [GoRails Screencasts](https://gorails.com/)
- [Drifting Ruby](https://www.driftingruby.com/)

---

Good luck! Remember: **Think out loud**, **ask clarifying questions**, and **write clean, readable code**.
