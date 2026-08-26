<template>
  <div class="new-post">
    <h1>{{ isEditing ? 'Edit Post' : 'New Post' }}</h1>

    <form @submit.prevent="savePost">
      <div class="form-group">
        <label>Title</label>
        <input v-model="form.title" required placeholder="Post title" />
      </div>

      <div class="form-group">
        <label>Category</label>
        <select v-model="form.category_id" required>
          <option value="">Select category</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
      </div>

      <div class="form-group">
        <label>Content</label>
        <textarea v-model="form.body" required rows="10" placeholder="Write your post..."></textarea>
      </div>

      <div v-if="error" class="error">{{ error }}</div>

      <div class="actions">
        <button type="submit" class="btn" :disabled="loading">
          {{ loading ? 'Saving...' : (isEditing ? 'Update' : 'Create') }} Post
        </button>
        <router-link to="/posts" class="btn cancel">Cancel</router-link>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { postService, categoryService } from '../services/api'

const route = useRoute()
const router = useRouter()

const categories = ref([])
const form = ref({
  title: '',
  body: '',
  category_id: ''
})
const error = ref('')
const loading = ref(false)

const isEditing = computed(() => route.name === 'EditPost')

const loadData = async () => {
  const categoriesRes = await categoryService.getAll()
  categories.value = categoriesRes.data

  if (isEditing.value) {
    const postRes = await postService.get(route.params.id)
    form.value = {
      title: postRes.data.title,
      body: postRes.data.body,
      category_id: postRes.data.category?.id || postRes.data.category_id
    }
  }
}

const savePost = async () => {
  error.value = ''
  loading.value = true
  try {
    if (isEditing.value) {
      await postService.update(route.params.id, form.value)
    } else {
      await postService.create(form.value)
    }
    router.push('/posts')
  } catch (e) {
    error.value = e.response?.data?.error || e.response?.data?.errors?.join(', ') || 'Failed to save post'
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.new-post { padding: 20px; max-width: 600px; margin: 0 auto; }
h1 { margin-bottom: 20px; }
.form-group { margin-bottom: 15px; }
.form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1em;
}
.form-group textarea { resize: vertical; }
.error { color: #e74c3c; margin-bottom: 15px; }
.actions { display: flex; gap: 10px; margin-top: 20px; }
.btn { background: #42b883; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 1em; }
.btn:disabled { opacity: 0.7; cursor: not-allowed; }
.btn.cancel { background: #888; }
</style>
