<script setup>
import { ref, onMounted } from 'vue'
import BarChart from '../components/BarChart.vue'
import { getStatsCharts } from '../api'

const charts = ref({ problemType: [], byCategory: [], topAdditives: [] })
onMounted(async () => { charts.value = await getStatsCharts() })
</script>

<template>
  <div class="grid grid-2">
    <div class="card">
      <div class="card-title">问题类型分布 <span class="sub">FR-7.1</span></div>
      <BarChart :items="charts.problemType" unit=" 条" />
    </div>
    <div class="card">
      <div class="card-title">各品类问题占比 <span class="sub">按品类</span></div>
      <BarChart :items="charts.byCategory" unit="%" />
    </div>
  </div>

  <div class="card">
    <div class="card-title">高频添加剂排行 <span class="sub">product_ingredient 反向统计（FR-6.2）</span></div>
    <BarChart :items="charts.topAdditives.map(x => ({ ...x, color: 'var(--purple)' }))" />
  </div>

  <div class="card">
    <div class="card-title">筛查报告 <span class="sub">FR-7.3</span>
      <button class="btn btn-primary btn-sm" style="float:right">生成报告</button>
    </div>
    <div class="detail-text">
      报告结构：<b>方法</b>（规则版本 v1.3 · R1–R6）→ <b>数据范围</b>（截至 2026-10-21 共 2,146 件，4 类数据源）→
      <b>结论</b>（违规 42 / 疑似 96 / 提示 48，准确率抽样复核 84%）→
      <b>局限说明</b>（配料表无含量数据的「超标」不可判定；电商数据依赖 OCR，识别错误进入人工复核；结论不构成违法定性）。
    </div>
  </div>
</template>
