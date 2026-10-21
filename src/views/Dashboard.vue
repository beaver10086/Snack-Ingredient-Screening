<script setup>
import { ref, onMounted } from 'vue'
import StatCard from '../components/StatCard.vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getStats, getCheckRuns } from '../api'

const stats = ref({})
const runs = ref([])
onMounted(async () => {
  stats.value = await getStats()
  runs.value = (await getCheckRuns()).slice(0, 4)
})
</script>

<template>
  <div class="grid grid-4">
    <StatCard :label="'产品总数（条）'" :value="stats.productCount ?? '-'" badge-text="目标 ≥ 2000 ✔" />
    <StatCard :label="'已接入数据源'" :value="stats.sourceCount ?? '-'" delta="开放库/电商/官网/公告" />
    <StatCard :label="'启用的合规规则'" :value="stats.ruleCount ?? '-'" delta="规则库 v1.3" />
    <StatCard :label="'待复核筛查结果'" :value="stats.pendingReview ?? '-'" badge-text="近期新增 +6" />
  </div>

  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">配料标准化覆盖率 <span class="sub">目标 G3 ≥ 85%</span></div>
      <div style="font-size:30px;font-weight:700;color:var(--primary)">
        {{ stats.coveredRate ? (stats.coveredRate * 100).toFixed(1) + '%' : '…' }}
      </div>
      <div class="progress"><div :style="{ width: (stats.coveredRate ?? 0) * 100 + '%' }"></div></div>
      <div class="detail-text">
        抽样人工核对口径：已映射 /（已映射 + 待确认）。未映射配料进入「待人工确认」队列，确认后沉淀入别名词典。
      </div>
    </div>

    <div class="card">
      <div class="card-title">最近筛查批次 <span class="sub">check_run</span></div>
      <table>
        <thead><tr><th>批次</th><th>时间</th><th>规则版本</th><th>命中</th><th>状态</th></tr></thead>
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
    <div class="card-title">三层数据模型 <span class="sub">原始层 → 标准层 → 规则与结果层</span></div>
    <div class="detail-text">
      <b>原始层</b> raw_record（采集原文，不可变，用于溯源）→
      <b>标准层</b> product / brand / label_info / product_ingredient / additive（清洗、去重、标准化）→
      <b>规则与结果层</b> regulation / check_rule / additive_usage_limit / check_run / check_result（规则驱动筛查、结果留痕可追溯）。
    </div>
  </div>
</template>
