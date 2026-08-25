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
  </div>
  <div v-else class="loading">Loading...</div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { postService } from '../services/api'

const route = useRoute()
const router = useRouter()
const post = ref(null)

const loadPost = async () => {
  const res = await postService.get(route.params.id)
  post.value = res.data
}

const deletePost = async () => {
  if (confirm('Delete this post?')) {
    await postService.delete(route.params.id)
    router.push('/posts')
  }
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
</style>
