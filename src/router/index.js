import { createRouter, createWebHashHistory } from 'vue-router'

// 后台侧边导航（仅分析员登录后可见）
// 对齐《需求文档 V2.2》：后台数据区 FR-1~FR-8
export const NAV = [
  { group: '概览', items: [
    { path: '/dashboard', title: '仪表盘', icon: '📊' },
  ]},
  { group: '数据层', items: [
    { path: '/sources', title: '数据源与采集', icon: '🌐' },
    { path: '/products', title: '产品检索与对比', icon: '🛒' },
    { path: '/ingredients', title: '配料标准化', icon: '🧪' },
  ]},
  { group: '知识与解读层', items: [
    { path: '/rules', title: '知识与关注规则', icon: '📚' },
    { path: '/screening', title: '成分解读', icon: '💡' },
  ]},
  { group: '分析层', items: [
    { path: '/stats', title: '统计与报告', icon: '📈' },
    { path: '/system', title: '系统管理', icon: '⚙️' },
  ]},
]

const routes = [
  { path: '/', redirect: '/filter' },
  // 访客查询页（无需登录）
  { path: '/filter', component: () => import('../views/FilterView.vue'), meta: { title: '按需求筛选', public: true } },
  // 后台页面（需分析员登录）
  { path: '/dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表盘', admin: true } },
  { path: '/sources', component: () => import('../views/SourcesView.vue'), meta: { title: '数据源与采集管理', admin: true } },
  { path: '/products', component: () => import('../views/ProductsView.vue'), meta: { title: '产品检索与对比', admin: true } },
  { path: '/ingredients', component: () => import('../views/IngredientsView.vue'), meta: { title: '配料解析与标准化', admin: true } },
  { path: '/rules', component: () => import('../views/RulesView.vue'), meta: { title: '添加剂知识与用户关注规则', admin: true } },
  { path: '/screening', component: () => import('../views/ScreeningView.vue'), meta: { title: '成分解读与个性化提示', admin: true } },
  { path: '/stats', component: () => import('../views/StatsView.vue'), meta: { title: '统计与报告', admin: true } },
  { path: '/system', component: () => import('../views/SystemView.vue'), meta: { title: '系统管理', admin: true } },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

// 访问控制（前端模拟；接入数据库后由后端会话判定）
router.beforeEach((to, from, next) => {
  const loggedIn = localStorage.getItem('snack_admin_logged') === '1'
  if (to.meta.admin && !loggedIn) {
    next('/filter')
  } else {
    next()
  }
})

export default router
