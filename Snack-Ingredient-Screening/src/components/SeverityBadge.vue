<script setup>
defineProps({
  text: { type: String, required: true },
})
// V2.0 三级表述：客观事实 / 知识科普 / 个人提示（NFR-10）
// 其余为通用状态徽章配色
const MAP = {
  // 解读结果三级
  '客观事实': 'b-info', '知识科普': 'b-purple', '个人提示': 'b-warning',
  // 通用状态
  '成功': 'b-success', '启用': 'b-success', '正常': 'b-success', '现行': 'b-success', '确认': 'b-success',
  '运行中': 'b-warning', '待确认': 'b-warning',
  '失败': 'b-danger',
  '停用': 'b-gray',
  // 关注规则类型
  '过敏原': 'b-warning', '营养阈值': 'b-info',
}
</script>

<template>
  <span class="badge" :class="MAP[text] || 'b-gray'">{{ text }}</span>
</template>
