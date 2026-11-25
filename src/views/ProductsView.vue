<script setup>
import { ref, computed, onMounted } from 'vue'
import { getProducts } from '../api'

const products = ref([])
const keyword = ref('')
const category = ref('全部品类')
const additive = ref('全部添加剂')
const expanded = ref(new Set())
const compare = ref([])   // 产品对比选择（FR-6.3）

onMounted(async () => { products.value = await getProducts() })

const CATEGORIES = ['全部品类', '膨化食品', '肉类零食', '饼干糕点', '糖果巧克力', '坚果炒货']
const ADDITIVES = ['全部添加剂', 'TBHQ', '脱氢乙酸钠', '三氯蔗糖', '大豆磷脂', '无添加剂']

// FR-6.1 关键词检索 + FR-6.2 反向检索（按添加剂/配料）
const filtered = computed(() =>
  products.value.filter(p => {
    const kw = keyword.value.trim()
    const okKw = !kw || p.name.includes(kw) || p.barcode.includes(kw) || p.brand.includes(kw) || p.ingredients.includes(kw)
    const okCat = category.value === '全部品类' || p.category === category.value
    const okAdd = additive.value === '全部添加剂'
      || (additive.value === '无添加剂' ? p.additives.length === 0 : p.additives.includes(additive.value))
    return okKw && okCat && okAdd
  })
)

function toggle(id) {
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

// 对比表：选出两款产品后横向展示配料与营养差异
const compareProducts = computed(() => compare.value.map(id => products.value.find(p => p.id === id)).filter(Boolean))
</script>

<template>
  <div class="card">
    <div class="search-bar">
      <input v-model="keyword" type="text" placeholder="产品名 / 条码 / 品牌 / 配料关键词…">
      <select v-model="category">
        <option v-for="c in CATEGORIES" :key="c" :value="c">{{ c }}</option>
      </select>
      <select v-model="additive">
        <option v-for="a in ADDITIVES" :key="a" :value="a">{{ a }}</option>
      </select>
      <button class="btn btn-primary">检索</button>
      <button class="btn">导出 CSV</button>
    </div>
    <div class="detail-text">
      FR-6.1 按名称/品牌/品类/条码/配料检索 · FR-6.2 反向检索（按添加剂查产品）。
      每条产品可追溯到来源 URL（G6）。
    </div>

    <table>
      <thead><tr><th>对比</th><th>产品</th><th>条码 GTIN</th><th>品牌</th><th>品类</th><th>添加剂</th><th>致敏原</th><th>来源</th><th>操作</th></tr></thead>
      <tbody>
        <template v-for="p in filtered" :key="p.id">
          <tr>
            <td><input type="checkbox" :checked="compare.includes(p.id)" @change="toggleCompare(p.id)" title="加入对比（最多两款）"></td>
            <td>{{ p.name }}</td><td>{{ p.barcode }}</td><td>{{ p.brand }}</td>
            <td><span class="badge b-gray">{{ p.category }}</span></td>
            <td>{{ p.additives.length ? p.additives.join('、') : '无' }}</td>
            <td>{{ p.allergens.length ? p.allergens.join('、') : '无' }}</td>
            <td>{{ p.sources }}</td>
            <td><button class="btn btn-sm" @click="toggle(p.id)">配料表</button></td>
          </tr>
          <tr v-if="expanded.has(p.id)">
            <td colspan="9">
              <div class="detail-text">
                <b>label_info.ingredient_text（采用值）：</b><br>{{ p.ingredients }}<br>
                <b>营养成分：</b>能量 {{ p.nutrition.energy }} · 脂肪 {{ p.nutrition.fat }} · 碳水 {{ p.nutrition.carbs }} · 钠 {{ p.nutrition.sodium }}<br>
                <b>来源：</b>{{ p.sourceUrl }}
              </div>
            </td>
          </tr>
        </template>
        <tr v-if="!filtered.length"><td colspan="9" class="empty">无匹配产品</td></tr>
      </tbody>
    </table>
    <div class="pager">共 {{ filtered.length }} 条（演示数据） · 勾选两款产品可横向对比</div>
  </div>

  <div class="card" v-if="compareProducts.length">
    <div class="card-title">产品横向对比 <span class="sub">FR-6.3 · 配料与营养比一比</span></div>
    <table>
      <thead>
        <tr><th>对比项</th><th v-for="p in compareProducts" :key="p.id">{{ p.name }}</th></tr>
      </thead>
      <tbody>
        <tr><td>品牌</td><td v-for="p in compareProducts" :key="p.id">{{ p.brand }}</td></tr>
        <tr><td>配料项数</td><td v-for="p in compareProducts" :key="p.id">{{ p.ingredientCount }}</td></tr>
        <tr><td>添加剂</td><td v-for="p in compareProducts" :key="p.id">{{ p.additives.length ? p.additives.join('、') : '无' }}</td></tr>
        <tr><td>致敏原</td><td v-for="p in compareProducts" :key="p.id">{{ p.allergens.length ? p.allergens.join('、') : '无' }}</td></tr>
        <tr><td>能量</td><td v-for="p in compareProducts" :key="p.id">{{ p.nutrition.energy }}</td></tr>
        <tr><td>钠</td><td v-for="p in compareProducts" :key="p.id">{{ p.nutrition.sodium }}</td></tr>
        <tr><td>配料表</td><td v-for="p in compareProducts" :key="p.id" style="font-size:12px">{{ p.ingredients }}</td></tr>
      </tbody>
    </table>
  </div>
</template>
