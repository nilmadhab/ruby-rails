# Comment Feature Implementation Guide

Build a comment system where authenticated users can comment on posts.

---

## Backend (Rails)

### Step 1: Generate the Comment Model

Generate a Comment model with these fields:
- `body` (text) - the comment content
- `user_id` (references) - who wrote the comment
- `post_id` (references) - which post it belongs to

**Command to use:**
```bash
bin/rails generate model Comment body:text user:references post:references
```

### Step 2: Run the Migration

```bash
bin/rails db:migrate
```

### Step 3: Set Up Model Associations

Edit these files to add associations:

**app/models/comment.rb**
- Add `belongs_to :user`
- Add `belongs_to :post`
- Add validation for `body` presence

**app/models/user.rb**
- Add `has_many :comments, dependent: :destroy`

**app/models/post.rb**
- Add `has_many :comments, dependent: :destroy`

### Step 4: Generate the Comments Controller

```bash
bin/rails generate controller Api::V1::Comments --skip-routes
```

### Step 5: Implement Controller Actions

**app/controllers/api/v1/comments_controller.rb**

Implement these actions:

| Action | Auth Required | Description |
|--------|---------------|-------------|
| `index` | No | List all comments for a post |
| `create` | Yes | Create comment (use `current_user`) |
| `update` | Yes | Update own comment only |
| `destroy` | Yes | Delete own comment only |

**Hints:**
- Use `skip_before_action :authenticate_request, only: [:index]`
- Nest comments under posts: find post first, then work with its comments
- Check `comment.user_id == current_user.id` before update/destroy

### Step 6: Add Routes

**config/routes.rb**

Add nested routes for comments under posts:

```ruby
resources :posts do
  resources :comments, only: [:index, :create, :update, :destroy]
end
```

This creates:
- `GET /api/v1/posts/:post_id/comments`
- `POST /api/v1/posts/:post_id/comments`
- `PATCH /api/v1/posts/:post_id/comments/:id`
- `DELETE /api/v1/posts/:post_id/comments/:id`

### Step 7: Update Posts Controller (Optional)

Modify the `show` action in PostsController to include comments:

```ruby
render json: @post, include: [:user, :category, :comments]
```

---

## Frontend (Vue)

### Step 8: Add Comment Service

**src/services/api.js**

Add a new `commentService` object with methods:
- `getAll(postId)` - GET `/posts/${postId}/comments`
- `create(postId, data)` - POST `/posts/${postId}/comments`
- `update(postId, id, data)` - PATCH `/posts/${postId}/comments/${id}`
- `delete(postId, id)` - DELETE `/posts/${postId}/comments/${id}`

### Step 9: Create Comments Component

**src/components/Comments.vue**

Build a component that:
- Receives `postId` as a prop
- Fetches and displays comments on mount
- Shows a form to add new comment (only if logged in)
- Shows edit/delete buttons (only on own comments)

### Step 10: Integrate into PostDetail

**src/views/PostDetail.vue**

- Import and use the Comments component
- Pass the post ID as a prop

---

## Testing Your Implementation

### Test with curl:

```bash
# Get comments for a post
curl http://localhost:3000/api/v1/posts/1/comments

# Create a comment (requires auth token)
curl -X POST http://localhost:3000/api/v1/posts/1/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"comment": {"body": "Great post!"}}'

# Update a comment
curl -X PATCH http://localhost:3000/api/v1/posts/1/comments/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"comment": {"body": "Updated comment"}}'

# Delete a comment
curl -X DELETE http://localhost:3000/api/v1/posts/1/comments/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Bonus Challenges

1. **Pagination** - Add pagination to comments using `limit` and `offset`
2. **Nested Replies** - Add `parent_id` to allow replies to comments
3. **Like Comments** - Create a CommentLike model for upvoting
4. **Real-time Updates** - Use ActionCable for live comment updates

---

## Useful Rails Commands

```bash
# Check your routes
bin/rails routes | grep comment

# Open Rails console to test models
bin/rails console
```

---

## Working with Comments in Rails Console

Open the console:
```bash
bin/rails console
```

### Create a Comment

```ruby
# Find a user and a post first
user = User.first
post = Post.first

# Method 1: Create directly
comment = Comment.create(body: "This is my comment!", user: user, post: post)

# Method 2: Build through association
comment = post.comments.create(body: "Another comment", user: user)

# Method 3: Build and save separately
comment = post.comments.build(body: "Draft comment", user: user)
comment.save
```

### Read Comments

```ruby
# Get all comments
Comment.all

# Get comments for a specific post
post = Post.first
post.comments

# Get comments by a specific user
user = User.first
user.comments

# Get comment with user and post info
Comment.includes(:user, :post).first
```

### Update a Comment

```ruby
# Find the comment
comment = Comment.find(1)

# Update it
comment.update(body: "Updated comment text")

# Or update attributes individually
comment.body = "New text"
comment.save
```

### Delete a Comment

```ruby
# Find and delete
comment = Comment.find(1)
comment.destroy

# Delete all comments for a post
post = Post.first
post.comments.destroy_all
```

### Useful Queries

```ruby
# Count comments on a post
post.comments.count

# Get latest 5 comments
Comment.order(created_at: :desc).limit(5)

# Find comments containing specific text
Comment.where("body LIKE ?", "%great%")

# Get all posts with their comment counts
Post.left_joins(:comments).group(:id).select("posts.*, COUNT(comments.id) as comments_count")
```

### Check Validations

```ruby
# Try creating an invalid comment
comment = Comment.new(body: "")
comment.valid?        # => false
comment.errors.full_messages  # => ["Body can't be blank"]
```

---

Good luck! 🚀
