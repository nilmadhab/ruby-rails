import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Users from '../views/Users.vue'
import Categories from '../views/Categories.vue'
import Posts from '../views/Posts.vue'
import PostDetail from '../views/PostDetail.vue'
import NewPost from '../views/NewPost.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/users', name: 'Users', component: Users },
  { path: '/categories', name: 'Categories', component: Categories },
  { path: '/posts', name: 'Posts', component: Posts },
  { path: '/posts/new', name: 'NewPost', component: NewPost },
  { path: '/posts/:id', name: 'PostDetail', component: PostDetail },
  { path: '/posts/:id/edit', name: 'EditPost', component: NewPost }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
