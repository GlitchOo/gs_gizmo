import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  base: "./",
  plugins: [react()],
  build: {
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.indexOf('node_modules') >= 0) {
            if (id.indexOf('@react-three') >= 0) {
              return 'index-react-three';
            }
            if (id.indexOf('three') >= 0) {
              return 'index-threejs';
            }
            if (id.indexOf('react') >= 0 || id.indexOf('react-dom') >= 0) {
              return 'index-react';
            }
            return 'index';
          }
        },
      },
    },
  },
})
