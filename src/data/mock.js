/* ============================================================
 * mock.js — 演示数据（后端就绪后由 api/index.js 的真实请求替代）
 * 对齐《需求文档 V2.0》：基于开放数据的零食标签结构化与查询系统
 * 字段名对齐 V2.0 第 6 节数据字典，且全部标注数据来源（可追溯 G6）
 * 重要：系统只输出客观事实/知识科普/个人提示，不做违法定性 (NFR-10)
 * ============================================================ */

export const MOCK = {
  // 仪表盘统计（V2.0 第 2.2 节目标）
  stats: {
    productCount: 386,          // G1 目标 300~500，实测 Open Food Facts 中国零食约 180 条 + 多品类累加
    sourceCount: 3,             // Open Food Facts / 抽检公告 / 电商公开页
    ruleCount: 12,              // 用户关注规则条数（非合规规则）
    pendingConfirm: 18,         // 待人工确认配料（FR-3.6）
    coveredRate: 0.82,          // 配料标准化覆盖率 G3 ≥ 80%
    lastRun: '2026-11-25 16:20', // 最近解读批次
    apiLimit: '15 req/min',     // 实测限速，采集器已实现退避
  },

  // 数据源（FR-1 / V2.0 第 5 节，全部为公开网络来源）
  dataSources: [
    {
      id: 1, name: 'Open Food Facts', type: '开放库',
      url: 'https://world.openfoodfacts.org/api/v2/search',
      method: 'API 分页抓取（主源）', reliability: 4, active: true,
      terms: 'ODbL 开放授权 · 实测中国零食约180条 · 限速15req/min · 须署名',
      fields: '条码/名称/品牌/配料原文/添加剂/营养成分',
    },
    {
      id: 2, name: '市场监管总局抽检公告', type: '官方公告',
      url: 'https://www.samr.gov.cn',
      method: '公告附件解析（Excel/PDF）', reliability: 5, active: true,
      terms: '官方公开数据 · 含检出值与标准限值 · 仅作规则验证样本',
      fields: '产品名/检验项目/检出值/标准限值',
    },
    {
      id: 3, name: '电商公开详情页', type: '网页',
      url: 'https://www.jd.com',
      method: '人工核对少量补充', reliability: 3, active: true,
      terms: '仅少量补充(30~50条) · 遵守robots · 不绕反爬 · 不作主力',
      fields: '商品名/品牌/配料表',
    },
  ],

  // 采集任务（FR-1.3 限速退避 / FR-1.5 原始层留存 / FR-1.6 日志）
  crawlTasks: [
    {
      id: 201, source: 'Open Food Facts', keyword: 'en:snacks（膨化食品）',
      status: '成功', start: '2026-11-25 16:00', ok: 180, fail: 3,
      rate: '4 秒/请求', retry: '指数退避 2 次', raw: 'JSON 原样入库',
    },
    {
      id: 202, source: 'Open Food Facts', keyword: 'en:biscuits（饼干糕点）',
      status: '成功', start: '2026-11-25 16:06', ok: 96, fail: 1,
      rate: '4 秒/请求', retry: '指数退避 2 次', raw: 'JSON 原样入库',
    },
    {
      id: 203, source: 'Open Food Facts', keyword: 'en:chocolates（糖果巧克力）',
      status: '运行中', start: '2026-11-25 16:12', ok: 74, fail: 5,
      rate: '4 秒/请求', retry: '遇 503 退避 60 秒', raw: 'JSON 原样入库',
    },
    {
      id: 204, source: '市场监管总局抽检公告', keyword: '2026 食品抽检',
      status: '成功', start: '2026-11-24 10:20', ok: 36, fail: 0,
      rate: '手动解析', retry: '—', raw: '附件原样存档',
    },
  ],

  // 产品（FR-6.1 检索 / FR-6.2 反向检索 / FR-6.3 对比）
  products: [
    {
      id: 1, name: '乐事经典原味薯片 70g', barcode: '7622210449283',
      brand: '乐事', category: '膨化食品', gb: '06.03',
      sources: 2, ingredientCount: 6, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '马铃薯、植物油、经典原味调味料（含5\'-呈味核苷酸二钠）、TBHQ',
      additives: ['TBHQ', '5\'-呈味核苷酸二钠'], allergens: [],
      nutrition: { energy: '548 kcal/100g', fat: '32g', carbs: '53g', sodium: '520mg' },
    },
    {
      id: 2, name: '卫龙辣条大面筋 106g', barcode: '6920202888888',
      brand: '卫龙', category: '肉类零食', gb: '08.03',
      sources: 2, ingredientCount: 12, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '小麦粉、水、植物油、食用盐、白砂糖、辣椒、食品添加剂（防腐剂（脱氢乙酸钠）、甜味剂（三氯蔗糖））、食用香精',
      additives: ['脱氢乙酸钠', '三氯蔗糖'], allergens: ['麸质谷物', '大豆'],
      nutrition: { energy: '412 kcal/100g', fat: '22g', carbs: '48g', sodium: '980mg' },
    },
    {
      id: 3, name: '奥利奥夹心饼干 97g', barcode: '6901668044444',
      brand: '奥利奥', category: '饼干糕点', gb: '07.01',
      sources: 2, ingredientCount: 11, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '小麦粉、白砂糖、植物油、可可粉、葡萄糖浆、全脂乳粉、食品添加剂（膨松剂（碳酸氢钠）、乳化剂（大豆磷脂））、食盐',
      additives: ['碳酸氢钠', '大豆磷脂'], allergens: ['麸质谷物', '乳', '大豆'],
      nutrition: { energy: '480 kcal/100g', fat: '20g', carbs: '67g', sodium: '380mg' },
    },
    {
      id: 4, name: '沃隆每日坚果 25g', barcode: '6971234567890',
      brand: '沃隆', category: '坚果炒货', gb: '04.05',
      sources: 1, ingredientCount: 6, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干',
      additives: [], allergens: ['坚果'],
      nutrition: { energy: '590 kcal/100g', fat: '48g', carbs: '28g', sodium: '5mg' },
    },
    {
      id: 5, name: '大白兔奶糖 114g', barcode: '6901234599999',
      brand: '大白兔', category: '糖果巧克力', gb: '05.02',
      sources: 2, ingredientCount: 5, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '白砂糖、奶粉、氢化植物油、明胶、食品添加剂（乳化剂（单硬脂酸甘油酯）、食用香精）',
      additives: ['单硬脂酸甘油酯'], allergens: ['乳'],
      nutrition: { energy: '410 kcal/100g', fat: '8g', carbs: '78g', sodium: '120mg' },
    },
    {
      id: 6, name: '某品牌低糖苏打饼干 100g', barcode: '6901234567001',
      brand: '某品牌', category: '饼干糕点', gb: '07.01',
      sources: 1, ingredientCount: 8, sourceUrl: 'world.openfoodfacts.org/api/v2/search?countries_tags=en:china',
      ingredients: '小麦粉、植物油、食用盐、碳酸氢钠、全麦粉（≥30%）、食用香精',
      additives: ['碳酸氢钠'], allergens: ['麸质谷物'],
      nutrition: { energy: '430 kcal/100g', fat: '16g', carbs: '62g', sodium: '610mg' },
    },
  ],

  // 添加剂知识条目（FR-4 / additive.knowledge_text，仅科普，不含禁用概念）
  additives: [
    { id: 1, name: '山梨酸钾', ins: '202', cns: '17.004', fn: '防腐剂', products: 486, knowledge: '常见的食品防腐剂，可抑制霉菌和酵母菌生长，延长保质期。在按规定范围使用是常见配料。' },
    { id: 2, name: '柠檬黄', ins: '102', cns: '08.006', fn: '着色剂', products: 233, knowledge: '一种合成食用色素，常用于糖果、饮料等着色。标签上通常以「着色剂（柠檬黄）」形式标示。' },
    { id: 3, name: '特丁基对苯二酚（TBHQ）', ins: '319', cns: '04.007', fn: '抗氧化剂', products: 312, knowledge: '常用于油脂和膨化食品的抗氧化剂，可延缓油脂氧化变质。配料表中常见简写「TBHQ」。' },
    { id: 4, name: '三氯蔗糖', ins: '955', cns: '19.016', fn: '甜味剂', products: 178, knowledge: '一种高倍甜味剂，甜度约为蔗糖的数百倍，常用于低糖或无糖产品。' },
    { id: 5, name: '单硬脂酸甘油酯', ins: '471', cns: '10.006', fn: '乳化剂', products: 398, knowledge: '常见乳化剂，可改善食品质地与稳定性，广泛用于糖果、糕点。' },
    { id: 6, name: '5\'-呈味核苷酸二钠', ins: '—', cns: '—', fn: '增味剂', products: 152, knowledge: '常见增味剂，可增强食品鲜味，常与味精配合使用。' },
    { id: 7, name: '脱氢乙酸钠', ins: '—', cns: '17.009', fn: '防腐剂', products: 88, knowledge: '常见防腐剂，用于抑制微生物生长。不同食品类别对其使用有不同规定。' },
    { id: 8, name: '大豆磷脂', ins: '322', cns: '—', fn: '乳化剂', products: 264, knowledge: '来源于大豆的天然乳化剂，同时是常见致敏原，标签中需注意致敏提示。' },
  ],

  // 待人工确认队列（FR-3.6）
  pendingIngredients: [
    { raw: '食用香精香料', times: 132, guess: '食用香精' },
    { raw: '5\'-呈味核苷酸二钠', times: 88, guess: '呈味核苷酸二钠' },
    { raw: '酵母抽提物', times: 35, guess: '酵母提取物' },
    { raw: '复配膨松剂', times: 27, guess: '膨松剂（复合）' },
  ],

  // 用户关注规则（FR-4.2 / user_rule，表驱动、版本化，非合规规则）
  userRules: [
    { id: 1, type: '过敏原', name: '花生', threshold: '—', version: 'v1.0', hint: '个人提示', active: true, desc: '配料中含花生或花生制品时提示' },
    { id: 2, type: '过敏原', name: '麸质谷物', threshold: '—', version: 'v1.0', hint: '个人提示', active: true, desc: '配料中含小麦、大麦等含麸质谷物时提示' },
    { id: 3, type: '过敏原', name: '乳', threshold: '—', version: 'v1.0', hint: '个人提示', active: true, desc: '配料中含乳或乳制品时提示' },
    { id: 4, type: '过敏原', name: '坚果', threshold: '—', version: 'v1.0', hint: '个人提示', active: true, desc: '配料中含坚果类时提示' },
    { id: 5, type: '营养阈值', name: '钠', threshold: '600 mg/100g', version: 'v1.0', hint: '个人提示', active: true, desc: '钠含量高于设定阈值时提示' },
    { id: 6, type: '营养阈值', name: '碳水化合物', threshold: '60 g/100g', version: 'v1.0', hint: '个人提示', active: true, desc: '碳水化合物高于设定阈值时提示' },
  ],

  // 解读批次（FR-5 / interpret_run）
  interpretRuns: [
    { id: 31, time: '2026-11-25 16:20', scope: '全量 386 件', version: 'v1.0', total: 386, hits: 164 },
    { id: 30, time: '2026-11-24 20:15', scope: '膨化食品增量', version: 'v1.0', total: 180, hits: 72 },
    { id: 29, time: '2026-11-22 14:00', scope: '饼干糕点增量', version: 'v1.0', total: 96, hits: 41 },
  ],

  // 解读结果（FR-5 / interpret_result，三级：客观事实/知识科普/个人提示）
  results: [
    {
      id: 9001, product: '乐事经典原味薯片 70g', infoType: '客观事实',
      rule: '—', evidence: '配料表含 TBHQ、5\'-呈味核苷酸二钠', detail: '来源：Open Food Facts',
      note: '这是标签原文的客观呈现',
    },
    {
      id: 9002, product: '乐事经典原味薯片 70g', infoType: '知识科普',
      rule: '添加剂知识库', evidence: 'TBHQ（抗氧化剂）：延缓油脂氧化变质',
      detail: 'INS 319', note: '这是添加剂功能的科普说明',
    },
    {
      id: 9003, product: '卫龙辣条大面筋 106g', infoType: '个人提示',
      rule: '关注规则 #2 麸质谷物', evidence: '配料含小麦粉；钠 980mg/100g 高于阈值 600',
      detail: '命中 2 条关注项', note: '这是按用户设定给出的个人提示，非合规判定',
    },
    {
      id: 9004, product: '奥利奥夹心饼干 97g', infoType: '个人提示',
      rule: '关注规则 #2/#3 麸质、乳', evidence: '配料含小麦粉、全脂乳粉、大豆磷脂',
      detail: '命中 3 条关注项', note: '含致敏原，供用户自行判断',
    },
    {
      id: 9005, product: '某品牌低糖苏打饼干 100g', infoType: '个人提示',
      rule: '关注规则 #5 钠', evidence: '钠 610mg/100g 高于阈值 600',
      detail: '命中 1 条关注项', note: '个人营养关注提示',
    },
    {
      id: 9006, product: '沃隆每日坚果 25g', infoType: '客观事实',
      rule: '—', evidence: '配料：扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干（无添加剂）',
      detail: '来源：Open Food Facts', note: '这是标签原文的客观呈现',
    },
  ],

  // 统计（FR-7 / V2.0：不再有"违规/疑似"分布）
  statsCharts: {
    category: [
      { label: '膨化食品', value: 180, color: '#378ADD' },
      { label: '饼干糕点', value: 96, color: '#1D9E75' },
      { label: '糖果巧克力', value: 74, color: '#7F77DD' },
      { label: '坚果炒货', value: 22, color: '#BA7517' },
      { label: '肉类零食', value: 14, color: '#D85A30' },
    ],
    topAdditives: [
      { label: '山梨酸钾', value: 486 },
      { label: '单硬脂酸甘油酯', value: 398 },
      { label: 'TBHQ', value: 312 },
      { label: '大豆磷脂', value: 264 },
      { label: '柠檬黄', value: 233 },
      { label: '三氯蔗糖', value: 178 },
    ],
    dataQuality: [
      { label: '配料表非空', value: 94, color: '#1D9E75' },
      { label: '条码唯一', value: 100, color: '#378ADD' },
      { label: '标准化覆盖', value: 82, color: '#7F77DD' },
    ],
  },

  // 系统管理（FR-8）
  users: [
    { id: 1, name: 'admin', role: '管理员', status: '正常' },
    { id: 2, name: 'data_ops', role: '数据维护员', status: '正常' },
    { id: 3, name: 'analyst', role: '分析员（只读）', status: '正常' },
  ],
  logs: [
    { time: '2026-11-25 16:20', user: 'admin', action: '触发全量解读 run#31', target: 'interpret_run' },
    { time: '2026-11-25 16:12', user: 'data_ops', action: '创建采集任务 #203（遇503退避）', target: 'crawl_task' },
    { time: '2026-11-25 16:00', user: 'data_ops', action: '采集 180 条原始 JSON 入库', target: 'raw_record' },
    { time: '2026-11-24 10:20', user: 'data_ops', action: '导入抽检公告样本 36 条', target: 'inspection_record' },
  ],
  schedules: [
    { type: '增量采集', mode: '每日 02:00 · 限速 4 秒/请求', next: '2026-11-26 02:00' },
    { type: '全量解读', mode: '每周一 09:00', next: '2026-11-30 09:00' },
    { type: '数据备份', mode: '每日 03:30', next: '2026-11-26 03:30' },
  ],
}
