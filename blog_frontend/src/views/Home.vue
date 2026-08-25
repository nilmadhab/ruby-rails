<template>
  <div class="home">
    <h1>Blog Dashboard</h1>
    <div class="stats">
      <div class="stat-card">
        <h3>{{ users.length }}</h3>
        <p>Users</p>
      </div>
      <div class="stat-card">
        <h3>{{ categories.length }}</h3>
        <p>Categories</p>
      </div>
      <div class="stat-card">
        <h3>{{ posts.length }}</h3>
        <p>Posts</p>
      </div>
    </div>
    <div class="recent-posts">
      <h2>Recent Posts</h2>
      <div v-if="posts.length === 0" class="empty">No posts yet</div>
      <div v-else class="post-list">
        <div v-for="post in posts.slice(0, 5)" :key="post.id" class="post-item">
          <router-link :to="`/posts/${post.id}`">
            <h3>{{ post.title }}</h3>
          </router-link>
          <p class="meta">By {{ post.user?.name }} in {{ post.category?.name }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { userService, categoryService, postService } from '../services/api'

const users = ref([])
const categories = ref([])
const posts = ref([])

onMounted(async () => {
  const [usersRes, categoriesRes, postsRes] = await Promise.all([
    userService.getAll(),
    categoryService.getAll(),
    postService.getAll()
  ])
  users.value = usersRes.data
  categories.value = categoriesRes.data
  posts.value = postsRes.data
})
</script>

<style scoped>
.home { padding: 20px; }
.stats { display: flex; gap: 20px; margin-bottom: 30px; }
.stat-card {
  background: #f5f5f5;
  padding: 20px 40px;
  border-radius: 8px;
  text-align: center;
}
.stat-card h3 { font-size: 2em; margin: 0; color: #42b883; }
.stat-card p { margin: 5px 0 0; color: #666; }
.recent-posts h2 { margin-bottom: 15px; }
.post-item {
  padding: 15px;
  border-bottom: 1px solid #eee;
}
.post-item h3 { margin: 0 0 5px; }
.post-item a { color: #42b883; text-decoration: none; }
.meta { color: #888; font-size: 0.9em; margin: 0; }
.empty { color: #888; }
</style>
