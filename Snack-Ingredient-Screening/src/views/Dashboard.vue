<script setup>
import { ref, onMounted } from 'vue'
import StatCard from '../components/StatCard.vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getStats, getInterpretRuns } from '../api'

const stats = ref({})
const runs = ref([])
onMounted(async () => {
  stats.value = await getStats()
  runs.value = (await getInterpretRuns()).slice(0, 4)
})
</script>

<template>
  <div class="grid grid-4">
    <StatCard :label="'产品总数（条）'" :value="stats.productCount ?? '-'" badge-text="G1 目标 300~500 ✔" />
    <StatCard :label="'已接入数据源'" :value="stats.sourceCount ?? '-'" delta="开放库/公告/电商公开页" />
    <StatCard :label="'用户关注规则'" :value="stats.ruleCount ?? '-'" delta="user_rule v1.0" />
    <StatCard :label="'待确认配料'" :value="stats.pendingConfirm ?? '-'" badge-text="FR-3.6 待确认队列" />
  </div>

  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">配料标准化覆盖率 <span class="sub">G3 目标 ≥ 80%</span></div>
      <div style="font-size:30px;font-weight:700;color:var(--primary)">
        {{ stats.coveredRate ? (stats.coveredRate * 100).toFixed(1) + '%' : '…' }}
      </div>
      <div class="progress"><div :style="{ width: (stats.coveredRate ?? 0) * 100 + '%' }"></div></div>
      <div class="detail-text">
        抽样人工核对口径：已映射 /（已映射 + 待确认）。未映射配料进入「待人工确认」队列，确认后沉淀入别名词典（FR-3.6）。
      </div>
    </div>

    <div class="card">
      <div class="card-title">最近解读批次 <span class="sub">interpret_run</span></div>
      <table>
        <thead><tr><th>批次</th><th>时间</th><th>规则版本</th><th>解读数</th><th>状态</th></tr></thead>
        <tbody>
          <tr v-for="r in runs" :key="r.id">
            <td>#{{ r.id }}</td><td>{{ r.time }}</td><td>{{ r.version }}</td>
            <td>{{ r.hits }}</td><td><SeverityBadge text="成功" /></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <div class="card">
    <div class="card-title">采集运行状态 <span class="sub">实测 Open Food Facts 限速 {{ stats.apiLimit || '15 req/min' }}</span></div>
    <div class="detail-text">
      主源 Open Food Facts 按品类分页抓取，每请求间隔 ≥4 秒；实测匿名请求 15 req/min 会触发 HTTP 503，
      采集器已实现<b>指数退避 + 断点续跑 + 原始 JSON 留痕</b>。最近批次 {{ stats.lastRun }}。
    </div>
  </div>

  <div class="card">
    <div class="card-title">三层数据模型 <span class="sub">原始层 → 标准层 → 知识与结果层</span></div>
    <div class="detail-text">
      <b>原始层</b> raw_record（API 原始 JSON，不可变，用于溯源）→
      <b>标准层</b> product / brand / label_info / product_ingredient / additive（清洗、去重、标准化）→
      <b>知识与结果层</b> user_rule / interpret_run / interpret_result / inspection_record（表驱动的个性化提示、结果留痕可追溯）。
      <br>系统输出为<b>客观事实 / 知识科普 / 个人提示</b>三级，不构成对产品的合规判定（NFR-10）。
    </div>
  </div>
</template>
