/* ============================================================
 * api/index.js — 数据访问层
 *
 * 现状：直接返回 mock 演示数据（Promise.resolve）。
 * 后端就绪后：将各函数体替换为 axios 真实请求，视图层无需改动。
 *   例如：getProducts: (params) => http.get('/api/products', { params })
 * ============================================================ */
import axios from 'axios'
import { MOCK } from '../data/mock.js'

export const http = axios.create({
  baseURL: '/api',   // 对应 vite.config.js 中的 proxy 配置
  timeout: 10000,
})

// 仪表盘统计
export const getStats = () => Promise.resolve(MOCK.stats)

// FR-1 数据源与采集
export const getDataSources = () => Promise.resolve(MOCK.dataSources)
export const getCrawlTasks = () => Promise.resolve(MOCK.crawlTasks)

// FR-6 产品检索
export const getProducts = () => Promise.resolve(MOCK.products)

// FR-3 配料与添加剂
export const getAdditives = () => Promise.resolve(MOCK.additives)
export const getPendingIngredients = () => Promise.resolve(MOCK.pendingIngredients)

// FR-4 法规与规则库
export const getRegulations = () => Promise.resolve(MOCK.regulations)
export const getRules = () => Promise.resolve(MOCK.rules)
export const getUsageLimits = () => Promise.resolve(MOCK.usageLimits)

// FR-5 合规筛查
export const getCheckRuns = () => Promise.resolve(MOCK.checkRuns)
export const getCheckResults = () => Promise.resolve(MOCK.results)

// FR-7 统计
export const getStatsCharts = () => Promise.resolve(MOCK.statsCharts)

// FR-8 系统管理
export const getUsers = () => Promise.resolve(MOCK.users)
export const getLogs = () => Promise.resolve(MOCK.logs)
