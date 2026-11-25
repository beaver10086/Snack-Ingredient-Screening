<script setup>
import { ref, onMounted } from 'vue'
import BarChart from '../components/BarChart.vue'
import { getStatsCharts } from '../api'

const charts = ref({ category: [], topAdditives: [], dataQuality: [] })
onMounted(async () => { charts.value = await getStatsCharts() })
</script>

<template>
  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">品类分布 <span class="sub">按数据源记录统计（FR-7.1）</span></div>
      <BarChart :items="charts.category" unit=" 条" />
    </div>
    <div class="card">
      <div class="card-title">数据质量指标 <span class="sub">FR-7.2 / G2</span></div>
      <BarChart :items="charts.dataQuality" unit="%" />
    </div>
  </div>

  <div class="card">
    <div class="card-title">高频添加剂排行 <span class="sub">product_ingredient 反向统计（FR-6.2）</span></div>
    <BarChart :items="charts.topAdditives.map(x => ({ ...x, color: 'var(--purple)' }))" />
  </div>

  <div class="card">
    <div class="card-title">数据报告 <span class="sub">FR-7.3 · 含方法与局限说明</span>
      <button class="btn btn-primary btn-sm" style="float:right">生成报告</button>
    </div>
    <div class="detail-text">
      报告结构：<b>数据来源</b>（Open Food Facts 开放 API 为主源，抽检公告做验证样本，电商公开页少量补充）→
      <b>方法</b>（采集限速退避 → 原始数据层留存 → 清洗去重 → 配料拆分与标准化 → 表驱动解读，规则版本 v1.0）→
      <b>数据范围</b>（截至 2026-11-25 共 386 条，配料非空率 94%，标准化覆盖 82%）→
      <b>结论</b>（品类与添加剂分布、高频成分排行）→
      <b>局限说明</b>（开放库中国产品覆盖有限，众包数据质量不一，按用户关注生成的提示仅作参考；
      系统<b>不做违法定性</b>，也不宣称国民零食全覆盖）。
    </div>
  </div>
</template>
