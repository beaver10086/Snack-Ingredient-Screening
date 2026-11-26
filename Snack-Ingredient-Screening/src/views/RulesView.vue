<script setup>
import { ref, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getAdditives, getUserRules } from '../api'

const additives = ref([])
const rules = ref([])
onMounted(async () => {
  additives.value = await getAdditives()
  rules.value = await getUserRules()
})
</script>

<template>
  <div class="card">
    <div class="card-title">
      用户关注规则 <span class="sub">user_rule · 表驱动、版本化（DB-4 / DB-5），非合规规则</span>
      <button class="btn btn-primary btn-sm" style="float:right">+ 新建关注规则</button>
    </div>
    <table>
      <thead><tr><th>规则类型</th><th>关注项</th><th>阈值</th><th>提示级别</th><th>版本</th><th>说明</th><th>状态</th></tr></thead>
      <tbody>
        <tr v-for="r in rules" :key="r.id">
          <td><SeverityBadge :text="r.type" /></td>
          <td><b>{{ r.name }}</b></td>
          <td>{{ r.threshold }}</td>
          <td><SeverityBadge :text="r.hint" /></td>
          <td>{{ r.version }}</td>
          <td style="font-size:12px;color:var(--text-sub)">{{ r.desc }}</td>
          <td>{{ r.active ? '启用' : '停用' }}</td>
        </tr>
      </tbody>
    </table>
    <div class="detail-text">
      规则存于表中而非写死在程序里；标准更新时新增版本而非覆盖，解读结果记录所用版本（可重现）。
      规则只表达<b>用户个人的饮食关注</b>（过敏原、营养阈值），不表达法规合规判定。
    </div>
  </div>

  <div class="card">
    <div class="card-title">添加剂知识库 <span class="sub">additive.knowledge_text · 科普说明（FR-4.1 / G4）</span></div>
    <table>
      <thead><tr><th>添加剂</th><th>功能类别</th><th>INS / CNS</th><th>科普说明</th></tr></thead>
      <tbody>
        <tr v-for="a in additives" :key="a.id">
          <td><b>{{ a.name }}</b></td>
          <td><span class="badge b-purple">{{ a.fn }}</span></td>
          <td>{{ a.ins }} / {{ a.cns }}</td>
          <td style="max-width:460px;font-size:12px;color:var(--text-sub)">{{ a.knowledge }}</td>
        </tr>
      </tbody>
    </table>
    <div class="detail-text">
      知识条目只说明"这种添加剂是什么、常见功能是什么"，用于生成<b>知识科普</b>类解读，
      不含"禁用/允许"等违法定性内容（NFR-10）。
    </div>
  </div>
</template>
