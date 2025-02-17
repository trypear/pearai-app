import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
// import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    lib: {
      entry: 'src/index.ts', // We'll create this
      formats: ['es'],
      fileName: 'index'
    },
    outDir: '../out', // Output to the VS Code extension's out directory
    rollupOptions: {
      external: [
        'react',
        'react-dom',
        /^vs\/.*/  // Keep VS Code imports external
      ]
    }
  },
  server: {
    watch: {
      ignored: ['!**/node_modules/**']
    }
  }
})
