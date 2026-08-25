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
        <li><router-link to="/users">Users</router-link></li>
      </ul>
    </nav>
    <main class="container">
      <router-view />
    </main>
  </div>
</template>

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

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}
</style>
