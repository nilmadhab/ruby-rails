import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Users from '../views/Users.vue'
import Categories from '../views/Categories.vue'
import Posts from '../views/Posts.vue'
import PostDetail from '../views/PostDetail.vue'
import NewPost from '../views/NewPost.vue'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/login', name: 'Login', component: Login, meta: { guest: true } },
  { path: '/register', name: 'Register', component: Register, meta: { guest: true } },
  { path: '/users', name: 'Users', component: Users },
  { path: '/categories', name: 'Categories', component: Categories },
  { path: '/posts', name: 'Posts', component: Posts },
  { path: '/posts/new', name: 'NewPost', component: NewPost, meta: { requiresAuth: true } },
  { path: '/posts/:id', name: 'PostDetail', component: PostDetail },
  { path: '/posts/:id/edit', name: 'EditPost', component: NewPost, meta: { requiresAuth: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')

  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.meta.guest && token) {
    next('/')
  } else {
    next()
  }
})

export default router
