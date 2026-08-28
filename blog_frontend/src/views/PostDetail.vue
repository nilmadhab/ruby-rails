<template>
  <div class="post-detail" v-if="post">
    <div class="header">
      <router-link to="/posts" class="back">&larr; Back to Posts</router-link>
    </div>
    <article>
      <div class="category-badge">{{ post.category?.name }}</div>
      <h1>{{ post.title }}</h1>
      <div class="meta">By {{ post.user?.name }}</div>
      <div class="content">{{ post.body }}</div>
    </article>
    <div class="actions">
      <router-link :to="`/posts/${post.id}/edit`" class="btn">Edit Post</router-link>
      <button @click="deletePost" class="btn delete">Delete Post</button>
    </div>

    <!-- Comments Section -->
    <section class="comments-section">
      <h2>Comments ({{ comments.length }})</h2>

      <!-- Add Comment Form -->
      <div v-if="isAuthenticated" class="add-comment">
        <textarea
          v-model="newComment"
          placeholder="Write a comment..."
          rows="3"
        ></textarea>
        <button @click="addComment" :disabled="!newComment.trim() || submitting">
          {{ submitting ? 'Posting...' : 'Post Comment' }}
        </button>
      </div>
      <div v-else class="login-prompt">
        <router-link to="/login">Login</router-link> to add a comment
      </div>

      <!-- Comments List -->
      <div v-if="comments.length === 0" class="no-comments">
        No comments yet. Be the first to comment!
      </div>
      <div v-else class="comments-list">
        <div v-for="comment in comments" :key="comment.id" class="comment">
          <div class="comment-header">
            <strong>{{ comment.user?.name || 'Anonymous' }}</strong>
            <span class="comment-date">{{ formatDate(comment.created_at) }}</span>
          </div>
          <p class="comment-body">{{ comment.body }}</p>
        </div>
      </div>
    </section>
  </div>
  <div v-else class="loading">Loading...</div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { postService, commentService } from '../services/api'
import { useAuth } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const { isAuthenticated } = useAuth()

const post = ref(null)
const newComment = ref('')
const submitting = ref(false)

const comments = computed(() => post.value?.comments || [])

const loadPost = async () => {
  const res = await postService.get(route.params.id)
  post.value = res.data
}

const addComment = async () => {
  if (!newComment.value.trim()) return
  submitting.value = true
  try {
    await commentService.create(route.params.id, { body: newComment.value })
    newComment.value = ''
    await loadPost()
  } catch (e) {
    alert('Failed to add comment')
  } finally {
    submitting.value = false
  }
}

const deletePost = async () => {
  if (confirm('Delete this post?')) {
    await postService.delete(route.params.id)
    router.push('/posts')
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

onMounted(loadPost)
</script>

<style scoped>
.post-detail { padding: 20px; max-width: 800px; margin: 0 auto; }
.back { color: #42b883; text-decoration: none; }
article { margin-top: 20px; }
.category-badge { display: inline-block; background: #42b883; color: white; padding: 5px 12px; border-radius: 4px; font-size: 0.85em; margin-bottom: 10px; }
h1 { margin: 10px 0; font-size: 2em; }
.meta { color: #888; margin-bottom: 20px; }
.content { line-height: 1.8; white-space: pre-wrap; }
.actions { margin-top: 30px; display: flex; gap: 10px; }
.btn { background: #42b883; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; border: none; cursor: pointer; }
.btn.delete { background: #e74c3c; }
.loading { padding: 40px; text-align: center; color: #888; }

/* Comments Section */
.comments-section {
  margin-top: 50px;
  border-top: 1px solid #eee;
  padding-top: 30px;
}
.comments-section h2 {
  margin-bottom: 20px;
}
.add-comment {
  margin-bottom: 25px;
}
.add-comment textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1em;
  resize: vertical;
  margin-bottom: 10px;
  box-sizing: border-box;
}
.add-comment button {
  background: #42b883;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
}
.add-comment button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.login-prompt {
  background: #f5f5f5;
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 20px;
}
.login-prompt a {
  color: #42b883;
}
.no-comments {
  color: #888;
  font-style: italic;
}
.comments-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.comment {
  background: #f9f9f9;
  padding: 15px;
  border-radius: 8px;
}
.comment-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}
.comment-date {
  color: #888;
  font-size: 0.85em;
}
.comment-body {
  margin: 0;
  line-height: 1.5;
}
</style>
