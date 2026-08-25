<template>
  <div class="categories">
    <h1>Categories</h1>

    <form @submit.prevent="saveCategory" class="form">
      <input v-model="form.name" placeholder="Category Name" required />
      <button type="submit">{{ editing ? 'Update' : 'Add' }} Category</button>
      <button v-if="editing" type="button" @click="cancelEdit">Cancel</button>
    </form>

    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Posts</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="category in categories" :key="category.id">
          <td>{{ category.name }}</td>
          <td>{{ category.posts?.length || 0 }}</td>
          <td>
            <button @click="editCategory(category)">Edit</button>
            <button @click="deleteCategory(category.id)" class="delete">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { categoryService } from '../services/api'

const categories = ref([])
const form = ref({ name: '' })
const editing = ref(null)

const loadCategories = async () => {
  const res = await categoryService.getAll()
  categories.value = res.data
}

const saveCategory = async () => {
  if (editing.value) {
    await categoryService.update(editing.value, form.value)
  } else {
    await categoryService.create(form.value)
  }
  form.value = { name: '' }
  editing.value = null
  loadCategories()
}

const editCategory = (category) => {
  form.value = { name: category.name }
  editing.value = category.id
}

const cancelEdit = () => {
  form.value = { name: '' }
  editing.value = null
}

const deleteCategory = async (id) => {
  if (confirm('Delete this category?')) {
    await categoryService.delete(id)
    loadCategories()
  }
}

onMounted(loadCategories)
</script>

<style scoped>
.categories { padding: 20px; }
.form { display: flex; gap: 10px; margin-bottom: 20px; }
.form input { padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; flex: 1; max-width: 300px; }
.form button { padding: 8px 16px; background: #42b883; color: white; border: none; border-radius: 4px; cursor: pointer; }
.form button[type="button"] { background: #888; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
th { background: #f5f5f5; }
button { padding: 5px 10px; margin-right: 5px; cursor: pointer; border: none; border-radius: 4px; background: #42b883; color: white; }
button.delete { background: #e74c3c; }
</style>
