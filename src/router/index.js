import { createRouter, createWebHashHistory } from 'vue-router'

// 侧边导航配置（App.vue 与路由共用）
// 对齐《需求文档 V2.2》：按使用者分区 —— 消费者前台应用区 / 后台数据区
export const NAV = [
  { group: '消费者前台应用区', items: [
    { path: '/filter', title: '帮我筛选', icon: '🧾', zone: 'consumer' },
  ]},
  { group: '后台数据区', items: [
    { path: '/dashboard', title: '仪表盘', icon: '📊', zone: 'admin' },
  ]},
  { group: '后台 · 数据层', items: [
    { path: '/sources', title: '数据源与采集', icon: '🌐', zone: 'admin' },
    { path: '/products', title: '产品检索与对比', icon: '🛒', zone: 'admin' },
    { path: '/ingredients', title: '配料标准化', icon: '🧪', zone: 'admin' },
  ]},
  { group: '后台 · 知识与解读层', items: [
    { path: '/rules', title: '知识与关注规则', icon: '📚', zone: 'admin' },
    { path: '/screening', title: '成分解读', icon: '💡', zone: 'admin' },
  ]},
  { group: '后台 · 分析层', items: [
    { path: '/stats', title: '统计与报告', icon: '📈', zone: 'admin' },
    { path: '/system', title: '系统管理', icon: '⚙️', zone: 'admin' },
  ]},
]

const routes = [
  { path: '/', redirect: '/filter' },   // V2.2：默认进入消费者前台应用区
  { path: '/filter', component: () => import('../views/FilterView.vue'), meta: { title: '帮我筛选', zone: 'consumer' } },
  { path: '/dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表盘', zone: 'admin' } },
  { path: '/sources', component: () => import('../views/SourcesView.vue'), meta: { title: '数据源与采集管理', zone: 'admin' } },
  { path: '/products', component: () => import('../views/ProductsView.vue'), meta: { title: '产品检索与对比', zone: 'admin' } },
  { path: '/ingredients', component: () => import('../views/IngredientsView.vue'), meta: { title: '配料解析与标准化', zone: 'admin' } },
  { path: '/rules', component: () => import('../views/RulesView.vue'), meta: { title: '添加剂知识与用户关注规则', zone: 'admin' } },
  { path: '/screening', component: () => import('../views/ScreeningView.vue'), meta: { title: '成分解读与个性化提示', zone: 'admin' } },
  { path: '/stats', component: () => import('../views/StatsView.vue'), meta: { title: '统计与报告', zone: 'admin' } },
  { path: '/system', component: () => import('../views/SystemView.vue'), meta: { title: '系统管理', zone: 'admin' } },
]

export default createRouter({
  history: createWebHashHistory(),
  routes,
})
