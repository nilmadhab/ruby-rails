# RSpec Testing Guide for Rails

A beginner-friendly guide to understanding RSpec testing in Ruby on Rails.

---

## Table of Contents

1. [What is RSpec?](#1-what-is-rspec)
2. [Project Structure](#2-project-structure)
3. [Unit Tests vs Integration Tests](#3-unit-tests-vs-integration-tests)
4. [Basic Syntax](#4-basic-syntax)
5. [Describe and Context](#5-describe-and-context)
6. [Let and Let!](#6-let-and-let)
7. [Subject](#7-subject)
8. [FactoryBot](#8-factorybot)
9. [Model Specs](#9-model-specs)
10. [Request Specs](#10-request-specs)
11. [Mocking and Stubbing](#11-mocking-and-stubbing)
12. [Mocking External API Calls](#12-mocking-external-api-calls)
13. [Database Testing](#13-database-testing)
14. [Matchers](#14-matchers)
15. [Running Tests](#15-running-tests)
16. [Best Practices](#16-best-practices)

---

## 1. What is RSpec?

RSpec is a testing framework for Ruby. It uses a readable, English-like syntax to describe how your code should behave.

```ruby
# English: "A user should have a valid email"
# RSpec:
it "has a valid email" do
  expect(user.email).to be_present
end
```

**Why Test?**
- Catch bugs before they reach production
- Confidence when refactoring code
- Documentation for how code should work
- Faster development in the long run

---

## 2. Project Structure

```
spec/
├── rails_helper.rb       # Rails-specific configuration
├── spec_helper.rb        # General RSpec configuration
├── support/              # Helper modules
│   └── auth_helper.rb    # Custom helpers (e.g., authentication)
├── factories/            # FactoryBot factories
│   ├── users.rb
│   ├── posts.rb
│   ├── categories.rb
│   └── comments.rb
├── models/               # Model tests
│   ├── user_spec.rb
│   ├── post_spec.rb
│   ├── category_spec.rb
│   └── comment_spec.rb
└── requests/             # API/Controller tests
    ├── auth_spec.rb
    ├── posts_spec.rb
    └── comments_spec.rb
```

**Naming Convention:** Test files must end with `_spec.rb`

---

## 3. Unit Tests vs Integration Tests

Understanding the difference between test types is crucial for writing effective tests.

### The Testing Pyramid

```
                    /\
                   /  \
                  / E2E \        ← Slow, expensive, few
                 /________\
                /          \
               / Integration \   ← Medium speed, some
              /______________\
             /                \
            /    Unit Tests    \  ← Fast, cheap, many
           /____________________\
```

### Unit Tests

**What:** Test a single unit (class, method) in isolation.

**Characteristics:**
- Fast (milliseconds)
- No database, no network, no external dependencies
- Test one thing at a time
- Use mocks/stubs for dependencies

**Example: Model Spec (Unit Test)**

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe '#full_name' do
    it 'combines first and last name' do
      # No database needed - using build (not create)
      user = build(:user, first_name: 'John', last_name: 'Doe')

      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'validations' do
    it 'requires email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end
  end
end
```

**What to Unit Test:**
- Model validations
- Model methods
- Service objects
- Plain Ruby classes
- Calculations and business logic

### Integration Tests

**What:** Test multiple components working together.

**Characteristics:**
- Slower (seconds)
- Hits the database
- Tests the full request/response cycle
- Tests how components integrate

**Example: Request Spec (Integration Test)**

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts API', type: :request do
  describe 'POST /api/v1/posts' do
    let!(:user) { create(:user) }           # Database
    let!(:category) { create(:category) }   # Database

    it 'creates a post' do
      # Tests: routing → controller → model → database → response
      post '/api/v1/posts',
           params: { post: { title: 'Hello', body: 'World', category_id: category.id } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      expect(Post.count).to eq(1)  # Verifies database
    end
  end
end
```

**What to Integration Test:**
- API endpoints (request specs)
- User flows
- Multiple models working together
- Authentication flows

### Comparison Table

| Aspect | Unit Test | Integration Test |
|--------|-----------|------------------|
| **Speed** | Very fast (ms) | Slower (seconds) |
| **Database** | No (use `build`) | Yes (use `create`) |
| **External APIs** | Mocked | Can be real or mocked |
| **Scope** | Single class/method | Multiple components |
| **Quantity** | Many (70-80%) | Fewer (20-30%) |
| **When fails** | Points to exact problem | Shows something is broken |
| **Example** | Model spec | Request spec |

### In Your Blog Project

```
spec/
├── models/          ← UNIT TESTS (fast, isolated)
│   ├── user_spec.rb
│   ├── post_spec.rb
│   ├── category_spec.rb
│   └── comment_spec.rb
│
└── requests/        ← INTEGRATION TESTS (full stack)
    ├── auth_spec.rb
    ├── posts_spec.rb
    └── comments_spec.rb
```

### Rule of Thumb

```
"Write unit tests for logic, integration tests for flows"
```

- **Unit test:** Does this method calculate correctly?
- **Integration test:** Can a user create a post via the API?

---

## 4. Basic Syntax

### The Anatomy of a Test

```ruby
require 'rails_helper'  # Load Rails and RSpec configuration

RSpec.describe User, type: :model do  # What are we testing?

  describe '#full_name' do            # What method/behavior?

    it 'returns first and last name combined' do  # What should happen?
      user = User.new(first_name: 'John', last_name: 'Doe')

      expect(user.full_name).to eq('John Doe')  # The actual test
    end

  end
end
```

### Breaking It Down

| Part | Purpose |
|------|---------|
| `RSpec.describe` | Groups related tests together |
| `describe` | Describes a specific method or behavior |
| `it` | Defines a single test case |
| `expect(...).to` | The assertion - what we're checking |

---

## 5. Describe and Context

### `describe` - Groups by Feature/Method

```ruby
RSpec.describe User, type: :model do

  describe 'validations' do
    # Tests for validations go here
  end

  describe 'associations' do
    # Tests for associations go here
  end

  describe '#authenticate' do
    # Tests for the authenticate method
    # Convention: use # for instance methods, . for class methods
  end

end
```

### `context` - Groups by Scenario/Condition

```ruby
describe 'POST /api/v1/auth/login' do

  context 'with valid credentials' do
    it 'returns a token' do
      # happy path test
    end
  end

  context 'with invalid credentials' do
    it 'returns unauthorized' do
      # sad path test
    end
  end

end
```

**Rule of Thumb:**
- `describe` = WHAT you're testing
- `context` = WHEN/UNDER WHAT CONDITIONS

---

## 6. Let and Let!

### `let` - Lazy Loading (Created when first used)

```ruby
RSpec.describe Post, type: :model do
  # This user is NOT created until we call `user` in a test
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  it 'belongs to a user' do
    post = create(:post, user: user)  # `user` is created HERE
    expect(post.user).to eq(user)
  end
end
```

### `let!` - Eager Loading (Created immediately)

```ruby
RSpec.describe 'Posts API' do
  # These are created BEFORE each test runs
  let!(:user) { create(:user) }
  let!(:posts) { create_list(:post, 3, user: user) }

  it 'returns all posts' do
    get '/api/v1/posts'
    # posts already exist in database
    expect(JSON.parse(response.body).size).to eq(3)
  end
end
```

### When to Use Which?

| Use `let` | Use `let!` |
|-----------|------------|
| When you might not need the object in every test | When you need objects to exist before the test runs |
| For building objects without saving | When testing queries that fetch existing records |
| To improve test performance | When the test depends on database state |

### Comparison Example

```ruby
# With let (lazy) - user created only if test uses `user`
let(:user) { create(:user) }

# With let! (eager) - user created before EVERY test
let!(:user) { create(:user) }

# Equivalent to:
before(:each) do
  @user = create(:user)
end
```

---

## 7. Subject

`subject` is a special `let` for the thing you're testing.

```ruby
RSpec.describe User, type: :model do
  # Explicit subject
  subject { build(:user) }

  # Now you can use one-liner syntax
  it { should validate_presence_of(:email) }
  it { should have_many(:posts) }
end
```

### Without Subject (verbose)

```ruby
it 'validates presence of email' do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
end
```

### With Subject (concise)

```ruby
subject { build(:user) }
it { should validate_presence_of(:email) }
```

---

## 8. FactoryBot

FactoryBot creates test data. Think of factories as "templates" for creating objects.

### Defining a Factory

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }           # Dynamic value using Faker
    email { Faker::Internet.unique.email }
    password { "password123" }           # Static value
  end
end
```

### Using Factories

```ruby
# Build (in memory, not saved to database)
user = build(:user)
user.persisted?  # => false

# Create (saved to database)
user = create(:user)
user.persisted?  # => true

# Create with overrides
user = create(:user, name: "Custom Name", email: "custom@example.com")

# Create multiple records
users = create_list(:user, 5)  # Creates 5 users

# Build attributes as a hash
attrs = attributes_for(:user)
# => { name: "John", email: "john@example.com", password: "password123" }
```

### Factory with Associations

```ruby
# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    association :user      # Automatically creates a user
    association :category  # Automatically creates a category
  end
end

# Usage
post = create(:post)
post.user      # => A User instance (auto-created)
post.category  # => A Category instance (auto-created)

# Or specify your own
my_user = create(:user)
post = create(:post, user: my_user)
```

---

## 9. Model Specs

Model specs test your ActiveRecord models: validations, associations, and custom methods.

### Testing Validations

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    # Using Shoulda Matchers (one-liners)
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:password).is_at_least(6) }
  end
end
```

**Without Shoulda Matchers (manual way):**

```ruby
describe 'validations' do
  it 'requires a name' do
    user = build(:user, name: nil)
    expect(user).not_to be_valid
    expect(user.errors[:name]).to include("can't be blank")
  end

  it 'requires a unique email' do
    create(:user, email: 'taken@example.com')
    user = build(:user, email: 'taken@example.com')
    expect(user).not_to be_valid
  end
end
```

### Testing Associations

```ruby
describe 'associations' do
  # Shoulda Matchers
  it { should have_many(:posts).dependent(:destroy) }
  it { should have_many(:comments).dependent(:destroy) }
  it { should belong_to(:category) }
end
```

### Testing Custom Methods

```ruby
describe '#authenticate' do
  it 'returns user with correct password' do
    user = create(:user, password: 'secret123')
    expect(user.authenticate('secret123')).to eq(user)
  end

  it 'returns false with incorrect password' do
    user = create(:user, password: 'secret123')
    expect(user.authenticate('wrong')).to be_falsey
  end
end
```

### Testing Callbacks and Dependent Destroy

```ruby
describe 'dependent destroy' do
  it 'destroys comments when post is destroyed' do
    post = create(:post)
    create_list(:comment, 3, post: post)

    expect { post.destroy }.to change(Comment, :count).by(-3)
  end
end
```

---

## 10. Request Specs

Request specs test your API endpoints. They simulate HTTP requests and check responses.

### Basic Structure

```ruby
# spec/requests/posts_spec.rb
RSpec.describe 'Posts API', type: :request do

  describe 'GET /api/v1/posts' do
    let!(:posts) { create_list(:post, 3) }

    it 'returns all posts' do
      get '/api/v1/posts'  # Make the HTTP request

      expect(response).to have_http_status(:ok)  # Check status code

      json = JSON.parse(response.body)  # Parse JSON response
      expect(json.size).to eq(3)        # Check response data
    end
  end

end
```

### HTTP Methods

```ruby
# GET request
get '/api/v1/posts'
get '/api/v1/posts/1'

# POST request with params
post '/api/v1/posts', params: { post: { title: 'Hello', body: 'World' } }

# PATCH/PUT request
patch '/api/v1/posts/1', params: { post: { title: 'Updated' } }

# DELETE request
delete '/api/v1/posts/1'

# With headers (e.g., authentication)
get '/api/v1/posts', headers: { 'Authorization' => 'Bearer token123' }
```

### Testing with Authentication

```ruby
# spec/support/auth_helper.rb
module AuthHelper
  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
```

```ruby
# In your spec
describe 'POST /api/v1/posts' do
  let(:user) { create(:user) }

  context 'when authenticated' do
    it 'creates a post' do
      post '/api/v1/posts',
           params: { post: { title: 'Hello', body: 'World', category_id: 1 } },
           headers: auth_headers(user)  # Using the helper

      expect(response).to have_http_status(:created)
    end
  end

  context 'when not authenticated' do
    it 'returns unauthorized' do
      post '/api/v1/posts', params: { post: { title: 'Hello' } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

### Common Response Checks

```ruby
# Status codes
expect(response).to have_http_status(:ok)           # 200
expect(response).to have_http_status(:created)      # 201
expect(response).to have_http_status(:no_content)   # 204
expect(response).to have_http_status(:unauthorized) # 401
expect(response).to have_http_status(:forbidden)    # 403
expect(response).to have_http_status(:not_found)    # 404
expect(response).to have_http_status(:unprocessable_entity)  # 422

# Parsing JSON response
json = JSON.parse(response.body)

# Checking response content
expect(json['title']).to eq('Hello')
expect(json['user']['id']).to eq(user.id)
expect(json['errors']).to include("can't be blank")
```

### Testing Database Changes

```ruby
it 'creates a new post' do
  expect {
    post '/api/v1/posts', params: valid_params, headers: auth_headers(user)
  }.to change(Post, :count).by(1)
end

it 'deletes the post' do
  expect {
    delete "/api/v1/posts/#{post.id}", headers: auth_headers(user)
  }.to change(Post, :count).by(-1)
end
```

---

## 11. Mocking and Stubbing

Mocking and stubbing let you isolate the code you're testing by replacing dependencies with fake objects.

### What's the Difference?

| Term | Purpose | Example |
|------|---------|---------|
| **Stub** | Replace a method with a canned response | `allow(user).to receive(:admin?).and_return(true)` |
| **Mock** | Stub + verify it was called | `expect(mailer).to receive(:send_email)` |
| **Double** | Fake object that stands in for a real one | `double('User', name: 'John')` |
| **Spy** | Record calls for later verification | `spy('Logger')` |

### Stubs - Fake Return Values

```ruby
# Stub a method to return a specific value
allow(user).to receive(:admin?).and_return(true)

# Now user.admin? always returns true
expect(user.admin?).to eq(true)
```

### Real Example: Stubbing Time

```ruby
describe Post do
  describe '#recent?' do
    it 'returns true for posts from last week' do
      post = build(:post, created_at: 3.days.ago)

      expect(post.recent?).to be true
    end

    it 'returns false for old posts' do
      post = build(:post, created_at: 1.month.ago)

      expect(post.recent?).to be false
    end
  end
end

# Or freeze time for consistent tests
describe '#recent?' do
  it 'returns true for posts from last week' do
    # Freeze time
    allow(Time).to receive(:current).and_return(Time.new(2024, 1, 15))

    post = build(:post, created_at: Time.new(2024, 1, 10))
    expect(post.recent?).to be true
  end
end
```

### Mocks - Verify Method Calls

```ruby
describe NotificationService do
  describe '#notify_user' do
    it 'sends an email' do
      mailer = double('Mailer')
      user = create(:user)

      # EXPECT this method to be called
      expect(mailer).to receive(:send_email).with(user.email, anything)

      service = NotificationService.new(mailer)
      service.notify_user(user)
    end
  end
end
```

### Doubles - Fake Objects

```ruby
# Simple double
user_double = double('User')
allow(user_double).to receive(:name).and_return('John')
allow(user_double).to receive(:email).and_return('john@example.com')

# Double with attributes (shorthand)
user_double = double('User', name: 'John', email: 'john@example.com')

# Instance double (verifies methods exist on real class)
user_double = instance_double(User, name: 'John', email: 'john@example.com')
# This will error if User doesn't have 'name' or 'email' methods
```

### Stubbing Chains

```ruby
# If you need to stub: user.posts.published.count
allow(user).to receive_message_chain(:posts, :published, :count).and_return(5)
```

### Common Stubbing Patterns

```ruby
# Return different values on consecutive calls
allow(dice).to receive(:roll).and_return(1, 4, 6)
dice.roll  # => 1
dice.roll  # => 4
dice.roll  # => 6

# Raise an error
allow(api).to receive(:fetch).and_raise(ConnectionError)

# Call the original method
allow(user).to receive(:save).and_call_original

# Yield to a block
allow(file).to receive(:open).and_yield(mock_file)
```

### When to Use Mocks/Stubs

**DO use mocks/stubs for:**
- External services (APIs, email, SMS)
- Time-dependent code
- Random values
- Expensive operations
- Things you don't control

**DON'T use mocks/stubs for:**
- The class you're testing
- Simple value objects
- Everything (leads to brittle tests)

---

## 12. Mocking External API Calls

When your app calls external APIs (Stripe, SendGrid, Twilio), you need to mock those calls in tests.

### Why Mock External APIs?

1. **Speed** - API calls are slow
2. **Cost** - Some APIs charge per request
3. **Reliability** - Tests shouldn't fail if API is down
4. **Isolation** - Test YOUR code, not the API
5. **Control** - Test edge cases (errors, timeouts)

### Method 1: Using WebMock Gem

WebMock intercepts HTTP requests and returns fake responses.

```ruby
# Gemfile
group :test do
  gem 'webmock'
end
```

```ruby
# spec/rails_helper.rb
require 'webmock/rspec'

# Disable all real HTTP connections in tests
WebMock.disable_net_connect!(allow_localhost: true)
```

```ruby
# spec/services/weather_service_spec.rb
require 'rails_helper'

RSpec.describe WeatherService do
  describe '#get_temperature' do
    it 'returns temperature from API' do
      # Stub the HTTP request
      stub_request(:get, "https://api.weather.com/v1/current")
        .with(query: { city: 'London' })
        .to_return(
          status: 200,
          body: { temperature: 20, unit: 'celsius' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      service = WeatherService.new
      result = service.get_temperature('London')

      expect(result).to eq(20)
    end

    it 'handles API errors' do
      stub_request(:get, "https://api.weather.com/v1/current")
        .to_return(status: 500, body: 'Server Error')

      service = WeatherService.new

      expect { service.get_temperature('London') }.to raise_error(ApiError)
    end

    it 'handles timeouts' do
      stub_request(:get, "https://api.weather.com/v1/current")
        .to_timeout

      service = WeatherService.new

      expect { service.get_temperature('London') }.to raise_error(TimeoutError)
    end
  end
end
```

### Method 2: Using VCR Gem

VCR records real API responses and replays them in future tests.

```ruby
# Gemfile
group :test do
  gem 'vcr'
  gem 'webmock'
end
```

```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV['WEATHER_API_KEY'] }
end
```

```ruby
# spec/services/weather_service_spec.rb
RSpec.describe WeatherService do
  describe '#get_temperature', :vcr do
    it 'returns temperature from API' do
      # First run: makes REAL API call and records response
      # Subsequent runs: uses recorded response
      service = WeatherService.new
      result = service.get_temperature('London')

      expect(result).to be_a(Numeric)
    end
  end
end

# Or explicitly name the cassette
it 'returns temperature' do
  VCR.use_cassette('weather_london') do
    service = WeatherService.new
    result = service.get_temperature('London')
    expect(result).to eq(20)
  end
end
```

**Recorded cassette file (spec/cassettes/weather_london.yml):**
```yaml
---
http_interactions:
- request:
    method: get
    uri: https://api.weather.com/v1/current?city=London
  response:
    status:
      code: 200
    body: '{"temperature": 20, "unit": "celsius"}'
  recorded_at: 2024-01-15 10:00:00
```

### Method 3: Stub at the Service Level

```ruby
# Instead of mocking HTTP, mock your service class
RSpec.describe PostsController do
  describe 'POST #create' do
    it 'notifies external service' do
      # Stub the entire service
      notification_service = instance_double(NotificationService)
      allow(NotificationService).to receive(:new).and_return(notification_service)
      allow(notification_service).to receive(:notify).and_return(true)

      post '/api/v1/posts', params: { post: { title: 'Hello' } }

      expect(notification_service).to have_received(:notify)
    end
  end
end
```

### Example: Mocking Stripe API

```ruby
# spec/services/payment_service_spec.rb
RSpec.describe PaymentService do
  describe '#charge' do
    it 'creates a Stripe charge' do
      # Create a mock Stripe charge response
      stub_request(:post, "https://api.stripe.com/v1/charges")
        .with(
          body: hash_including(amount: '1000', currency: 'usd'),
          headers: { 'Authorization' => "Bearer #{ENV['STRIPE_SECRET_KEY']}" }
        )
        .to_return(
          status: 200,
          body: {
            id: 'ch_123',
            amount: 1000,
            status: 'succeeded'
          }.to_json
        )

      result = PaymentService.new.charge(amount: 1000, currency: 'usd')

      expect(result[:status]).to eq('succeeded')
    end

    it 'handles declined cards' do
      stub_request(:post, "https://api.stripe.com/v1/charges")
        .to_return(
          status: 402,
          body: { error: { message: 'Card declined' } }.to_json
        )

      expect {
        PaymentService.new.charge(amount: 1000)
      }.to raise_error(PaymentError, 'Card declined')
    end
  end
end
```

### WebMock Cheat Sheet

```ruby
# Match any request to a host
stub_request(:any, /api\.example\.com/)

# Match specific headers
stub_request(:get, 'https://api.example.com/data')
  .with(headers: { 'Authorization' => 'Bearer token123' })

# Match request body
stub_request(:post, 'https://api.example.com/users')
  .with(body: { name: 'John' })

# Return different responses
stub_request(:get, 'https://api.example.com/data')
  .to_return({ body: 'First' }, { body: 'Second' })

# Verify request was made
expect(WebMock).to have_requested(:get, 'https://api.example.com/data').once
expect(WebMock).to have_requested(:post, 'https://api.example.com/users')
  .with(body: { name: 'John' })
```

---

## 13. Database Testing

Understanding how Rails handles the database in tests.

### Test Database

Rails uses a separate database for tests:

```yaml
# config/database.yml
test:
  <<: *default
  database: blog_service_test   # Separate from development!
```

```bash
# Create test database
rails db:create RAILS_ENV=test

# Run migrations on test database
rails db:migrate RAILS_ENV=test

# Or do both
rails db:test:prepare
```

### Transactional Tests (Default)

By default, each test runs in a database transaction that rolls back:

```ruby
# spec/rails_helper.rb
config.use_transactional_fixtures = true
```

```
Test 1 starts
├── BEGIN TRANSACTION
├── create(:user)           # User created
├── create(:post)           # Post created
├── expect(User.count).to eq(1)  ✓
├── ROLLBACK                # Everything undone!
└── Test 1 ends

Test 2 starts
├── BEGIN TRANSACTION
├── User.count              # => 0 (clean slate!)
├── ...
```

**Benefits:**
- Each test starts with empty database
- Tests don't affect each other
- Fast (no actual deletes needed)

### Database Cleaner (For Complex Scenarios)

Sometimes you need more control (e.g., JavaScript tests, multiple databases):

```ruby
# Gemfile
gem 'database_cleaner-active_record'
```

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

### Testing Database Operations

#### Testing Records Are Created

```ruby
it 'creates a user' do
  expect {
    post '/api/v1/auth/register', params: { name: 'John', email: 'john@example.com', password: 'secret' }
  }.to change(User, :count).by(1)
end
```

#### Testing Records Are Updated

```ruby
it 'updates the post title' do
  post = create(:post, title: 'Old Title')

  expect {
    patch "/api/v1/posts/#{post.id}", params: { post: { title: 'New Title' } }, headers: auth_headers(post.user)
  }.to change { post.reload.title }.from('Old Title').to('New Title')
end
```

#### Testing Records Are Deleted

```ruby
it 'deletes the post' do
  post = create(:post)

  expect {
    delete "/api/v1/posts/#{post.id}", headers: auth_headers(post.user)
  }.to change(Post, :count).by(-1)
end
```

#### Testing Associations

```ruby
it 'deletes associated comments when post is deleted' do
  post = create(:post)
  create_list(:comment, 3, post: post)

  expect {
    post.destroy
  }.to change(Comment, :count).by(-3)
end
```

### Build vs Create

```ruby
# BUILD - in memory only, no database
user = build(:user)
user.persisted?  # => false
User.count       # => 0

# CREATE - saved to database
user = create(:user)
user.persisted?  # => true
User.count       # => 1
```

**When to use which:**

| Use `build` | Use `create` |
|-------------|--------------|
| Testing validations | Testing queries |
| Testing instance methods | Testing associations |
| Unit tests | Integration tests |
| When you don't need persistence | When you need to find records |

```ruby
# GOOD: Use build for validation tests (faster)
describe 'validations' do
  it 'requires email' do
    user = build(:user, email: nil)  # Not saved
    expect(user).not_to be_valid
  end
end

# GOOD: Use create for query tests
describe '.active' do
  it 'returns only active users' do
    active = create(:user, active: true)
    inactive = create(:user, active: false)

    expect(User.active).to contain_exactly(active)
  end
end
```

### Testing Scopes

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { where('created_at > ?', 1.week.ago) }
  scope :by_category, ->(category) { where(category: category) }
end
```

```ruby
# spec/models/post_spec.rb
describe 'scopes' do
  describe '.published' do
    it 'returns only published posts' do
      published = create(:post, published: true)
      draft = create(:post, published: false)

      expect(Post.published).to contain_exactly(published)
    end
  end

  describe '.recent' do
    it 'returns posts from last week' do
      recent = create(:post, created_at: 2.days.ago)
      old = create(:post, created_at: 2.weeks.ago)

      expect(Post.recent).to contain_exactly(recent)
    end
  end

  describe '.by_category' do
    it 'filters by category' do
      tech = create(:category, name: 'Tech')
      food = create(:category, name: 'Food')
      tech_post = create(:post, category: tech)
      food_post = create(:post, category: food)

      expect(Post.by_category(tech)).to contain_exactly(tech_post)
    end
  end
end
```

### Testing Uniqueness Constraints

```ruby
describe 'email uniqueness' do
  it 'does not allow duplicate emails' do
    create(:user, email: 'taken@example.com')
    duplicate = build(:user, email: 'taken@example.com')

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include('has already been taken')
  end

  it 'is case insensitive' do
    create(:user, email: 'Test@Example.com')
    duplicate = build(:user, email: 'test@example.com')

    expect(duplicate).not_to be_valid
  end
end
```

### Testing Database Constraints

```ruby
describe 'database constraints' do
  it 'enforces foreign key constraint' do
    expect {
      # Try to create comment with non-existent post_id
      Comment.create!(body: 'Hello', post_id: 999999, user_id: 1)
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it 'enforces not null constraint' do
    expect {
      Post.connection.execute("INSERT INTO posts (title) VALUES (NULL)")
    }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
```

### Tips for Database Testing

1. **Keep test database in sync:**
   ```bash
   rails db:migrate RAILS_ENV=test
   # Or
   rails db:test:prepare
   ```

2. **Use `reload` to get fresh data:**
   ```ruby
   post.update(title: 'New')
   post.reload  # Fetch from database
   expect(post.title).to eq('New')
   ```

3. **Count queries for performance:**
   ```ruby
   expect {
     Post.includes(:comments).each { |p| p.comments.size }
   }.to make_database_queries(count: 2)  # With bullet gem
   ```

4. **Test indexes exist:**
   ```ruby
   it 'has index on email' do
     expect(ActiveRecord::Base.connection.index_exists?(:users, :email)).to be true
   end
   ```

---

## 14. Matchers

Matchers are the `expect(...).to MATCHER` part. Here are the most common ones:

### Equality Matchers

```ruby
expect(result).to eq(5)           # Equal (value)
expect(result).to eql(5)          # Equal (value + type)
expect(object).to equal(other)    # Same object in memory
expect(result).to be(5)           # Same as equal
```

### Truthiness Matchers

```ruby
expect(result).to be true
expect(result).to be false
expect(result).to be_truthy      # Anything except nil/false
expect(result).to be_falsey      # nil or false
expect(result).to be_nil
```

### Comparison Matchers

```ruby
expect(result).to be > 5
expect(result).to be >= 5
expect(result).to be < 10
expect(result).to be_between(1, 10)
```

### Collection Matchers

```ruby
expect(array).to include(1, 2)
expect(array).to contain_exactly(1, 2, 3)  # Exact contents, any order
expect(array).to match_array([3, 2, 1])    # Same as contain_exactly
expect(array).to be_empty
expect(array).to have_attributes(name: 'John')
```

### String Matchers

```ruby
expect(string).to include('hello')
expect(string).to start_with('Hello')
expect(string).to end_with('world')
expect(string).to match(/regex/)
```

### Change Matchers

```ruby
expect { post.destroy }.to change(Comment, :count).by(-3)
expect { user.save }.to change(User, :count).by(1)
expect { user.update(name: 'New') }.to change { user.name }.from('Old').to('New')
```

### Predicate Matchers

```ruby
# If object has `valid?` method:
expect(user).to be_valid

# If object has `admin?` method:
expect(user).to be_admin

# If object has `empty?` method:
expect(array).to be_empty
```

### Shoulda Matchers (for Rails)

```ruby
# Validations
it { should validate_presence_of(:name) }
it { should validate_uniqueness_of(:email) }
it { should validate_length_of(:password).is_at_least(6) }
it { should validate_numericality_of(:age) }

# Associations
it { should belong_to(:user) }
it { should have_many(:posts) }
it { should have_many(:posts).dependent(:destroy) }
it { should have_one(:profile) }
```

---

## 15. Running Tests

### Command Line

```bash
# Run ALL tests
bundle exec rspec

# Run a specific file
bundle exec rspec spec/models/user_spec.rb

# Run a specific folder
bundle exec rspec spec/models
bundle exec rspec spec/requests

# Run a specific test by line number
bundle exec rspec spec/models/user_spec.rb:15

# Run tests matching a pattern
bundle exec rspec --example "creates a new post"

# Run with detailed output
bundle exec rspec --format documentation

# Run only failed tests from last run
bundle exec rspec --only-failures
```

### Output Formats

```bash
# Dots (default) - . for pass, F for fail
bundle exec rspec

# Documentation - shows describe/it text
bundle exec rspec --format documentation

# Short output
bundle exec rspec --format progress
```

### Example Output

```
Posts API
  GET /api/v1/posts
    returns all posts
    includes user and category
  POST /api/v1/posts
    when authenticated
      creates a new post
    when not authenticated
      returns unauthorized

Finished in 0.5 seconds
5 examples, 0 failures
```

---

## 16. Best Practices

### 1. One Expectation Per Test (Usually)

```ruby
# Good - focused tests
it 'returns status ok' do
  get '/api/v1/posts'
  expect(response).to have_http_status(:ok)
end

it 'returns all posts' do
  get '/api/v1/posts'
  expect(JSON.parse(response.body).size).to eq(3)
end

# Also OK - related expectations in one test
it 'returns post with correct attributes' do
  get '/api/v1/posts/1'
  json = JSON.parse(response.body)
  expect(json['title']).to eq('Hello')
  expect(json['body']).to eq('World')
end
```

### 2. Use Descriptive Test Names

```ruby
# Bad
it 'works' do

# Good
it 'returns unauthorized when token is missing' do
it 'creates a post with valid attributes' do
it 'returns 404 when post does not exist' do
```

### 3. Arrange-Act-Assert Pattern

```ruby
it 'creates a comment' do
  # Arrange - set up test data
  user = create(:user)
  post = create(:post)

  # Act - perform the action
  post '/api/v1/posts/#{post.id}/comments',
       params: { comment: { body: 'Great!' } },
       headers: auth_headers(user)

  # Assert - check the result
  expect(response).to have_http_status(:created)
  expect(Comment.count).to eq(1)
end
```

### 4. Test Edge Cases

```ruby
describe 'POST /api/v1/posts' do
  context 'with valid params' do
    it 'creates a post' do
      # happy path
    end
  end

  context 'with missing title' do
    it 'returns validation error' do
      # edge case
    end
  end

  context 'without authentication' do
    it 'returns unauthorized' do
      # edge case
    end
  end

  context 'when category does not exist' do
    it 'returns not found' do
      # edge case
    end
  end
end
```

### 5. Use Factories, Not Fixtures

```ruby
# Good - explicit, readable
let(:user) { create(:user, name: 'John') }

# Avoid - fixtures are harder to understand
# fixtures :users  # What data does this have?
```

### 6. Clean Database Between Tests

Rails does this automatically with:

```ruby
# spec/rails_helper.rb
config.use_transactional_fixtures = true
```

Each test runs in a database transaction that rolls back after.

---

## Quick Reference

| Concept | Purpose | Example |
|---------|---------|---------|
| `describe` | Group by feature/method | `describe 'validations'` |
| `context` | Group by scenario | `context 'when logged in'` |
| `it` | Define a test | `it 'returns 200'` |
| `let` | Lazy variable | `let(:user) { create(:user) }` |
| `let!` | Eager variable | `let!(:posts) { create_list(:post, 3) }` |
| `subject` | Main test object | `subject { build(:user) }` |
| `before` | Run before tests | `before { sign_in(user) }` |
| `expect` | Make assertion | `expect(response).to be_ok` |

---

## Resources

- [RSpec Documentation](https://rspec.info/documentation/)
- [FactoryBot Getting Started](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [Better Specs](https://www.betterspecs.org/) - RSpec best practices

---

## Your Project's Test Summary

```
spec/
├── models/
│   ├── user_spec.rb      # 8 tests (validations, associations, auth)
│   ├── category_spec.rb  # 4 tests (validations, associations)
│   ├── post_spec.rb      # 6 tests (validations, associations, dependent destroy)
│   └── comment_spec.rb   # 4 tests (validations, associations)
└── requests/
    ├── auth_spec.rb      # 9 tests (register, login, me)
    ├── posts_spec.rb     # 13 tests (CRUD with auth)
    └── comments_spec.rb  # 6 tests (create with auth)

Total: 56 tests
```

Run them with: `bundle exec rspec`
