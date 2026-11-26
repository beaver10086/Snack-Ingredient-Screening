/* ============================================================
 * api/index.js — 数据访问层
 *
 * 对齐《需求文档 V2.2》：基于开放数据的零食标签结构化与查询系统
 * 现状：直接返回 mock 演示数据（Promise.resolve）。
 * 后端就绪后：将各函数体替换为 axios 真实请求，视图层无需改动。
 *   例如：getProducts: (params) => http.get('/api/products', { params })
 *
 * 注意：V2.0 已移除"合规筛查/违法定性"相关接口，
 *       改为"知识库 + 用户关注规则 + 成分解读"。
 * ============================================================ */
import axios from 'axios'
import { MOCK } from '../data/mock.js'

export const http = axios.create({
  baseURL: '/api',   // 对应 vite.config.js 中的 proxy 配置
  timeout: 10000,
})

// 仪表盘统计
export const getStats = () => Promise.resolve(MOCK.stats)

// FR-1 数据源与采集（V2.0：限速退避 / 原始层留存）
export const getDataSources = () => Promise.resolve(MOCK.dataSources)
export const getCrawlTasks = () => Promise.resolve(MOCK.crawlTasks)

// FR-6 产品检索 / 反向检索
export const getProducts = () => Promise.resolve(MOCK.products)

// FR-3 配料标准化 / 待确认队列
export const getAdditives = () => Promise.resolve(MOCK.additives)
export const getPendingIngredients = () => Promise.resolve(MOCK.pendingIngredients)

// FR-4 知识与用户关注规则（V2.0：替代原法规规则库）
export const getUserRules = () => Promise.resolve(MOCK.userRules)

// FR-5 成分解读与个性化提示（V2.0：替代原合规筛查）
export const getInterpretRuns = () => Promise.resolve(MOCK.interpretRuns)
export const getInterpretResults = () => Promise.resolve(MOCK.results)

// FR-7 统计
export const getStatsCharts = () => Promise.resolve(MOCK.statsCharts)

// FR-8 系统管理
export const getUsers = () => Promise.resolve(MOCK.users)
export const getLogs = () => Promise.resolve(MOCK.logs)
export const getSchedules = () => Promise.resolve(MOCK.schedules)
