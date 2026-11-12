<template>
  <div class="page learning-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Learning Center</h1>
        <p class="page-subtitle">Enhance your skills with interactive micro-learning modules and earn extra points.</p>
      </div>

      <!-- Completion progress badge -->
      <div class="card card-pad py-2 row" style="gap: 12px;">
        <GraduationCap :size="24" class="text-primary" />
        <div>
          <template v-if="loading">
            <div class="skeleton sk-line" style="width: 130px;"></div>
            <div class="skeleton mt-1" style="width: 140px; height: 5px; border-radius: 999px;"></div>
          </template>
          <template v-else>
            <div class="bold small text-dark">{{ completedCount }} of {{ totalCount }} Completed</div>
            <div class="progress mt-1" style="width: 140px; height: 5px;">
              <span :style="{ width: `${totalCount ? (completedCount / totalCount) * 100 : 0}%` }"></span>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Category filter pills -->
    <div class="chips mb-4">
      <button
        class="chip"
        :class="{ active: selectedCategory === '' }"
        @click="selectedCategory = ''"
      >
        All Modules
      </button>
      <template v-if="loading">
        <div
          v-for="n in 4"
          :key="`sk-lc-cat-${n}`"
          class="skeleton sk-chip"
          :style="{ width: `${92 + (n % 2) * 28}px` }"
          aria-hidden="true"
        ></div>
      </template>
      <template v-else>
        <button
          v-for="cat in categories"
          :key="cat"
          class="chip"
          :class="{ active: selectedCategory === cat }"
          @click="selectedCategory = cat"
        >
          {{ cat }}
        </button>
      </template>
    </div>

    <!-- Courses Grid -->
    <div v-if="loading" class="grid grid-3 course-grid" aria-label="Loading courses">
      <div v-for="n in 3" :key="`sk-course-${n}`" class="card course-card">
        <div class="skeleton" style="height: 120px; border-radius: 0;"></div>
        <div class="card-pad course-content stack" style="gap: 10px;">
          <div class="row-between">
            <div class="skeleton sk-line-sm" style="width: 72px;"></div>
            <div class="skeleton sk-line" style="width: 68px;"></div>
          </div>
          <div class="skeleton sk-line-lg" style="width: 88%;"></div>
          <div class="skeleton sk-line" style="width: 100%;"></div>
          <div class="skeleton sk-line" style="width: 76%;"></div>
          <div class="row-between pt-2" style="border-top: 1px solid var(--border); margin-top: auto;">
            <div class="skeleton sk-line-sm" style="width: 82px;"></div>
            <div class="skeleton sk-line" style="width: 96px;"></div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="grid grid-3 course-grid">
      <router-link
        v-for="course in filteredCourses"
        :key="course.id"
        :to="`/learning/${course.slug}`"
        class="card card-hover course-card"
      >
        <!-- Card Cover Banner -->
        <div class="course-banner" :style="{ background: course.cover_color || '#1e8c45' }">
          <div class="row-between">
            <span class="badge badge-light-blur">{{ course.category }}</span>
            <span v-if="course.is_completed" class="badge badge-completed">
              <CheckCircle2 :size="12" />
              <span>Completed</span>
            </span>
          </div>
          <div class="course-banner-icon">
            <GraduationCap :size="32" class="text-white" />
          </div>
        </div>

        <div class="card-pad course-content">
          <div class="row-between mb-1">
            <span class="small bold text-2">{{ course.level }}</span>
            <div class="row small bold text-primary" style="gap: 4px;">
              <Sparkles :size="14" />
              <span>+{{ course.points_reward }} Pts</span>
            </div>
          </div>

          <h2 class="course-title clamp-2">{{ course.title }}</h2>
          <p class="course-summary clamp-2 small text-2 mb-3">{{ course.summary }}</p>

          <div class="row-between pt-2" style="border-top: 1px solid var(--border);">
            <div class="row small muted" style="gap: 4px;">
              <Clock :size="14" />
              <span>{{ course.duration_minutes }} min read</span>
            </div>
            <span class="btn btn-ghost btn-sm text-primary bold">
              <span>Open Module</span>
              <ChevronRight :size="14" />
            </span>
          </div>
        </div>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  GraduationCap, CheckCircle2, Sparkles, Clock, ChevronRight
} from 'lucide-vue-next'
import api from '@/api/client'

const loading = ref(true)
const courses = ref([])
const categories = ref([])
const selectedCategory = ref('')
const completedCount = ref(0)
const totalCount = ref(0)

const fetchCourses = async () => {
  loading.value = true
  try {
    const res = await api.get('/courses')
    courses.value = res.data.courses
    categories.value = res.data.categories
    completedCount.value = res.data.completed
    totalCount.value = res.data.total
  } catch (err) {
    console.error('Failed courses', err)
  } finally {
    loading.value = false
  }
}

const filteredCourses = computed(() => {
  if (!selectedCategory.value) return courses.value
  return courses.value.filter((c) => c.category === selectedCategory.value)
})

onMounted(() => {
  fetchCourses()
})
</script>

<style scoped src="@/styles/features/learning-center.css"></style>
