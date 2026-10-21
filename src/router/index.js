import { createRouter, createWebHashHistory } from 'vue-router'

// 侧边导航配置（App.vue 与路由共用）
export const NAV = [
  { group: null, items: [
    { path: '/dashboard', title: '仪表盘', icon: '📊' },
  ]},
  { group: '数据层', items: [
    { path: '/sources', title: '数据源与采集', icon: '🌐' },
    { path: '/products', title: '产品检索', icon: '🛒' },
    { path: '/ingredients', title: '配料与添加剂', icon: '🧪' },
  ]},
  { group: '规则层', items: [
    { path: '/rules', title: '法规与规则库', icon: '📖' },
    { path: '/screening', title: '合规筛查', icon: '🔍' },
  ]},
  { group: '分析层', items: [
    { path: '/stats', title: '统计与报告', icon: '📈' },
    { path: '/system', title: '系统管理', icon: '⚙️' },
  ]},
]

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表盘' } },
  { path: '/sources', component: () => import('../views/SourcesView.vue'), meta: { title: '数据源与采集管理' } },
  { path: '/products', component: () => import('../views/ProductsView.vue'), meta: { title: '产品检索' } },
  { path: '/ingredients', component: () => import('../views/IngredientsView.vue'), meta: { title: '配料与添加剂' } },
  { path: '/rules', component: () => import('../views/RulesView.vue'), meta: { title: '法规与规则库' } },
  { path: '/screening', component: () => import('../views/ScreeningView.vue'), meta: { title: '合规筛查' } },
  { path: '/stats', component: () => import('../views/StatsView.vue'), meta: { title: '统计与报告' } },
  { path: '/system', component: () => import('../views/SystemView.vue'), meta: { title: '系统管理' } },
]

export default createRouter({
  history: createWebHashHistory(),
  routes,
})
