import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:3000/api/v1',
  headers: {
    'Content-Type': 'application/json'
  }
})

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const authService = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  me: () => api.get('/auth/me'),
  logout: () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }
}

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

export const commentService = {
  getAll: (postId) => api.get(`/posts/${postId}/comments`),
  get: (postId, id) => api.get(`/posts/${postId}/comments/${id}`),
  create: (postId, data) => api.post(`/posts/${postId}/comments`, { comment: data }),
  update: (postId, id, data) => api.patch(`/posts/${postId}/comments/${id}`, { comment: data }),
  delete: (postId, id) => api.delete(`/posts/${postId}/comments/${id}`)
}

export default api
