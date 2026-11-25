<script setup>
import { ref, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getUsers, getLogs, getSchedules } from '../api'

const users = ref([])
const logs = ref([])
const schedules = ref([])
onMounted(async () => {
  users.value = await getUsers()
  logs.value = await getLogs()
  schedules.value = await getSchedules()
})
</script>

<template>
  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">用户与角色 <span class="sub">sys_user · FR-8.1</span></div>
      <table>
        <thead><tr><th>账号</th><th>角色</th><th>状态</th></tr></thead>
        <tbody>
          <tr v-for="u in users" :key="u.id">
            <td>{{ u.name }}</td>
            <td><span class="badge b-info">{{ u.role }}</span></td>
            <td><SeverityBadge :text="u.status" /></td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">任务调度 <span class="sub">FR-8.3 · 采集/解读/备份手动或定时触发</span></div>
      <table>
        <thead><tr><th>任务类型</th><th>调度方式</th><th>下次执行</th></tr></thead>
        <tbody>
          <tr v-for="s in schedules" :key="s.type">
            <td>{{ s.type }}</td><td>{{ s.mode }}</td><td>{{ s.next }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <div class="card">
    <div class="card-title">操作日志 <span class="sub">sys_log · FR-8.2</span></div>
    <table>
      <thead><tr><th>时间</th><th>用户</th><th>操作</th><th>目标表</th></tr></thead>
      <tbody>
        <tr v-for="(l, i) in logs" :key="i">
          <td>{{ l.time }}</td><td>{{ l.user }}</td><td>{{ l.action }}</td>
          <td><span class="badge b-gray">{{ l.target }}</span></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
