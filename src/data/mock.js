/* ============================================================
 * mock.js — 演示数据（后端就绪后由 api/index.js 的真实请求替代）
 * 字段名对齐需求文档第 6 节数据字典（check_run、additive_usage_limit 等）
 * ============================================================ */

export const MOCK = {
  // 仪表盘统计
  stats: {
    productCount: 2146,
    sourceCount: 4,
    ruleCount: 87,
    pendingReview: 23,
    coveredRate: 0.87,          // 配料标准化覆盖率 G3
    lastRun: "2026-10-21 09:30",
  },

  // 数据源（FR-1）
  dataSources: [
    { id: 1, name: "Open Food Facts", type: "开放库", url: "https://world.openfoodfacts.org", method: "API / 数据导出", reliability: 4, active: true, terms: "ODbL 开放授权，官方导出" },
    { id: 2, name: "电商平台（京东/天猫）", type: "电商", url: "https://www.jd.com", method: "网页采集 + OCR", reliability: 3, active: true, terms: "限速 1 次/秒，遵守 robots 协议" },
    { id: 3, name: "品牌官网", type: "官网", url: "-", method: "网页采集", reliability: 5, active: true, terms: "仅采集公开详情页" },
    { id: 4, name: "市场监管抽检公告", type: "抽检公告", url: "https://www.samr.gov.cn", method: "公告 PDF/Excel 解析", reliability: 5, active: true, terms: "官方公开信息" },
  ],

  // 采集任务（FR-1）
  crawlTasks: [
    { id: 101, source: "Open Food Facts", keyword: "薯片/膨化食品", status: "成功", start: "2026-10-21 09:30", ok: 612, fail: 3 },
    { id: 102, source: "电商平台", keyword: "辣条", status: "运行中", start: "2026-10-21 14:00", ok: 158, fail: 12 },
    { id: 103, source: "品牌官网", keyword: "头部品牌清单", status: "成功", start: "2026-10-20 16:20", ok: 240, fail: 0 },
    { id: 104, source: "监管抽检公告", keyword: "2026-Q3 食品抽检", status: "失败", start: "2026-10-19 10:00", ok: 0, fail: 0 },
  ],

  // 产品（FR-6.1 检索）
  products: [
    { id: 1, name: "乐事原味薯片 70g", barcode: "6901234567890", brand: "乐事", category: "膨化食品", gb: "06.03", sources: 3, ingredientCount: 9 },
    { id: 2, name: "卫龙辣条大面筋 106g", barcode: "6920202888888", brand: "卫龙", category: "肉类零食", gb: "08.03", sources: 2, ingredientCount: 12 },
    { id: 3, name: "奥利奥夹心饼干 97g", barcode: "6901668044444", brand: "奥利奥", category: "饼干糕点", gb: "07.01", sources: 3, ingredientCount: 11 },
    { id: 4, name: "旺旺仙贝 50g", barcode: "6920208888888", brand: "旺旺", category: "膨化食品", gb: "06.03", sources: 2, ingredientCount: 8 },
    { id: 5, name: "沃隆每日坚果 25g", barcode: "6971234567890", brand: "沃隆", category: "坚果炒货", gb: "04.05", sources: 2, ingredientCount: 6 },
    { id: 6, name: "大白兔奶糖 114g", barcode: "6901234599999", brand: "大白兔", category: "糖果巧克力", gb: "05.02", sources: 2, ingredientCount: 5 },
  ],

  // 添加剂（FR-3 / ingredient_dict+additive）
  additives: [
    { id: 1, name: "山梨酸钾", ins: "202", cns: "17.004", fn: "防腐剂", products: 486, prohibited: false },
    { id: 2, name: "柠檬黄", ins: "102", cns: "08.006", fn: "着色剂", products: 233, prohibited: false },
    { id: 3, name: "二氧化钛", ins: "171", cns: "08.011", fn: "着色剂", products: 45, prohibited: true, note: "2025 年起撤回许可（示例）" },
    { id: 4, name: "特丁基对苯二酚（TBHQ）", ins: "319", cns: "04.007", fn: "抗氧化剂", products: 312, prohibited: false },
    { id: 5, name: "三氯蔗糖", ins: "955", cns: "19.016", fn: "甜味剂", products: 178, prohibited: false },
    { id: 6, name: "单硬脂酸甘油酯", ins: "471", cns: "10.006", fn: "乳化剂", products: 398, prohibited: false },
  ],

  // 待人工确认队列（FR-3.6）
  pendingIngredients: [
    { raw: "食用香精香料", times: 132, guess: "食用香精" },
    { raw: "5'-呈味核苷酸二钠", times: 88, guess: "呈味核苷酸二钠" },
    { raw: "脱氢乙酸钠", times: 41, guess: "脱氢乙酸（及其钠盐）" },
    { raw: "酵母抽提物", times: 35, guess: "酵母提取物" },
  ],

  // 法规（FR-4.1）
  regulations: [
    { id: 1, name: "食品安全国家标准 食品添加剂使用标准", no: "GB 2760-2024", publish: "2024-03-12", effective: "2025-02-08", status: "现行" },
    { id: 2, name: "食品安全国家标准 预包装食品标签通则", no: "GB 7718-2025", publish: "2025-03-27", effective: "2027-03-16", status: "即将实施" },
    { id: 3, name: "食品安全国家标准 预包装食品营养标签通则", no: "GB 28050-2025", publish: "2025-03-27", effective: "2027-03-16", status: "即将实施" },
  ],

  // 规则（FR-4.2，R1–R6）
  rules: [
    { id: 1, type: "R1", typeDesc: "禁用/非法物质", reg: "公告 2025 年第 2 号", clause: "名单全文", severity: "违规", desc: "配料命中禁用/非食用物质名单", active: true },
    { id: 2, type: "R2", typeDesc: "未许可物质", reg: "GB 2760-2024", clause: "表 A.1", severity: "违规", desc: "添加剂未列入允许使用名单", active: true },
    { id: 3, type: "R3", typeDesc: "使用范围", reg: "GB 2760-2024", clause: "表 A.1", severity: "疑似", desc: "添加剂不得用于该食品分类号", active: true },
    { id: 4, type: "R4", typeDesc: "最大使用量", reg: "GB 2760-2024", clause: "表 A.1", severity: "疑似", desc: "检出值 > 最大使用量（需含量数据）", active: true },
    { id: 5, type: "R5", typeDesc: "复配限制", reg: "GB 2760-2024", clause: "A.2", severity: "疑似", desc: "同类防腐剂用量比例之和 ≤ 1", active: true },
    { id: 6, type: "R6", typeDesc: "标签标注", reg: "GB 7718-2025", clause: "4.1 / 4.3", severity: "提示", desc: "配料顺序、添加剂标示形式、致敏提示、营养标签核心项", active: true },
  ],

  // 使用限量示例（FR-4 additive_usage_limit）
  usageLimits: [
    { additive: "山梨酸钾", gb: "06.03 谷类膨化食品", max: 0.075, unit: "g/kg" },
    { additive: "柠檬黄", gb: "06.03 谷类膨化食品", max: 0.1, unit: "g/kg" },
    { additive: "TBHQ", gb: "06.03 谷类膨化食品", max: 0.2, unit: "g/kg" },
    { additive: "三氯蔗糖", gb: "07.01 饼干", max: 0.45, unit: "g/kg" },
  ],

  // 筛查批次（FR-5）
  checkRuns: [
    { id: 31, time: "2026-10-21 09:30", scope: "全量 2146 件", version: "v1.3", total: 2146, hits: 186 },
    { id: 30, time: "2026-10-18 20:15", scope: "全量 2090 件", version: "v1.2", total: 2090, hits: 194 },
    { id: 29, time: "2026-10-15 14:00", scope: "膨化食品增量", version: "v1.2", total: 320, hits: 37 },
  ],

  // 筛查结果（FR-5 / FR-6.3）
  results: [
    { id: 9001, product: "某品牌着色糖豆 80g", problem: "不合规配料", severity: "违规", rule: "R1 禁用物质", evidence: "配料表含「二氧化钛」", detail: "检出值 - / 限值 -", review: "未复核" },
    { id: 9002, product: "某辣条 106g", problem: "添加剂使用", severity: "疑似", rule: "R3 使用范围", evidence: "脱氢乙酸钠用于 08.03（示例数据）", detail: "检出值 - / 限值 -", review: "未复核" },
    { id: 9003, product: "某薯片 70g", problem: "添加剂使用", severity: "违规", rule: "R4 最大使用量", evidence: "抽检检出 TBHQ 0.31 g/kg", detail: "检出 0.31 / 限值 0.20", review: "确认" },
    { id: 9004, product: "某夹心饼干 97g", problem: "标签标注", severity: "提示", rule: "R6 标签标注", evidence: "强调「全麦」但未标注含量", detail: "-", review: "未复核" },
    { id: 9005, product: "某果冻 200g", problem: "标签标注", severity: "疑似", rule: "R6 标签标注", evidence: "着色剂未以「着色剂（xx）」形式标示", detail: "-", review: "误报" },
  ],

  // 统计（FR-7）
  statsCharts: {
    problemType: [
      { label: "不合规配料", value: 42, color: "#dc2626" },
      { label: "添加剂使用", value: 96, color: "#d97706" },
      { label: "标签标注", value: 48, color: "#2563eb" },
    ],
    byCategory: [
      { label: "肉类零食", pct: 31 }, { label: "膨化食品", pct: 26 },
      { label: "糖果巧克力", pct: 18 }, { label: "饼干糕点", pct: 14 },
      { label: "果干蜜饯", pct: 7 }, { label: "坚果炒货", pct: 4 },
    ],
    topAdditives: [
      { label: "山梨酸钾", count: 486 }, { label: "单甘酯", count: 398 },
      { label: "TBHQ", count: 312 }, { label: "柠檬黄", count: 233 },
      { label: "三氯蔗糖", count: 178 }, { label: "二氧化钛", count: 45 },
    ],
  },

  // 系统管理（FR-8）
  users: [
    { id: 1, name: "admin", role: "管理员", status: "正常" },
    { id: 2, name: "data_ops", role: "数据维护员", status: "正常" },
    { id: 3, name: "analyst", role: "分析员（只读）", status: "正常" },
  ],
  logs: [
    { time: "2026-10-21 14:00", user: "data_ops", action: "创建采集任务 #102", target: "crawl_task" },
    { time: "2026-10-21 09:30", user: "admin", action: "触发全量筛查 run#31", target: "check_run" },
    { time: "2026-10-20 16:40", user: "data_ops", action: "规则 v1.3 启用 R4 检查", target: "check_rule" },
    { time: "2026-10-20 10:12", user: "analyst", action: "导出筛查结果 CSV", target: "check_result" },
  ],
};
