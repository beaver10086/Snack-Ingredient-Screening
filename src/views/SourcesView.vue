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
      已登记数据源 <span class="sub">data_source</span>
      <button class="btn btn-primary btn-sm" style="float:right">+ 登记数据源</button>
    </div>
    <table>
      <thead><tr><th>名称</th><th>类型</th><th>采集方式</th><th>可信度</th><th>使用条款说明</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>
        <tr v-for="d in sources" :key="d.id">
          <td>{{ d.name }}<div class="detail-text" style="margin:2px 0 0">{{ d.url }}</div></td>
          <td><span class="badge b-info">{{ d.type }}</span></td>
          <td>{{ d.method }}</td>
          <td>{{ stars(d.reliability) }}</td>
          <td style="max-width:240px;font-size:12px;color:var(--text-sub)">{{ d.terms }}</td>
          <td><SeverityBadge :text="d.active ? '启用' : '停用'" /></td>
          <td><button class="btn btn-sm">编辑</button></td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="card">
    <div class="card-title">
      采集任务 <span class="sub">crawl_task · 支持增量与失败重试（FR-1.6）</span>
      <button class="btn btn-primary btn-sm" style="float:right">+ 新建任务</button>
    </div>
    <table>
      <thead><tr><th>任务</th><th>数据源</th><th>关键词</th><th>成功 / 失败</th><th>开始时间</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>
        <tr v-for="t in tasks" :key="t.id">
          <td>#{{ t.id }}</td><td>{{ t.source }}</td><td>{{ t.keyword }}</td>
          <td><span style="color:var(--green)">{{ t.ok }}</span> / <span style="color:var(--red)">{{ t.fail }}</span></td>
          <td>{{ t.start }}</td>
          <td><SeverityBadge :text="t.status" /></td>
          <td><button class="btn btn-sm">日志</button> <button class="btn btn-sm">重试</button></td>
        </tr>
      </tbody>
    </table>
    <div class="detail-text">
      采集约束：保存原始 HTML/JSON 至 raw_record（与清洗数据分离）；遵守 robots 协议、限速访问、不绕过登录/反爬（NFR-8）。
    </div>
  </div>
</template>
