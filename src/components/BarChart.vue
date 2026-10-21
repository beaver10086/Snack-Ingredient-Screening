<script setup>
const props = defineProps({
  // [{ label, value, color? }] 或 [{ label, pct }]
  items: { type: Array, required: true },
  unit: { type: String, default: '' },
})

function rowStyle(x) {
  const max = Math.max(...props.items.map(v => v.value ?? v.pct))
  const w = ((x.value ?? x.pct) / max) * 100
  return { width: w + '%', background: x.color || 'var(--primary)' }
}
function rowText(x) {
  return (x.value ?? x.pct) + props.unit
}
</script>

<template>
  <div>
    <div v-for="(x, i) in items" :key="i" class="bar-row">
      <div class="bar-label">{{ x.label }}</div>
      <div class="bar-track">
        <div class="bar-fill" :style="rowStyle(x)"></div>
      </div>
      <div class="bar-value">{{ rowText(x) }}</div>
    </div>
  </div>
</template>
