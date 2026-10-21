<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { NAV } from './router'

const route = useRoute()
const pageTitle = computed(() => route.meta.title || '仪表盘')
</script>

<template>
  <div class="layout">
    <!-- 侧边栏 -->
    <aside class="sidebar">
      <div class="logo">
        <span class="logo-icon">🍬</span>
        <div>
          <div class="logo-title">零食配料筛查系统</div>
          <div class="logo-sub">高级数据库 · 课程设计</div>
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
      <div class="sidebar-footer">数据仅用于课程研究<br>不构成违法定性</div>
    </aside>

    <!-- 主内容区 -->
    <main class="main">
      <header class="topbar">
        <h1>{{ pageTitle }}</h1>
        <div class="topbar-right"><span class="user-badge">👤 分析员</span></div>
      </header>
      <div class="content">
        <router-view />
      </div>
    </main>
  </div>
</template>
