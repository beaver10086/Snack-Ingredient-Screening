<script setup>
import { ref, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getRegulations, getRules, getUsageLimits } from '../api'

const regulations = ref([])
const rules = ref([])
const limits = ref([])
onMounted(async () => {
  regulations.value = await getRegulations()
  rules.value = await getRules()
  limits.value = await getUsageLimits()
})
</script>

<template>
  <div class="card">
    <div class="card-title">法规与标准 <span class="sub">regulation · 版本化管理，不覆盖（FR-4.3）</span></div>
    <table>
      <thead><tr><th>标准号</th><th>名称</th><th>发布日期</th><th>实施日期</th><th>状态</th></tr></thead>
      <tbody>
        <tr v-for="r in regulations" :key="r.id">
          <td><b>{{ r.no }}</b></td><td>{{ r.name }}</td><td>{{ r.publish }}</td><td>{{ r.effective }}</td>
          <td><SeverityBadge :text="r.status" /></td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="card-title">合规规则 R1–R6 <span class="sub">check_rule · 表驱动，程序内不写死阈值（DB-4）</span></div>
    <table>
      <thead><tr><th>类型</th><th>说明</th><th>依据法规</th><th>条款</th><th>严重程度</th><th>状态</th></tr></thead>
      <tbody>
        <tr v-for="r in rules" :key="r.id">
          <td><span class="badge b-info">{{ r.type }}</span> {{ r.typeDesc }}</td>
          <td>{{ r.desc }}</td><td>{{ r.reg }}</td><td>{{ r.clause }}</td>
          <td><SeverityBadge :text="r.severity" /></td>
          <td>{{ r.active ? '启用' : '停用' }}</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="card-title">使用限量示例 <span class="sub">additive_usage_limit</span></div>
    <table>
      <thead><tr><th>添加剂</th><th>适用食品分类</th><th>最大使用量</th><th>计量方式</th></tr></thead>
      <tbody>
        <tr v-for="(l, i) in limits" :key="i">
          <td>{{ l.additive }}</td><td>{{ l.gb }}</td>
          <td><b>{{ l.max }} {{ l.unit }}</b></td><td>以添加剂计</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
