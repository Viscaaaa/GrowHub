<template>
  <div class="page history-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">History Content</h1>
        <p class="page-subtitle">List of published knowledge contents you have recently opened and read.</p>
      </div>

      <router-link to="/feed" class="btn btn-outline">
        <BookOpen :size="16" />
        <span>Explore Feed</span>
      </router-link>
    </div>

    <div class="card card-pad mb-4">
      <div class="history-search-row">
        <div class="input-icon history-search-input">
          <Search :size="18" />
          <input
            v-model="searchQuery"
            @input="handleSearch"
            type="text"
            placeholder="Search opened content by title, keywords, or #tag..."
            class="input"
          />
        </div>
        <span v-if="!loading && pagination.total > 0" class="history-count-meta">
          {{ pagination.total }} {{ pagination.total === 1 ? 'content' : 'contents' }} viewed
        </span>
      </div>
    </div>

    <div v-if="loading">
      <ContentCardSkeleton :count="3" />
    </div>

    <div v-else-if="items.length > 0" class="stack">
      <div
        v-for="item in items"
        :key="item.id"
        class="history-entry"
      >
        <div v-if="item.last_viewed_at" class="history-viewed-bar">
          <History :size="13" class="text-primary" />
          <span>Opened {{ timeAgo(item.last_viewed_at) }}</span>
        </div>
        <ContentCard :item="item" />
      </div>

      <!-- Pagination -->
      <div v-if="pagination.last_page > 1" class="pagination-row mt-4">
        <button
          class="btn btn-outline btn-sm"
          :disabled="pagination.current_page <= 1"
          @click="fetchHistory(pagination.current_page - 1)"
        >
          <ChevronLeft :size="16" />
          <span>Previous</span>
        </button>

        <span class="small bold text-2">
          Page {{ pagination.current_page }} of {{ pagination.last_page }}
        </span>

        <button
          class="btn btn-outline btn-sm"
          :disabled="pagination.current_page >= pagination.last_page"
          @click="fetchHistory(pagination.current_page + 1)"
        >
          <span>Next</span>
          <ChevronRight :size="16" />
        </button>
      </div>
    </div>

    <div v-else class="card card-pad empty">
      <div class="empty-icon bg-green-50">
        <History :size="32" class="text-primary" />
      </div>
      <h3>{{ searchQuery ? 'No matching history found' : 'No history content yet' }}</h3>
      <p class="small muted">
        {{ searchQuery ? 'Try a different keyword or clear the search box.' : 'Contents you open from Home or Knowledge Feed will appear here for quick access.' }}
      </p>
      <button v-if="searchQuery" class="btn btn-outline btn-sm mt-3" @click="clearSearch">
        Clear Search
      </button>
      <router-link v-else to="/feed" class="btn btn-primary btn-sm mt-3">
        <span>Open Knowledge Feed</span>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { History, BookOpen, Search, ChevronLeft, ChevronRight } from 'lucide-vue-next'
import api from '@/api/client'
import ContentCard from '@/components/common/ContentCard.vue'
import ContentCardSkeleton from '@/components/common/ContentCardSkeleton.vue'

const loading = ref(true)
const items = ref([])
const searchQuery = ref('')
const pagination = ref({ current_page: 1, last_page: 1, total: 0 })

let searchTimer = null

const fetchHistory = async (page = 1) => {
  loading.value = true
  try {
    const params = { page }
    if (searchQuery.value.trim()) {
      params.q = searchQuery.value.trim()
    }
    const res = await api.get('/my/history', { params })
    items.value = res.data.data
    pagination.value = {
      current_page: res.data.current_page,
      last_page: res.data.last_page,
      total: res.data.total || 0,
    }
  } catch (err) {
    console.error('Failed to load content history', err)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    fetchHistory(1)
  }, 300)
}

const clearSearch = () => {
  searchQuery.value = ''
  fetchHistory(1)
}

const timeAgo = (dateStr) => {
  if (!dateStr) return ''
  const diff = (Date.now() - new Date(dateStr).getTime()) / 1000
  if (diff < 60) return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

onMounted(() => {
  fetchHistory(1)
})
</script>

<style scoped src="@/styles/features/history-content.css"></style>

