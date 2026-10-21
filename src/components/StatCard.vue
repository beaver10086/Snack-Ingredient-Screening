<script setup>
import SeverityBadge from './SeverityBadge.vue'

defineProps({
  label: { type: String, required: true },
  value: { type: [Number, String], required: true },
  delta: { type: String, default: '' },
  badgeText: { type: String, default: '' },
})
</script>

<template>
  <div class="card stat-card">
    <div class="label">{{ label }}</div>
    <div class="num">{{ value }}</div>
    <div class="delta">
      <SeverityBadge v-if="badgeText || delta" :text="badgeText || delta" />
    </div>
  </div>
</template>
