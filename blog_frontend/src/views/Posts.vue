<template>
  <div class="posts">
    <div class="header">
      <h1>Posts</h1>
      <router-link to="/posts/new" class="btn">New Post</router-link>
    </div>

    <div v-if="posts.length === 0" class="empty">No posts yet. Create your first post!</div>

    <div v-else class="post-grid">
      <div v-for="post in posts" :key="post.id" class="post-card">
        <div class="category-badge">{{ post.category?.name }}</div>
        <h2>
          <router-link :to="`/posts/${post.id}`">{{ post.title }}</router-link>
        </h2>
        <p class="excerpt">{{ post.body?.substring(0, 150) }}...</p>
        <div class="meta">
          <span>By {{ post.user?.name }}</span>
        </div>
        <div class="actions">
          <router-link :to="`/posts/${post.id}/edit`" class="edit">Edit</router-link>
          <button @click="deletePost(post.id)" class="delete">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { postService } from '../services/api'

const posts = ref([])

const loadPosts = async () => {
  const res = await postService.getAll()
  posts.value = res.data
}

const deletePost = async (id) => {
  if (confirm('Delete this post?')) {
    await postService.delete(id)
    loadPosts()
  }
}

onMounted(loadPosts)
</script>

<style scoped>
.posts { padding: 20px; }
.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.btn { background: #42b883; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; }
.empty { color: #888; text-align: center; padding: 40px; }
.post-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
.post-card { background: #f9f9f9; padding: 20px; border-radius: 8px; position: relative; }
.category-badge { position: absolute; top: 10px; right: 10px; background: #42b883; color: white; padding: 3px 8px; border-radius: 4px; font-size: 0.8em; }
.post-card h2 { margin: 0 0 10px; font-size: 1.2em; }
.post-card h2 a { color: #333; text-decoration: none; }
.post-card h2 a:hover { color: #42b883; }
.excerpt { color: #666; font-size: 0.9em; margin-bottom: 10px; }
.meta { color: #888; font-size: 0.85em; margin-bottom: 10px; }
.actions { display: flex; gap: 10px; }
.actions .edit { color: #42b883; text-decoration: none; }
.actions .delete { background: none; border: none; color: #e74c3c; cursor: pointer; padding: 0; }
</style>
