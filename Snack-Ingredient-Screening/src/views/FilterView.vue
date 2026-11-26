<script setup>
import { ref, computed, onMounted } from 'vue'
import { getProducts, getAdditives } from '../api'

// FR-9 消费者前台应用区：免登录、少数选项、三态结果、结果可解释
const products = ref([])
const additives = ref([])

// 用户勾选的饮食需求
const selectedAllergens = ref([])
const ALLERGENS = ['花生', '麸质谷物', '乳', '大豆', '坚果', '蛋']
const lowSugar = ref(false)
const lowSodium = ref(false)
const sugarLimit = ref(25)     // g/100g，用户自设，系统不预设健康标准
const sodiumLimit = ref(400)   // mg/100g

const expanded = ref(new Set())
const compare = ref([])
const searched = ref(false)

onMounted(async () => {
  products.value = await getProducts()
  additives.value = await getAdditives()
})

function toggleAllergen(a) {
  const s = new Set(selectedAllergens.value)
  s.has(a) ? s.delete(a) : s.add(a)
  selectedAllergens.value = [...s]
}

const additiveKnowledge = (name) => {
  const a = additives.value.find(x => name.includes(x.name) || x.name.includes(name))
  return a ? a.knowledge : ''
}

// FR-9.3~9.5：三态判定 + 命中原因
// 优先级：不适合 > 信息不足 > 适合；信息不足单列，不默认判适合
function judge(p) {
  const reasons = []
  let unfit = false
  let unknown = false

  // 过敏原：未标注 → 信息不足；命中勾选 → 不适合
  for (const a of selectedAllergens.value) {
    if (!p.allergenLabeled) {
      unknown = true
      reasons.push({ level: 'miss', text: `致敏原标注缺失，无法判断是否含「${a}」` })
    } else if (p.allergens.includes(a)) {
      unfit = true
      reasons.push({ level: 'hit', text: `配料含致敏原「${a}」` })
    } else {
      reasons.push({ level: 'ok', text: `未检出「${a}」` })
    }
  }

  // 控钠：数值缺失 → 信息不足；超阈值 → 不适合
  if (lowSodium.value) {
    const v = p.nutritionNum && p.nutritionNum.sodium
    if (v == null) {
      unknown = true
      reasons.push({ level: 'miss', text: '营养成分表未提供钠含量，无法判断' })
    } else if (v > sodiumLimit.value) {
      unfit = true
      reasons.push({ level: 'hit', text: `钠 ${v} mg/100g，高于您设定的 ${sodiumLimit.value} mg` })
    } else {
      reasons.push({ level: 'ok', text: `钠 ${v} mg/100g，符合您的设定` })
    }
  }

  // 控糖：数值缺失 → 信息不足；超阈值 → 不适合
  if (lowSugar.value) {
    const v = p.nutritionNum && p.nutritionNum.sugar
    if (v == null) {
      unknown = true
      reasons.push({ level: 'miss', text: '营养成分表未提供糖含量，无法判断' })
    } else if (v > sugarLimit.value) {
      unfit = true
      reasons.push({ level: 'hit', text: `糖 ${v} g/100g，高于您设定的 ${sugarLimit.value} g` })
    } else {
      reasons.push({ level: 'ok', text: `糖 ${v} g/100g，符合您的设定` })
    }
  }

  if (!reasons.length) {
    reasons.push({ level: 'ok', text: '未勾选关注项，仅展示标签信息' })
  }
  const status = unfit ? 'unfit' : (unknown ? 'unknown' : 'fit')
  return { ...p, status, reasons }
}

const results = computed(() => {
  const list = products.value.map(judge)
  const order = { fit: 0, unknown: 1, unfit: 2 }  // 适合优先
  return [...list].sort((a, b) => order[a.status] - order[b.status] || a.name.localeCompare(b.name))
})

const counts = computed(() => ({
  fit: results.value.filter(r => r.status === 'fit').length,
  unknown: results.value.filter(r => r.status === 'unknown').length,
  unfit: results.value.filter(r => r.status === 'unfit').length,
}))

const statusText = { fit: '适合', unknown: '信息不足', unfit: '不适合' }
const statusClass = { fit: 'b-success', unknown: 'b-warning', unfit: 'b-danger' }

function toggleDetail(id) {
  const s = new Set(expanded.value)
  s.has(id) ? s.delete(id) : s.add(id)
  expanded.value = s
}
function toggleCompare(id) {
  const s = new Set(compare.value)
  if (s.has(id)) s.delete(id)
  else if (s.size < 2) s.add(id)
  compare.value = [...s]
}
const compareProducts = computed(() => compare.value.map(id => results.value.find(p => p.id === id)).filter(Boolean))
</script>

<template>
  <!-- 前台 Hero：三步说明，免登录 -->
  <div class="hero">
    <h2>找到适合你的零食</h2>
    <p>根据你的过敏原和控糖控钠需求，从公开标签数据中筛选产品。无需登录，几步就能看懂"为什么适合我"。</p>
    <div class="steps">
      <span class="step">① 选择你的饮食需求</span>
      <span class="step">② 一键筛选</span>
      <span class="step">③ 看结果和原因</span>
    </div>
  </div>

  <!-- 饮食需求勾选面板（FR-9.2） -->
  <div class="pref-grid">
    <div class="card">
      <div class="card-title">我关注的过敏原</div>
      <div class="check-list">
        <label
          v-for="a in ALLERGENS" :key="a"
          class="check-chip" :class="{ checked: selectedAllergens.includes(a) }"
        >
          <input type="checkbox" :checked="selectedAllergens.includes(a)" @change="toggleAllergen(a)" style="accent-color:var(--primary)">
          {{ a }}
        </label>
      </div>
      <div class="detail-text">勾选后，配料表中含该致敏原的产品会标为"不适合"；标签未标注致敏原的产品会单列为"信息不足"，不会误判为适合。</div>
    </div>

    <div class="card">
      <div class="card-title">我的营养关注</div>
      <div class="check-list">
        <label class="check-chip" :class="{ checked: lowSodium }">
          <input type="checkbox" v-model="lowSodium" style="accent-color:var(--primary)"> 控钠
        </label>
        <label class="check-chip" :class="{ checked: lowSugar }">
          <input type="checkbox" v-model="lowSugar" style="accent-color:var(--primary)"> 控糖
        </label>
      </div>
      <div class="threshold-row">
        <label>钠 ≤ <input type="number" v-model.number="sodiumLimit" min="0"> mg/100g</label>
        <label>糖 ≤ <input type="number" v-model.number="sugarLimit" min="0"> g/100g</label>
      </div>
      <div class="detail-text">阈值由你自己设定，系统只做数值比较，不替你判断是否健康。未标注营养数据的产品会归入"信息不足"。</div>
    </div>
  </div>

  <div class="card" style="text-align:center">
    <button class="btn btn-primary" style="padding:10px 32px;font-size:15px" @click="searched = true">为我筛选适合的产品</button>
  </div>

  <!-- 筛选结果（FR-9.3~9.7） -->
  <div v-if="searched">
    <div class="card">
      <div class="result-toolbar">
        <span class="count">共 {{ results.length }} 款产品：</span>
        <span class="badge b-success">适合 {{ counts.fit }}</span>
        <span class="badge b-warning">信息不足 {{ counts.unknown }}</span>
        <span class="badge b-danger">不适合 {{ counts.unfit }}</span>
        <button class="btn btn-sm" style="margin-left:auto" @click="compare.length && (compare = [])">清空对比</button>
      </div>

      <div v-for="p in results" :key="p.id" class="result-card" :class="p.status">
        <div style="flex-shrink:0;text-align:center">
          <input type="checkbox" :checked="compare.includes(p.id)" @change="toggleCompare(p.id)" title="勾选两款产品对比">
          <div style="font-size:11px;color:var(--text-sub);margin-top:4px">对比</div>
        </div>
        <div class="result-main">
          <div class="result-name">
            {{ p.name }}
            <span class="badge" :class="statusClass[p.status]" style="margin-left:8px">{{ statusText[p.status] }}</span>
          </div>
          <div class="result-meta">{{ p.brand }} · {{ p.category }} · 数据来源：Open Food Facts</div>
          <div class="result-reason">
            <span v-for="(r, i) in p.reasons" :key="i" :class="r.level">
              {{ r.level === 'hit' ? '✕' : (r.level === 'miss' ? '?' : '✓') }} {{ r.text }}
              <span v-if="i < p.reasons.length - 1">　</span>
            </span>
          </div>
          <button class="btn btn-sm" style="margin-top:10px" @click="toggleDetail(p.id)">
            {{ expanded.has(p.id) ? '收起配料表' : '查看配料表与详情' }}
          </button>
          <div v-if="expanded.has(p.id)" class="detail-text" style="margin-top:8px">
            <b>配料表（标签原文）：</b>{{ p.ingredients }}<br>
            <b>营养成分：</b>能量 {{ p.nutrition.energy }} · 脂肪 {{ p.nutrition.fat }} · 碳水 {{ p.nutrition.carbs }} · 钠 {{ p.nutrition.sodium }}<br>
            <b>添加剂说明：</b>
            <template v-if="p.additives.length">
              <span v-for="(a, i) in p.additives" :key="i">{{ a }}<span v-if="additiveKnowledge(a)">—— {{ additiveKnowledge(a) }}</span><span v-if="i < p.additives.length - 1">；</span></span>
            </template>
            <template v-else>无食品添加剂</template><br>
            <b>数据来源：</b>{{ p.sourceUrl }}
          </div>
        </div>
      </div>
    </div>

    <!-- 两款产品横向对比（FR-9.7） -->
    <div class="card" v-if="compareProducts.length === 2">
      <div class="card-title">选中产品对比</div>
      <table>
        <thead><tr><th>对比项</th><th v-for="p in compareProducts" :key="p.id">{{ p.name }}</th></tr></thead>
        <tbody>
          <tr><td>筛选结论</td><td v-for="p in compareProducts" :key="p.id"><span class="badge" :class="statusClass[p.status]">{{ statusText[p.status] }}</span></td></tr>
          <tr><td>品牌 / 品类</td><td v-for="p in compareProducts" :key="p.id">{{ p.brand }} · {{ p.category }}</td></tr>
          <tr><td>过敏原提示</td><td v-for="p in compareProducts" :key="p.id">{{ p.allergenLabeled ? (p.allergens.join('、') || '未标示') : '标签未标注' }}</td></tr>
          <tr><td>钠</td><td v-for="p in compareProducts" :key="p.id">{{ p.nutrition.sodium }}</td></tr>
          <tr><td>糖</td><td v-for="p in compareProducts" :key="p.id">{{ p.nutritionNum.sugar == null ? '未标注' : p.nutritionNum.sugar + ' g/100g' }}</td></tr>
          <tr><td>添加剂</td><td v-for="p in compareProducts" :key="p.id">{{ p.additives.join('、') || '无' }}</td></tr>
        </tbody>
      </table>
    </div>

    <div class="disclaimer">
      ⚠️ 本页结果基于公开标签数据的客观呈现，仅供选购参考，<b>不构成合规判定或健康建议，也不能替代专业营养指导</b>。
      "信息不足"表示标签未提供相应数据，不等于"适合"。
    </div>
  </div>
</template>
