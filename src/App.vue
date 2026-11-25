<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { NAV } from './router'

const route = useRoute()
const router = useRouter()

// 登录状态用 localStorage 模拟，接入数据库后改为后端会话校验
const LOGIN_KEY = 'snack_admin_logged'
const loggedIn = ref(false)
const showLogin = ref(false)
const loginUser = ref('')
const loginPass = ref('')
const loginError = ref('')

onMounted(() => {
  loggedIn.value = localStorage.getItem(LOGIN_KEY) === '1'
})

const pageTitle = computed(() => route.meta.title || '仪表盘')

function doLogin() {
  if (loginUser.value.trim() === 'analyst' && loginPass.value === '123456') {
    loggedIn.value = true
    localStorage.setItem(LOGIN_KEY, '1')
    showLogin.value = false
    loginError.value = ''
    loginUser.value = ''
    loginPass.value = ''
    router.push('/dashboard')
  } else {
    loginError.value = '账号或密码不正确（演示账号：analyst / 123456）'
  }
}

function doLogout() {
  loggedIn.value = false
  localStorage.removeItem(LOGIN_KEY)
  router.push('/')
}
</script>

<template>
  <!-- ============ 访客网站：打开即查询，不标注"前台" ============ -->
  <div v-if="!loggedIn" class="public-site">
    <header class="public-header">
      <div class="public-header-inner">
        <router-link to="/" class="public-brand">
          <span class="public-brand-icon">🍬</span>
          <span>零食标签数据与查询系统</span>
        </router-link>
        <nav class="public-nav">
          <router-link to="/" class="public-nav-link" :class="{ active: route.path === '/' || route.path === '/filter' }">按需求筛选</router-link>
        </nav>
        <button class="btn-login" @click="showLogin = true">分析员登录</button>
      </div>
    </header>

    <main class="public-main">
      <router-view />
    </main>

    <footer class="public-footer">
      数据来自公开渠道，仅供课程研究 · 客观信息呈现，不构成合规判定或健康建议
    </footer>
  </div>

  <!-- ============ 管理后台：分析员登录后可见 ============ -->
  <div v-else class="layout">
    <aside class="sidebar">
      <div class="logo">
        <span class="logo-icon">🍬</span>
        <div>
          <div class="logo-title">零食标签数据与查询系统</div>
        </div>
      </div>
      <nav class="nav">
        <template v-for="(group, gi) in NAV" :key="gi">
          <div v-if="group.group" class="nav-group">{{ group.group }}</div>
          <router-link
            v-for="item in group.items"
            :key="item.path"
            :to="item.path"
            class="nav-item"
            :class="{ active: route.path === item.path }"
          >
            {{ item.icon }} {{ item.title }}
          </router-link>
        </template>
      </nav>
      <div class="sidebar-footer">数据来自公开渠道 · 仅供课程研究<br>客观信息呈现 · 不构成合规判定</div>
    </aside>

    <main class="main">
      <header class="topbar">
        <h1>{{ pageTitle }}</h1>
        <div class="topbar-right">
          <span class="user-badge">👤 分析员</span>
          <button class="btn-logout" @click="doLogout">退出登录</button>
        </div>
      </header>
      <div class="content">
        <router-view />
      </div>
    </main>
  </div>

  <!-- ============ 登录弹窗 ============ -->
  <div v-if="showLogin" class="modal-mask" @click.self="showLogin = false">
    <div class="modal">
      <div class="modal-title">分析员登录</div>
      <div class="modal-sub">登录后进入数据管理后台</div>
      <input v-model="loginUser" type="text" placeholder="账号" @keyup.enter="doLogin">
      <input v-model="loginPass" type="password" placeholder="密码" @keyup.enter="doLogin">
      <div v-if="loginError" class="modal-error">{{ loginError }}</div>
      <div class="modal-actions">
        <button class="btn" @click="showLogin = false">取消</button>
        <button class="btn btn-primary" @click="doLogin">登录</button>
      </div>
      <div class="modal-hint">演示账号：analyst　密码：123456（本阶段前端模拟，待接入数据库校验）</div>
    </div>
  </div>
</template>
