import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Dev proxy so `/api/ucf-parking` returns JSON locally (same as production)
      '/api/ucf-parking': {
        target: 'https://secure.parking.ucf.edu',
        changeOrigin: true,
        secure: true,
        rewrite: (path) => path.replace(/^\/api\/ucf-parking/, '/GarageCounter/GetOccupancy'),
      },
    },
  },
})
