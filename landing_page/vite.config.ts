import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/Agentic-Ops-Dev/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  },
})
