import axios from 'axios'

const defaultBaseURL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: defaultBaseURL,
  headers: {
    'Accept': 'application/json',
  },
})

// Attach Bearer token if present
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('growhub_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle unauthorized responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('growhub_token')
      localStorage.removeItem('growhub_user')
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api
