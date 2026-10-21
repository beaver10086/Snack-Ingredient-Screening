<script setup>
import { ref, computed, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getCheckRuns, getCheckResults } from '../api'

const runs = ref([])
const results = ref([])
const problem = ref('全部问题类型')
const severity = ref('全部严重程度')
const review = ref('全部复核状态')

onMounted(async () => {
  runs.value = await getCheckRuns()
  results.value = await getCheckResults()
})

const filtered = computed(() =>
  results.value.filter(r =>
    (problem.value === '全部问题类型' || r.problem === problem.value) &&
    (severity.value === '全部严重程度' || r.severity === severity.value) &&
    (review.value === '全部复核状态' || r.review === review.value)
  )
)
</script>

<template>
  <div class="card">
    <div class="card-title">
      发起筛查
      <span class="sub">FR-5 · 判定分层：有含量数据→与限量比较；无含量→仅判使用范围并给风险提示</span>
    </div>
    <div class="search-bar">
      <select>
        <option>全量产品</option><option>按品类</option><option>按单品</option><option>仅新增数据</option>
      </select>
      <select>
        <option>规则版本 v1.3</option><option>规则版本 v1.2</option>
      </select>
      <button class="btn btn-primary">▶ 执行筛查</button>
      <button class="btn">重新筛查历史数据</button>
    </div>
  </div>

  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">筛查批次 <span class="sub">check_run</span></div>
      <table>
        <thead><tr><th>批次</th><th>范围</th><th>产品数</th><th>命中</th><th>规则版本</th><th>时间</th></tr></thead>
        <tbody>
          <tr v-for="r in runs" :key="r.id">
            <td>#{{ r.id }}</td><td>{{ r.scope }}</td><td>{{ r.total }}</td><td>{{ r.hits }}</td>
            <td>{{ r.version }}</td><td>{{ r.time }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">结果分级说明 <span class="sub">FR-5.4 / NFR-10</span></div>
      <div class="detail-text" style="margin-top:0">
        <SeverityBadge text="违规" />　<b>确定违规</b>：命中禁用名单、抽检检出超限量等有确凿证据的结论。<br><br>
        <SeverityBadge text="疑似" />　<b>需人工复核</b>：如无含量数据仅可判使用范围/品种合规性。<br><br>
        <SeverityBadge text="提示" />　<b>风险提示</b>：高风险组合、标签不规范等非定论提示。<br><br>
        ⚠️ 结论仅作课程研究用途，<b>不构成对具体品牌的违法定性</b>；每条结果记录产品、触发规则、法规条款、证据原文、规则版本、筛查时间（可追溯 G6）。
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-title">筛查结果 <span class="sub">check_result · 支持按问题类型/严重程度/规则过滤</span></div>
    <div class="search-bar">
      <select v-model="problem">
        <option>全部问题类型</option><option>不合规配料</option><option>添加剂使用</option><option>标签标注</option>
      </select>
      <select v-model="severity">
        <option>全部严重程度</option><option>违规</option><option>疑似</option><option>提示</option>
      </select>
      <select v-model="review">
        <option>全部复核状态</option><option>未复核</option><option>确认</option><option>误报</option>
      </select>
      <button class="btn">导出 Excel</button>
    </div>
    <table>
      <thead><tr><th>产品</th><th>问题类型</th><th>严重程度</th><th>触发规则</th><th>证据</th><th>检出/限值</th><th>复核</th><th>操作</th></tr></thead>
      <tbody>
        <tr v-for="r in filtered" :key="r.id">
          <td>{{ r.product }}</td><td>{{ r.problem }}</td>
          <td><SeverityBadge :text="r.severity" /></td>
          <td>{{ r.rule }}</td>
          <td style="max-width:260px;font-size:12px">{{ r.evidence }}</td>
          <td>{{ r.detail }}</td>
          <td><SeverityBadge :text="r.review" /></td>
          <td><button class="btn btn-sm">确认</button> <button class="btn btn-sm">误报</button></td>
        </tr>
        <tr v-if="!filtered.length"><td colspan="8" class="empty">当前筛选条件下无结果</td></tr>
      </tbody>
    </table>
    <div class="detail-text">
      复核操作回流至规则优化（FR-6.4）：确认为误报的结果可关联分析规则缺陷，迭代别名词典与规则阈值。
    </div>
  </div>
</template>
