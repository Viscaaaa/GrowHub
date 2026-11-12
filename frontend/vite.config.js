import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

function createBackendProxy(target) {
  return {
    target,
    changeOrigin: true,
    configure: (proxy) => {
      proxy.on('error', (_err, _req, res) => {
        if (!res || typeof res.writeHead !== 'function') {
          return
        }
        if (!res.headersSent) {
          res.writeHead(502, { 'Content-Type': 'application/json' })
        }
        if (!res.writableEnded) {
          res.end(
            JSON.stringify({
              message: `Cannot connect to GrowHub backend at ${target}. Make sure the Laravel server is running on port 8001.`,
            }),
          )
        }
      })
    },
  }
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, fileURLToPath(new URL('.', import.meta.url)), '')
  const backendTarget = env.VITE_BACKEND_URL || 'http://127.0.0.1:8001'

  return {
    plugins: [vue()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
    server: {
      port: 5174,
      proxy: {
        '/api': createBackendProxy(backendTarget),
        '/storage': createBackendProxy(backendTarget),
      },
    },
  }
})
