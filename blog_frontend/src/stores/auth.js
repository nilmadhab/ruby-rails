import { ref, computed } from 'vue'
import { authService } from '../services/api'

const user = ref(JSON.parse(localStorage.getItem('user')))
const token = ref(localStorage.getItem('token'))

export const useAuth = () => {
  const isAuthenticated = computed(() => !!token.value)

  const login = async (email, password) => {
    const response = await authService.login({ email, password })
    token.value = response.data.token
    user.value = response.data.user
    localStorage.setItem('token', response.data.token)
    localStorage.setItem('user', JSON.stringify(response.data.user))
    return response.data
  }

  const register = async (name, email, password) => {
    const response = await authService.register({ name, email, password })
    token.value = response.data.token
    user.value = response.data.user
    localStorage.setItem('token', response.data.token)
    localStorage.setItem('user', JSON.stringify(response.data.user))
    return response.data
  }

  const logout = () => {
    authService.logout()
    token.value = null
    user.value = null
  }

  return {
    user,
    token,
    isAuthenticated,
    login,
    register,
    logout
  }
}
