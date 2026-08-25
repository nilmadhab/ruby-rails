import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:3000/api/v1',
  headers: {
    'Content-Type': 'application/json'
  }
})

export const userService = {
  getAll: () => api.get('/users'),
  get: (id) => api.get(`/users/${id}`),
  create: (data) => api.post('/users', { user: data }),
  update: (id, data) => api.patch(`/users/${id}`, { user: data }),
  delete: (id) => api.delete(`/users/${id}`)
}

export const categoryService = {
  getAll: () => api.get('/categories'),
  get: (id) => api.get(`/categories/${id}`),
  create: (data) => api.post('/categories', { category: data }),
  update: (id, data) => api.patch(`/categories/${id}`, { category: data }),
  delete: (id) => api.delete(`/categories/${id}`)
}

export const postService = {
  getAll: () => api.get('/posts'),
  get: (id) => api.get(`/posts/${id}`),
  create: (data) => api.post('/posts', { post: data }),
  update: (id, data) => api.patch(`/posts/${id}`, { post: data }),
  delete: (id) => api.delete(`/posts/${id}`)
}

export default api
