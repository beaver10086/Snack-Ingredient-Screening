import { createRouter, createWebHashHistory } from 'vue-router'

// 侧边导航配置（App.vue 与路由共用）
// 对齐《需求文档 V2.0》：基于开放数据的零食标签结构化与查询系统
export const NAV = [
  { group: null, items: [
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
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表盘' } },
  { path: '/sources', component: () => import('../views/SourcesView.vue'), meta: { title: '数据源与采集管理' } },
  { path: '/products', component: () => import('../views/ProductsView.vue'), meta: { title: '产品检索与对比' } },
  { path: '/ingredients', component: () => import('../views/IngredientsView.vue'), meta: { title: '配料解析与标准化' } },
  { path: '/rules', component: () => import('../views/RulesView.vue'), meta: { title: '添加剂知识与用户关注规则' } },
  { path: '/screening', component: () => import('../views/ScreeningView.vue'), meta: { title: '成分解读与个性化提示' } },
  { path: '/stats', component: () => import('../views/StatsView.vue'), meta: { title: '统计与报告' } },
  { path: '/system', component: () => import('../views/SystemView.vue'), meta: { title: '系统管理' } },
]

export default createRouter({
  history: createWebHashHistory(),
  routes,
})
