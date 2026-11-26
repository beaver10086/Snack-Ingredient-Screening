<script setup>
import { ref, computed, onMounted } from 'vue'
import SeverityBadge from '../components/SeverityBadge.vue'
import { getInterpretRuns, getInterpretResults } from '../api'

const runs = ref([])
const results = ref([])
const infoType = ref('全部类型')

onMounted(async () => {
  runs.value = await getInterpretRuns()
  results.value = await getInterpretResults()
})

const filtered = computed(() =>
  results.value.filter(r => infoType.value === '全部类型' || r.infoType === infoType.value)
)
</script>

<template>
  <div class="card">
    <div class="card-title">
      发起成分解读
      <span class="sub">FR-5 · 只输出客观事实 / 知识科普 / 个人提示三级（NFR-10）</span>
    </div>
    <div class="search-bar">
      <select>
        <option>全量产品</option><option>按品类</option><option>按单品</option><option>仅新增数据</option>
      </select>
      <select>
        <option>关注规则版本 v1.0</option>
      </select>
      <button class="btn btn-primary">▶ 执行解读</button>
    </div>
  </div>

  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">解读批次 <span class="sub">interpret_run</span></div>
      <table>
        <thead><tr><th>批次</th><th>范围</th><th>产品数</th><th>解读数</th><th>规则版本</th><th>时间</th></tr></thead>
        <tbody>
          <tr v-for="r in runs" :key="r.id">
            <td>#{{ r.id }}</td><td>{{ r.scope }}</td><td>{{ r.total }}</td><td>{{ r.hits }}</td>
            <td>{{ r.version }}</td><td>{{ r.time }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">三级表述说明 <span class="sub">FR-5.3 / NFR-10</span></div>
      <div class="detail-text" style="margin-top:0">
        <SeverityBadge text="客观事实" />　<b>标签原文的客观呈现</b>：如"配料表含 TBHQ"，来自数据源原始记录。<br><br>
        <SeverityBadge text="知识科普" />　<b>添加剂功能的科普说明</b>：如"TBHQ 是抗氧化剂，延缓油脂氧化"。<br><br>
        <SeverityBadge text="个人提示" />　<b>按用户关注规则给出的提示</b>：如"含麸质谷物""钠高于您设定的阈值"。<br><br>
        ⚠️ 所有内容仅为标签信息呈现与知识科普，<b>不构成对产品的合规判定或对品牌的评价</b>；
        每条结果记录产品、命中规则、原文证据、规则版本与生成时间（可追溯 G6）。
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-title">解读结果 <span class="sub">interpret_result · 支持按信息类型过滤</span></div>
    <div class="search-bar">
      <select v-model="infoType">
        <option>全部类型</option><option>客观事实</option><option>知识科普</option><option>个人提示</option>
      </select>
      <button class="btn">导出 Excel</button>
    </div>
    <table>
      <thead><tr><th>产品</th><th>信息类型</th><th>命中规则</th><th>证据 / 说明</th><th>备注</th><th>附加信息</th></tr></thead>
      <tbody>
        <tr v-for="r in filtered" :key="r.id">
          <td>{{ r.product }}</td>
          <td><SeverityBadge :text="r.infoType" /></td>
          <td>{{ r.rule }}</td>
          <td style="max-width:300px;font-size:12px">{{ r.evidence }}</td>
          <td style="max-width:220px;font-size:12px;color:var(--text-sub)">{{ r.note }}</td>
          <td>{{ r.detail }}</td>
        </tr>
        <tr v-if="!filtered.length"><td colspan="6" class="empty">当前筛选条件下无结果</td></tr>
      </tbody>
    </table>
    <div class="detail-text">
      用户可在「知识与关注规则」页调整过敏原名单与营养阈值，重新解读即可按新的个人关注生成提示。
    </div>
  </div>
</template>
