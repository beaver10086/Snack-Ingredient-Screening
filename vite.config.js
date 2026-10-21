import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    // 后端就绪后在此配置代理，例如：
    // proxy: { '/api': 'http://localhost:8080' }
  },
})
