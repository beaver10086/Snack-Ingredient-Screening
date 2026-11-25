<script setup>
import { ref, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getDataSources, getCrawlTasks } from '../api'

const sources = ref([])
const tasks = ref([])
onMounted(async () => {
  sources.value = await getDataSources()
  tasks.value = await getCrawlTasks()
})

const stars = (n) => '★'.repeat(n) + '☆'.repeat(5 - n)
</script>

<template>
  <div class="card">
    <div class="card-title">
      已登记数据源 <span class="sub">data_source · 全部为公开网络来源（V2.0 第 5 节）</span>
      <button class="btn btn-primary btn-sm" style="float:right">+ 登记数据源</button>
    </div>
    <table>
      <thead><tr><th>名称</th><th>类型</th><th>采集方式</th><th>可信度</th><th>授权 / 合规说明</th><th>状态</th></tr></thead>
      <tbody>
        <tr v-for="d in sources" :key="d.id">
          <td>{{ d.name }}<div class="detail-text" style="margin:2px 0 0">{{ d.url }}</div></td>
          <td><span class="badge b-info">{{ d.type }}</span></td>
          <td>{{ d.method }}<div class="detail-text" style="margin:2px 0 0">{{ d.fields }}</div></td>
          <td>{{ stars(d.reliability) }}</td>
          <td style="max-width:280px;font-size:12px;color:var(--text-sub)">{{ d.terms }}</td>
          <td><SeverityBadge :text="d.active ? '启用' : '停用'" /></td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="card-title">
      采集任务 <span class="sub">crawl_task · 限速退避 / 原始层留存 / 断点续跑（FR-1.3~1.6）</span>
      <button class="btn btn-primary btn-sm" style="float:right">+ 新建任务</button>
    </div>
    <table>
      <thead><tr><th>任务</th><th>数据源 / 品类关键词</th><th>成功 / 失败</th><th>限速</th><th>失败策略</th><th>原始层</th><th>状态</th></tr></thead>
      <tbody>
        <tr v-for="t in tasks" :key="t.id">
          <td>#{{ t.id }}<div class="detail-text" style="margin:2px 0 0">{{ t.start }}</div></td>
          <td>{{ t.source }}<div class="detail-text" style="margin:2px 0 0">{{ t.keyword }}</div></td>
          <td><span style="color:var(--green)">{{ t.ok }}</span> / <span style="color:var(--red)">{{ t.fail }}</span></td>
          <td>{{ t.rate }}</td>
          <td>{{ t.retry }}</td>
          <td>{{ t.raw }}</td>
          <td><SeverityBadge :text="t.status" /></td>
        </tr>
      </tbody>
    </table>
    <div class="detail-text">
      采集约束（NFR-8）：仅采公开数据，遵守 robots 与站点条款，限速访问，不绕过登录/反爬；
      原始数据（JSON / 公告附件）原样存入 raw_record，与清洗后数据分离，任何结果可追溯到来源 URL。
      主源实测限速 15 req/min/IP，连续请求会返回 503，代码中已实现退避重试。
    </div>
  </div>
</template>
