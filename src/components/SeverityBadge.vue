<script setup>
defineProps({
  text: { type: String, required: true },
})
// 与原版 badge() 映射一致：状态/严重程度 → 配色
const MAP = {
  '违规': 'b-danger', '失败': 'b-danger', '不合格': 'b-danger',
  '疑似': 'b-warning', '运行中': 'b-warning', '未复核': 'b-warning',
  '提示': 'b-info', '成功': 'b-success', '现行': 'b-success', '正常': 'b-success', '确认': 'b-success',
  '即将实施': 'b-purple', '误报': 'b-gray',
}
</script>

<template>
  <span class="badge" :class="MAP[text] || 'b-gray'">{{ text }}</span>
</template>
