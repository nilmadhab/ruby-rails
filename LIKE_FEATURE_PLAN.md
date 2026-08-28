# Like Feature Implementation Plan

A plan to implement a "like" feature for blog posts.

---

## Overview

Users can like/unlike posts. Each user can only like a post once.

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│  User   │────────▶│  Like   │◀────────│  Post   │
└─────────┘   1:N   └─────────┘   N:1   └─────────┘
                    (join table)
```

---

## Database Design

### Likes Table

| Column | Type | Constraints |
|--------|------|-------------|
| id | bigint | Primary Key |
| user_id | bigint | Foreign Key, NOT NULL |
| post_id | bigint | Foreign Key, NOT NULL |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

**Indexes:**
- Unique index on `[user_id, post_id]` - Prevents duplicate likes
- Index on `post_id` - For counting likes per post

### Migration

```ruby
# db/migrate/XXXXXX_create_likes.rb
class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    add_index :likes, [:user_id, :post_id], unique: true
  end
end
```

---

## Model Layer

### Like Model

```ruby
# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user_id, uniqueness: { scope: :post_id, message: "has already liked this post" }
end
```

### Update User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
end
```

### Update Post Model

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user

  def likes_count
    likes.count
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end
end
```

---

## API Design

### Endpoints

| Action | Method | Endpoint | Auth | Description |
|--------|--------|----------|------|-------------|
| Like | POST | `/api/v1/posts/:post_id/like` | Required | Like a post |
| Unlike | DELETE | `/api/v1/posts/:post_id/like` | Required | Remove like |
| Check | GET | `/api/v1/posts/:post_id/like` | Required | Check if liked |

### Response Formats

**Like/Unlike Response:**
```json
{
  "liked": true,
  "likes_count": 42
}
```

**Post Response (updated):**
```json
{
  "id": 1,
  "title": "My Post",
  "body": "Content...",
  "likes_count": 42,
  "liked_by_current_user": true,
  "user": { "id": 1, "name": "John" },
  "category": { "id": 1, "name": "Tech" }
}
```

---

## Controller Layer

### Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :posts do
      resource :like, only: [:create, :destroy, :show]
    end
  end
end
```

This creates:
- `POST /api/v1/posts/:post_id/like` → `likes#create`
- `DELETE /api/v1/posts/:post_id/like` → `likes#destroy`
- `GET /api/v1/posts/:post_id/like` → `likes#show`

### Likes Controller

```ruby
# app/controllers/api/v1/likes_controller.rb
class Api::V1::LikesController < ApplicationController
  before_action :set_post

  # POST /api/v1/posts/:post_id/like
  def create
    @like = @post.likes.build(user: current_user)

    if @like.save
      render json: like_response(true)
    else
      render json: { error: @like.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/posts/:post_id/like
  def destroy
    @like = @post.likes.find_by(user: current_user)

    if @like&.destroy
      render json: like_response(false)
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end

  # GET /api/v1/posts/:post_id/like
  def show
    liked = @post.liked_by?(current_user)
    render json: like_response(liked)
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def like_response(liked)
    {
      liked: liked,
      likes_count: @post.likes.count
    }
  end
end
```

### Update Posts Controller

Update the `show` and `index` actions to include like information:

```ruby
# In posts_controller.rb

def index
  @posts = Post.includes(:user, :category, :likes).all
  render json: @posts.map { |post| post_with_likes(post) }
end

def show
  render json: post_with_likes(@post)
end

private

def post_with_likes(post)
  post.as_json(include: {
    user: { only: [:id, :name, :email] },
    category: { only: [:id, :name] },
    comments: { include: { user: { only: [:id, :name] } } }
  }).merge(
    likes_count: post.likes.count,
    liked_by_current_user: post.liked_by?(current_user)
  )
end
```

---

## Frontend Changes

### API Service

```javascript
// src/services/api.js
export const likeService = {
  like: (postId) => api.post(`/posts/${postId}/like`),
  unlike: (postId) => api.delete(`/posts/${postId}/like`),
  check: (postId) => api.get(`/posts/${postId}/like`),
}
```

### PostDetail.vue Updates

```vue
<template>
  <!-- Add like button in post detail -->
  <div class="like-section">
    <button @click="toggleLike" :class="{ liked: isLiked }">
      {{ isLiked ? '❤️' : '🤍' }} {{ likesCount }}
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { likeService } from '../services/api'

const isLiked = ref(false)
const likesCount = ref(0)

const toggleLike = async () => {
  if (isLiked.value) {
    await likeService.unlike(postId)
    isLiked.value = false
    likesCount.value--
  } else {
    await likeService.like(postId)
    isLiked.value = true
    likesCount.value++
  }
}
</script>
```

---

## Testing

### Model Specs

```ruby
# spec/models/like_spec.rb
RSpec.describe Like, type: :model do
  describe 'validations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe 'uniqueness' do
    it 'prevents duplicate likes' do
      user = create(:user)
      post = create(:post)
      create(:like, user: user, post: post)

      duplicate = build(:like, user: user, post: post)
      expect(duplicate).not_to be_valid
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/likes_spec.rb
RSpec.describe "Likes API", type: :request do
  let!(:user) { create(:user) }
  let!(:post_record) { create(:post) }

  describe "POST /api/v1/posts/:post_id/like" do
    it "likes a post" do
      expect {
        post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
      }.to change(Like, :count).by(1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['liked']).to be true
      expect(json['likes_count']).to eq(1)
    end

    it "prevents duplicate likes" do
      create(:like, user: user, post: post_record)

      post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/posts/:post_id/like" do
    it "unlikes a post" do
      create(:like, user: user, post: post_record)

      expect {
        delete "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
      }.to change(Like, :count).by(-1)

      json = JSON.parse(response.body)
      expect(json['liked']).to be false
    end
  end
end
```

---

## Implementation Steps

### Step 1: Backend - Database & Model
- [ ] Generate Like model with migration
- [ ] Run migration
- [ ] Add associations to User and Post models
- [ ] Add helper methods (`liked_by?`, `likes_count`)

### Step 2: Backend - API
- [ ] Add routes for like/unlike
- [ ] Create LikesController
- [ ] Update PostsController to include like info

### Step 3: Backend - Testing
- [ ] Create Like factory
- [ ] Write model specs
- [ ] Write request specs
- [ ] Run all tests

### Step 4: Frontend
- [ ] Add like service methods
- [ ] Add like button to PostDetail
- [ ] Add like button to post list
- [ ] Style the like button

---

## Optional Enhancements

### 1. Counter Cache (Performance)

Instead of counting likes each time, cache the count:

```ruby
# Migration
add_column :posts, :likes_count, :integer, default: 0

# Model
class Like < ApplicationRecord
  belongs_to :post, counter_cache: true
end
```

### 2. Who Liked (Show Likers)

```ruby
# GET /api/v1/posts/:post_id/likes
def index
  @likers = @post.likers.limit(10)
  render json: @likers, only: [:id, :name]
end
```

### 3. Like Notifications

Send notification when someone likes your post.

### 4. Like Animation

Add a heart animation on like.

---

## File Changes Summary

| File | Action |
|------|--------|
| `db/migrate/XXX_create_likes.rb` | Create |
| `app/models/like.rb` | Create |
| `app/models/user.rb` | Modify |
| `app/models/post.rb` | Modify |
| `config/routes.rb` | Modify |
| `app/controllers/api/v1/likes_controller.rb` | Create |
| `app/controllers/api/v1/posts_controller.rb` | Modify |
| `spec/factories/likes.rb` | Create |
| `spec/models/like_spec.rb` | Create |
| `spec/requests/likes_spec.rb` | Create |
| `blog_frontend/src/services/api.js` | Modify |
| `blog_frontend/src/views/PostDetail.vue` | Modify |

---

Ready to implement? Let me know!
