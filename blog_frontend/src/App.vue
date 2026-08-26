<template>
  <div id="app">
    <nav class="navbar">
      <div class="brand">
        <router-link to="/">Blog</router-link>
      </div>
      <ul class="nav-links">
        <li><router-link to="/">Dashboard</router-link></li>
        <li><router-link to="/posts">Posts</router-link></li>
        <li><router-link to="/categories">Categories</router-link></li>
      </ul>
      <div class="auth-links">
        <template v-if="isAuthenticated">
          <span class="user-name">{{ user?.name }}</span>
          <button @click="handleLogout" class="logout-btn">Logout</button>
        </template>
        <template v-else>
          <router-link to="/login" class="auth-link">Login</router-link>
          <router-link to="/register" class="auth-link register">Register</router-link>
        </template>
      </div>
    </nav>
    <main class="container">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuth } from './stores/auth'

const router = useRouter()
const { user, isAuthenticated, logout } = useAuth()

const handleLogout = () => {
  logout()
  router.push('/login')
}
</script>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f0f2f5;
  color: #333;
}

#app {
  min-height: 100vh;
}

.navbar {
  background: #fff;
  padding: 15px 30px;
  display: flex;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.brand a {
  font-size: 1.5em;
  font-weight: bold;
  color: #42b883;
  text-decoration: none;
}

.nav-links {
  display: flex;
  list-style: none;
  margin-left: 40px;
  gap: 25px;
}

.nav-links a {
  text-decoration: none;
  color: #666;
  font-weight: 500;
  transition: color 0.2s;
}

.nav-links a:hover,
.nav-links a.router-link-active {
  color: #42b883;
}

.auth-links {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 15px;
}

.user-name {
  color: #666;
  font-weight: 500;
}

.logout-btn {
  background: none;
  border: 1px solid #e74c3c;
  color: #e74c3c;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9em;
}

.logout-btn:hover {
  background: #e74c3c;
  color: white;
}

.auth-link {
  text-decoration: none;
  color: #666;
  font-weight: 500;
}

.auth-link:hover {
  color: #42b883;
}

.auth-link.register {
  background: #42b883;
  color: white;
  padding: 8px 16px;
  border-radius: 4px;
}

.auth-link.register:hover {
  background: #3aa876;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}
</style>
