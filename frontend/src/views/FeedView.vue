<template>
  <div class="page feed-page">
    <!-- Header -->
    <div class="page-header">
      <div>
        <h1 class="page-title">Knowledge Feed</h1>
        <p class="page-subtitle">Explore knowledge, innovative ideas, and best practices shared by colleagues.</p>
      </div>

      <router-link to="/create" class="btn btn-primary">
        <Plus :size="18" />
        <span>Create Content</span>
      </router-link>
    </div>

    <!-- Filter & Search Controls Bar -->
    <div class="card card-pad feed-controls-card mb-4">
      <!-- Search Input -->
      <div class="feed-search-row">
        <div class="input-icon search-input-wrapper">
          <Search :size="18" />
          <input
            v-model="searchQuery"
            @input="handleSearch"
            type="text"
            placeholder="Search by title, keywords, or #tag..."
            class="input"
          />
        </div>

        <!-- Sort Select -->
        <div class="sort-wrapper">
          <select v-model="selectedSort" @change="fetchFeed(1)" class="select">
            <option value="latest">Latest</option>
            <option value="popular">Most Liked (Popular)</option>
            <option value="trending">Trending Now</option>
          </select>
        </div>
      </div>

      <!-- Categories Chips -->
      <div class="filter-chips-section mt-3">
        <div class="chips-scroll">
          <button
            class="chip"
            :class="{ active: selectedCategory === '' }"
            @click="selectCategory('')"
          >
            <span>All Topics</span>
          </button>
          <template v-if="categoriesLoading">
            <div
              v-for="n in 5"
              :key="`sk-cat-${n}`"
              class="skeleton sk-chip"
              :style="{ width: `${94 + (n % 3) * 26}px` }"
              aria-hidden="true"
            ></div>
          </template>
          <template v-else>
            <button
              v-for="cat in categories"
              :key="cat.id"
              class="chip"
              :class="{ active: selectedCategory === cat.slug }"
              @click="selectCategory(cat.slug)"
            >
              <span>{{ cat.name }}</span>
              <span v-if="cat.contents_count > 0" class="chip-count">{{ cat.contents_count }}</span>
            </button>
          </template>
        </div>
      </div>

      <!-- Media Type Filter Sub-row -->
      <div class="media-filter-row mt-3">
        <span class="small bold muted">Media Type:</span>
        <div class="media-pills">
          <button
            class="media-pill"
            :class="{ active: selectedMedia === '' }"
            @click="selectMedia('')"
          >
            All
          </button>
          <button
            class="media-pill"
            :class="{ active: selectedMedia === 'image' }"
            @click="selectMedia('image')"
          >
            <Image :size="14" />
            <span>Photos / Images</span>
          </button>
          <button
            class="media-pill"
            :class="{ active: selectedMedia === 'video' }"
            @click="selectMedia('video')"
          >
            <Video :size="14" />
            <span>Video Sharing</span>
          </button>
          <button
            class="media-pill"
            :class="{ active: selectedMedia === 'document' }"
            @click="selectMedia('document')"
          >
            <FileText :size="14" />
            <span>Documents / SOP</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Active filter summary -->
    <div v-if="activeFilterText" class="active-filter-alert mb-3">
      <span>Showing results for: <strong>{{ activeFilterText }}</strong></span>
      <button class="btn btn-ghost btn-sm" @click="resetFilters">Reset Filters</button>
    </div>

    <!-- Feed Content List -->
    <div v-if="loading">
      <ContentCardSkeleton :count="3" />
    </div>

    <div v-else-if="items.length > 0" class="stack feed-list">
      <ContentCard
        v-for="item in items"
        :key="item.id"
        :item="item"
      />

      <!-- Pagination -->
      <div v-if="pagination.last_page > 1" class="pagination-row mt-4">
        <button
          class="btn btn-outline btn-sm"
          :disabled="pagination.current_page <= 1"
          @click="fetchFeed(pagination.current_page - 1)"
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
          @click="fetchFeed(pagination.current_page + 1)"
        >
          <span>Next</span>
          <ChevronRight :size="16" />
        </button>
      </div>
    </div>

    <div v-else class="card card-pad empty">
      <div class="empty-icon">
        <Search :size="32" />
      </div>
      <h3>No content found</h3>
      <p class="small muted">Try using different keywords or clear your category filter.</p>
      <button class="btn btn-outline btn-sm mt-3" @click="resetFilters">
        Reset All Filters
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  Plus, Search, Image, Video, FileText, ChevronLeft, ChevronRight
} from 'lucide-vue-next'
import api from '@/api/client'
import ContentCard from '@/components/common/ContentCard.vue'
import ContentCardSkeleton from '@/components/common/ContentCardSkeleton.vue'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const categoriesLoading = ref(true)
const items = ref([])
const categories = ref([])
const pagination = ref({ current_page: 1, last_page: 1 })

const isTruthyQuery = (val) => val === '1' || val === 'true' || val === true

const searchQuery = ref(route.query.q || '')
const selectedCategory = ref(route.query.category || '')
const selectedMedia = ref(route.query.media || '')
const selectedSort = ref(route.query.sort || 'latest')
const historyOnly = ref(isTruthyQuery(route.query.history))

let searchTimer = null

const activeFilterText = computed(() => {
  const parts = []
  if (historyOnly.value) {
    parts.push('Recently Viewed')
  }
  if (selectedCategory.value) {
    const cat = categories.value.find((c) => c.slug === selectedCategory.value)
    if (cat) parts.push(`Category: ${cat.name}`)
  }
  if (selectedMedia.value) {
    parts.push(`Media: ${selectedMedia.value}`)
  }
  if (searchQuery.value) {
    parts.push(`Keyword: "${searchQuery.value}"`)
  }
  return parts.join(' • ')
})

const fetchCategories = async () => {
  categoriesLoading.value = true
  try {
    const res = await api.get('/categories')
    categories.value = res.data
  } catch (err) {
    console.error('Failed categories', err)
  } finally {
    categoriesLoading.value = false
  }
}

const fetchFeed = async (page = 1) => {
  loading.value = true
  try {
    const params = {
      page,
      sort: selectedSort.value,
    }
    if (historyOnly.value) params.history = 1
    if (searchQuery.value) params.q = searchQuery.value
    if (selectedCategory.value) params.category = selectedCategory.value
    if (selectedMedia.value) params.media = selectedMedia.value

    const res = await api.get('/contents', { params })
    items.value = res.data.data
    pagination.value = {
      current_page: res.data.current_page,
      last_page: res.data.last_page,
    }
  } catch (err) {
    console.error('Failed feed', err)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    fetchFeed(1)
  }, 350)
}

const selectCategory = (slug) => {
  selectedCategory.value = slug
  fetchFeed(1)
}

const selectMedia = (type) => {
  selectedMedia.value = type
  fetchFeed(1)
}

const resetFilters = () => {
  searchQuery.value = ''
  selectedCategory.value = ''
  selectedMedia.value = ''
  selectedSort.value = 'latest'
  historyOnly.value = false
  if (Object.keys(route.query).length > 0) {
    router.replace({ path: '/feed' })
  } else {
    fetchFeed(1)
  }
}

watch(
  () => route.query,
  (newQ) => {
    searchQuery.value = newQ.q || ''
    selectedCategory.value = newQ.category || ''
    selectedMedia.value = newQ.media || ''
    selectedSort.value = newQ.sort || 'latest'
    historyOnly.value = isTruthyQuery(newQ.history)
    fetchFeed(1)
  }
)

onMounted(async () => {
  await Promise.all([fetchCategories(), fetchFeed(1)])
})
</script>

<style scoped src="@/styles/features/feed.css"></style>
