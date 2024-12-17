import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
// export default defineConfig({
//   base: process.env.NODE_ENV === 'production' ? 'react-practice' : '/',
//   plugins: [react()],
// })

//使用vite內建功能mode指令判斷運行模式 但是需要先用回調函式導入
export default defineConfig(({ mode })=> {

  return {
    base: mode === 'production' ? 'react-practice' : '/',
    plugins: [react()],
  }
})

