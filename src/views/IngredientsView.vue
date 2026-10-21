<script setup>
import { ref, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getAdditives, getPendingIngredients } from '../api'

const additives = ref([])
const pending = ref([])
onMounted(async () => {
  additives.value = await getAdditives()
  pending.value = await getPendingIngredients()
})
</script>

<template>
  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">添加剂名录 <span class="sub">additive · G4 覆盖常见类别</span></div>
      <table>
        <thead><tr><th>名称</th><th>INS</th><th>CNS</th><th>功能类别</th><th>涉及产品</th></tr></thead>
        <tbody>
          <tr v-for="a in additives" :key="a.id">
            <td>{{ a.name }} <SeverityBadge v-if="a.prohibited" text="禁用" /></td>
            <td>{{ a.ins }}</td><td>{{ a.cns }}</td>
            <td><span class="badge b-purple">{{ a.fn }}</span></td>
            <td>{{ a.products }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">待人工确认队列 <span class="sub">FR-3.6 · 确认后沉淀入别名词典</span></div>
      <table>
        <thead><tr><th>原文片段</th><th>出现次数</th><th>猜测映射</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="p in pending" :key="p.raw">
            <td>{{ p.raw }}</td><td>{{ p.times }}</td>
            <td style="color:var(--text-sub)">{{ p.guess }}</td>
            <td><button class="btn btn-sm">确认</button> <button class="btn btn-sm">否决</button></td>
          </tr>
        </tbody>
      </table>
      <div class="detail-text">
        解析要点：按分隔符拆分并保留顺序（递减检查）；处理复合配料括号嵌套；识别「类别名（具体名/INS 号）」形式；提取标注比例（如 鸡肉（≥30%））。
      </div>
    </div>
  </div>
</template>
