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
  <div class="card">
    <div class="card-title">解析流程 <span class="sub">FR-3 · 系统技术核心</span></div>
    <div class="detail-text">
      ① 按分隔符拆分配料表并保留顺序 →
      ② 处理复合配料括号嵌套（如「巧克力（白砂糖、乳化剂（大豆磷脂））」）→
      ③ 识别添加剂「类别名（具体名 / INS 号）」→
      ④ 名称标准化（别名、英文名、INS/CNS 号映射）→
      ⑤ 提取标注比例（如「鸡肉（≥30%）」）→
      ⑥ 识别致敏物质相关配料。
    </div>
  </div>

  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">添加剂知识名录 <span class="sub">additive · knowledge_text（仅科普，非判定）</span></div>
      <table>
        <thead><tr><th>名称</th><th>INS</th><th>CNS</th><th>功能类别</th><th>涉及产品</th></tr></thead>
        <tbody>
          <tr v-for="a in additives" :key="a.id">
            <td>{{ a.name }}</td>
            <td>{{ a.ins }}</td><td>{{ a.cns }}</td>
            <td><span class="badge b-purple">{{ a.fn }}</span></td>
            <td>{{ a.products }}</td>
          </tr>
        </tbody>
      </table>
      <div class="detail-text">点击行可在「知识与关注规则」页查看该添加剂的功能科普说明（G4）。</div>
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
        无法自动映射的配料先进入待确认队列，人工确认后沉淀到 ingredient_alias 别名词典，
        覆盖率按「已映射 /（已映射 + 待确认）」抽样核对（G3 ≥ 80%）。
      </div>
    </div>
  </div>
</template>
