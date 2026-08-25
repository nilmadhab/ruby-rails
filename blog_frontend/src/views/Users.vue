<template>
  <div class="users">
    <h1>Users</h1>

    <form @submit.prevent="saveUser" class="form">
      <input v-model="form.name" placeholder="Name" required />
      <input v-model="form.email" type="email" placeholder="Email" required />
      <button type="submit">{{ editing ? 'Update' : 'Add' }} User</button>
      <button v-if="editing" type="button" @click="cancelEdit">Cancel</button>
    </form>

    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Email</th>
          <th>Posts</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in users" :key="user.id">
          <td>{{ user.name }}</td>
          <td>{{ user.email }}</td>
          <td>{{ user.posts?.length || 0 }}</td>
          <td>
            <button @click="editUser(user)">Edit</button>
            <button @click="deleteUser(user.id)" class="delete">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { userService } from '../services/api'

const users = ref([])
const form = ref({ name: '', email: '' })
const editing = ref(null)

const loadUsers = async () => {
  const res = await userService.getAll()
  users.value = res.data
}

const saveUser = async () => {
  if (editing.value) {
    await userService.update(editing.value, form.value)
  } else {
    await userService.create(form.value)
  }
  form.value = { name: '', email: '' }
  editing.value = null
  loadUsers()
}

const editUser = (user) => {
  form.value = { name: user.name, email: user.email }
  editing.value = user.id
}

const cancelEdit = () => {
  form.value = { name: '', email: '' }
  editing.value = null
}

const deleteUser = async (id) => {
  if (confirm('Delete this user?')) {
    await userService.delete(id)
    loadUsers()
  }
}

onMounted(loadUsers)
</script>

<style scoped>
.users { padding: 20px; }
.form { display: flex; gap: 10px; margin-bottom: 20px; }
.form input { padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; }
.form button { padding: 8px 16px; background: #42b883; color: white; border: none; border-radius: 4px; cursor: pointer; }
.form button[type="button"] { background: #888; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
th { background: #f5f5f5; }
button { padding: 5px 10px; margin-right: 5px; cursor: pointer; border: none; border-radius: 4px; background: #42b883; color: white; }
button.delete { background: #e74c3c; }
</style>
