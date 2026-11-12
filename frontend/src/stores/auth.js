import { defineStore } from 'pinia'
import api from '@/api/client'

function extractLoginErrorMessage(err) {
  if (!err?.response) {
    return 'Cannot connect to the GrowHub server. Please ensure the backend API is running on port 8001.'
  }

  const { status, data } = err.response
  if (status === 404) {
    return 'Login endpoint was not found on the API server (HTTP 404). Please verify the API points to GrowHub backend (port 8001).'
  }
  if (status >= 500) {
    return data?.message || `Server error while logging in (HTTP ${status}). Please verify the GrowHub backend is running.`
  }

  return data?.message || data?.errors?.nip?.[0] || 'Login failed. Please check your Employee ID and password.'
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: JSON.parse(localStorage.getItem('growhub_user') || 'null'),
    token: localStorage.getItem('growhub_token') || null,
    showEthicsModal: sessionStorage.getItem('growhub_show_ethics') === '1',
    loading: false,
    initialized: false,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token && !!state.user,
    isReviewer: (state) => state.user?.role === 'reviewer' || state.user?.role === 'admin',
    isAdmin: (state) => state.user?.role === 'admin',
    userPoints: (state) => state.user?.points || 0,
    userStreak: (state) => state.user?.current_streak || 0,
    userLevel: (state) => state.user?.level_info || { level: 1, name: 'Seedling', progress: 0 },
  },

  actions: {
    async login(nip, password) {
      this.loading = true
      try {
        const res = await api.post('/auth/login', { nip, password })
        this.token = res.data.token
        this.user = res.data.user
        localStorage.setItem('growhub_token', this.token)
        localStorage.setItem('growhub_user', JSON.stringify(this.user))
        this.triggerEthicsNotice()
        return { success: true }
      } catch (err) {
        return { success: false, message: extractLoginErrorMessage(err) }
      } finally {
        this.loading = false
      }
    },

    async fetchMe() {
      if (!this.token) return
      try {
        const res = await api.get('/auth/me')
        this.user = res.data
        localStorage.setItem('growhub_user', JSON.stringify(this.user))
      } catch (err) {
        console.error('Fetch me failed', err)
      } finally {
        this.initialized = true
      }
    },

    async logout() {
      try {
        await api.post('/auth/logout')
      } catch (e) {
        // ignore
      } finally {
        this.token = null
        this.user = null
        this.acknowledgeEthicsNotice()
        localStorage.removeItem('growhub_token')
        localStorage.removeItem('growhub_user')
      }
    },

    triggerEthicsNotice() {
      this.showEthicsModal = true
      sessionStorage.setItem('growhub_show_ethics', '1')
    },

    acknowledgeEthicsNotice() {
      this.showEthicsModal = false
      sessionStorage.removeItem('growhub_show_ethics')
    },

    updateUser(userData) {
      this.user = { ...this.user, ...userData }
      localStorage.setItem('growhub_user', JSON.stringify(this.user))
    },

    mutatePoints(delta) {
      if (!this.user) return
      this.user.points = Math.max(0, (this.user.points || 0) + delta)
      // re-fetch fresh user info in background for level re-calculation
      this.fetchMe()
    },
  },
})
