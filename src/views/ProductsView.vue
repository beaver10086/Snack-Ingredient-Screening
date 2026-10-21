<script setup>
import { ref, computed, onMounted } from 'vue'
import { getProducts } from '../api'

const products = ref([])
const keyword = ref('')
const category = ref('全部品类')
const additive = ref('全部添加剂')
const expanded = ref(new Set())

onMounted(async () => { products.value = await getProducts() })

const CATEGORIES = ['全部品类', '膨化食品', '肉类零食', '饼干糕点', '糖果巧克力', '坚果炒货']
const ADDITIVES = ['全部添加剂', '含山梨酸钾', '含柠檬黄', '含 TBHQ']

// 真实过滤：关键词（名称/条码/品牌）+ 品类
const filtered = computed(() =>
  products.value.filter(p => {
    const kw = keyword.value.trim()
    const okKw = !kw || p.name.includes(kw) || p.barcode.includes(kw) || p.brand.includes(kw)
    const okCat = category.value === '全部品类' || p.category === category.value
    return okKw && okCat
  })
)

// 演示用配料原文（后端就绪后由 label_info.ingredient_text 提供）
const INGREDIENT_EXAMPLES = {
  '膨化食品': '马铃薯、植物油（精炼棕榈油）、食用盐、白砂糖、味精、食品添加剂（抗氧化剂（TBHQ）、柠檬黄）、食用香精',
  '肉类零食': '小麦粉、水、植物油、食用盐、白砂糖、辣椒、食品添加剂（防腐剂（脱氢乙酸钠）、甜味剂（三氯蔗糖））、食用香精',
  '饼干糕点': '小麦粉、白砂糖、植物油、可可粉、葡萄糖浆、全脂乳粉、食品添加剂（膨松剂（碳酸氢钠）、乳化剂（大豆磷脂））、食盐',
  '糖果巧克力': '白砂糖、奶粉、氢化植物油、明胶、食品添加剂（乳化剂（单硬脂酸甘油酯）、食用香精）',
  '坚果炒货': '扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干',
}

function toggle(id) {
  const s = new Set(expanded.value)
  s.has(id) ? s.delete(id) : s.add(id)
  expanded.value = s
}
</script>

<template>
  <div class="card">
    <div class="search-bar">
      <input v-model="keyword" type="text" placeholder="产品名 / 条码 / 品牌…">
      <select v-model="category">
        <option v-for="c in CATEGORIES" :key="c" :value="c">{{ c }}</option>
      </select>
      <select v-model="additive">
        <option v-for="a in ADDITIVES" :key="a" :value="a">{{ a }}</option>
      </select>
      <button class="btn btn-primary">检索</button>
      <button class="btn">导出 CSV</button>
    </div>

    <table>
      <thead><tr><th>产品</th><th>条码 GTIN</th><th>品牌</th><th>品类</th><th>GB 2760 分类</th><th>来源数</th><th>配料项</th><th>操作</th></tr></thead>
      <tbody>
        <template v-for="p in filtered" :key="p.id">
          <tr>
            <td>{{ p.name }}</td><td>{{ p.barcode }}</td><td>{{ p.brand }}</td>
            <td><span class="badge b-gray">{{ p.category }}</span></td>
            <td>{{ p.gb }}</td><td>{{ p.sources }}</td><td>{{ p.ingredientCount }}</td>
            <td><button class="btn btn-sm" @click="toggle(p.id)">配料表</button></td>
          </tr>
          <tr v-if="expanded.has(p.id)">
            <td colspan="8">
              <div class="detail-text">
                <b>label_info.ingredient_text（采用值）：</b><br>
                {{ INGREDIENT_EXAMPLES[p.category] || '—' }}
              </div>
            </td>
          </tr>
        </template>
        <tr v-if="!filtered.length"><td colspan="8" class="empty">无匹配产品</td></tr>
      </tbody>
    </table>
    <div class="pager">共 {{ filtered.length }} 条（演示数据） · 每页 10 条</div>
  </div>
</template>
