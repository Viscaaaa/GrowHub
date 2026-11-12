<template>
  <div class="page home-page">
    <!-- Hero Banner + Top This Week Side-by-Side -->
    <div class="hero-top-grid">
      <div class="card card-dark hero-card">
        <div class="hero-content">
          <div class="hero-badge">
            <Sparkles :size="15" />
            <span>GrowHub Gamification</span>
          </div>
          <h1 class="hero-title">
            Hello, {{ authStore.user?.name }}! 🌱
          </h1>
          <p class="hero-desc">
            Share ideas, field tips, or standard operating procedures today to help colleagues grow while earning points and keeping your streak alive!
          </p>

          <div class="hero-stats-row">
            <div class="hero-stat-box">
              <span class="hero-stat-label">Total Points</span>
              <span class="hero-stat-val">{{ formatNumber(authStore.userPoints) }} Pts</span>
            </div>
            <div class="hero-stat-box">
              <span class="hero-stat-label">Daily Streak</span>
              <span class="hero-stat-val">🔥 {{ authStore.userStreak }} Days</span>
            </div>
            <div class="hero-stat-box">
              <span class="hero-stat-label">Your Rank</span>
              <span class="hero-stat-val">#{{ homeData.my_rank || '-' }}</span>
            </div>
          </div>

          <div class="hero-actions">
            <router-link to="/create" class="btn btn-primary btn-lg shadow-green">
              <Plus :size="18" />
              <span>Share Knowledge & Ideas</span>
            </router-link>
            <router-link to="/feed" class="btn btn-outline btn-lg text-white" style="background: rgba(255,255,255,0.1); border-color: rgba(255,255,255,0.3); color: #fff;">
              <Compass :size="18" />
              <span>Explore Feed</span>
            </router-link>
          </div>
        </div>
      </div>

      <!-- Right Side beside Hero: Top This Week + Current Level -->
      <div class="hero-side-stack">
        <!-- Weekly Leaderboard Widget -->
        <div class="card card-pad leaderboard-widget">
          <div class="row-between mb-2">
            <div class="row" style="gap: 8px;">
              <Trophy :size="17" class="text-amber" />
              <span class="card-title" style="font-size: 15px;">Top This Week</span>
            </div>
            <router-link to="/leaderboard" class="small bold text-primary">
              All
            </router-link>
          </div>

          <div v-if="loading" class="leader-list" aria-label="Loading Top This Week">
            <div v-for="n in 5" :key="`sk-leader-${n}`" class="leader-row leader-row-skeleton">
              <div class="skeleton" style="width: 18px; height: 18px; border-radius: 50%; flex-shrink: 0;"></div>
              <div class="skeleton" style="width: 26px; height: 26px; border-radius: 50%; flex-shrink: 0;"></div>
              <div class="leader-info">
                <div class="skeleton" style="width: 72%; height: 12px; border-radius: 4px; margin-bottom: 4px;"></div>
                <div class="skeleton" style="width: 46%; height: 10px; border-radius: 4px;"></div>
              </div>
              <div class="skeleton" style="width: 40px; height: 14px; border-radius: 5px; flex-shrink: 0;"></div>
            </div>
          </div>

          <div v-else-if="homeData.top_weekly?.length > 0" class="leader-list">
            <div
              v-for="(leader, idx) in homeData.top_weekly.slice(0, 5)"
              :key="leader.id"
              class="leader-row"
            >
              <div class="leader-rank" :class="`rank-${idx + 1}`">
                {{ idx + 1 }}
              </div>
              <router-link :to="`/profile/${leader.id}`" class="avatar" style="width: 26px; height: 26px; font-size: 10px;">
                <img v-if="leader.avatar_url" :src="leader.avatar_url" :alt="leader.name" />
                <span v-else>{{ initials(leader.name) }}</span>
              </router-link>
              <div class="leader-info">
                <router-link :to="`/profile/${leader.id}`" class="leader-name hover-green">
                  {{ leader.name }}
                </router-link>
                <span class="leader-dept">{{ leader.department || 'Employee' }}</span>
              </div>
              <div class="leader-score">
                <span class="leader-score-val">{{ leader.score }}</span>
                <span class="leader-score-unit">Pts</span>
              </div>
            </div>
          </div>

          <div v-else class="leader-empty small muted">
            Belum ada aktivitas minggu ini.
          </div>
        </div>

        <!-- Gamification Level Progression Card (below Top This Week) -->
        <div class="card card-pad level-compact-card bg-subtle">
          <template v-if="loading">
            <div class="row" style="gap: 10px;">
              <div class="skeleton" style="width: 34px; height: 34px; border-radius: 10px; flex-shrink: 0;"></div>
              <div style="flex: 1; min-width: 0;">
                <div class="skeleton" style="width: 72px; height: 12px; border-radius: 4px; margin-bottom: 5px;"></div>
                <div class="skeleton" style="width: 140px; height: 16px; border-radius: 5px;"></div>
              </div>
            </div>
            <div class="skeleton mt-2" style="width: 100%; height: 8px; border-radius: 999px;"></div>
            <div class="row-between mt-2">
              <div class="skeleton" style="width: 74px; height: 13px; border-radius: 4px;"></div>
              <div class="skeleton" style="width: 84px; height: 13px; border-radius: 4px;"></div>
            </div>
          </template>

          <template v-else>
            <div class="row" style="gap: 10px;">
              <div class="level-badge-circle">
                <Award :size="18" class="text-primary" />
              </div>
              <div>
                <div class="small muted" style="font-size: 11px;">Current Level</div>
                <div class="bold text-dark" style="font-size: 13.5px;">Level {{ authStore.userLevel.level }} – {{ authStore.userLevel.name }}</div>
              </div>
            </div>

            <div class="progress mt-2">
              <span :style="{ width: `${authStore.userLevel.progress}%` }"></span>
            </div>

            <div class="row-between small muted mt-2" style="font-size: 11.5px;">
              <span>{{ authStore.userPoints }} Pts total</span>
              <span v-if="authStore.userLevel.points_to_next > 0">
                {{ authStore.userLevel.points_to_next }} Pts to Lv.{{ authStore.userLevel.next_level }}
              </span>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Company Stats Counter -->
    <!-- <div class="grid grid-4 stats-grid mt-4">
      <div class="card card-pad stat">
        <div class="stat-icon bg-green-50">
          <BookOpen :size="22" class="text-primary" />
        </div>
        <div>
          <div class="stat-value">{{ homeData.stats?.published_contents || 0 }}</div>
          <div class="stat-label">Published Contents</div>
        </div>
      </div>

      <div class="card card-pad stat">
        <div class="stat-icon bg-amber-50">
          <Award :size="22" class="text-amber" />
        </div>
        <div>
          <div class="stat-value">{{ homeData.stats?.contributors || 0 }}</div>
          <div class="stat-label">Active Contributors</div>
        </div>
      </div>

      <div class="card card-pad stat">
        <div class="stat-icon bg-blue-50">
          <Users :size="22" class="text-blue" />
        </div>
        <div>
          <div class="stat-value">{{ homeData.stats?.employees || 0 }}</div>
          <div class="stat-label">Registered Employees</div>
        </div>
      </div>

      <div class="card card-pad stat">
        <div class="stat-icon bg-green-50">
          <TrendingUp :size="22" class="text-primary" />
        </div>
        <div>
          <div class="stat-value">{{ homeData.stats?.contents_this_week || 0 }}</div>
          <div class="stat-label">New Ideas This Week</div>
        </div>
      </div>
    </div> -->

    <!-- Categories Compact Single-Row Strip with Horizontal Arrows -->
    <div class="section-container mt-4">
      <div class="mb-2">
        <h2 class="card-title">Knowledge Categories</h2>
      </div>

      <div class="categories-carousel">
        <button
          v-if="!loading && canScrollCatLeft"
          type="button"
          class="cat-scroll-btn"
          @click="scrollCategories(-1)"
          aria-label="Scroll categories left"
        >
          <ChevronLeft :size="16" />
        </button>

        <div
          ref="catStripRef"
          class="categories-strip"
          @scroll="updateCatScrollState"
        >
          <template v-if="loading">
            <div
              v-for="n in 8"
              :key="`sk-cat-${n}`"
              class="cat-pill-tile cat-pill-skeleton"
              aria-hidden="true"
            >
              <div class="skeleton cat-pill-icon-skeleton"></div>
              <div
                class="skeleton"
                :style="{ width: `${getCategorySkeletonWidth(n)}px`, height: '13px', borderRadius: '5px' }"
              ></div>
              <div class="skeleton" style="width: 22px; height: 18px; border-radius: 999px;"></div>
            </div>
          </template>

          <template v-else-if="homeData.categories?.length > 0">
            <router-link
              v-for="cat in homeData.categories"
              :key="cat.id"
              :to="`/feed?category=${cat.slug}`"
              class="cat-pill-tile"
            >
              <div class="cat-pill-icon" :style="{ background: `${cat.color}18`, color: cat.color }">
                <component :is="getIcon(cat.icon)" :size="15" />
              </div>
              <span class="cat-pill-name">{{ cat.name }}</span>
              <span class="cat-pill-count">{{ cat.contents_count || 0 }}</span>
            </router-link>
          </template>

          <div v-else class="categories-empty small muted">
            No categories available yet.
          </div>
        </div>

        <button
          v-if="!loading && canScrollCatRight"
          type="button"
          class="cat-scroll-btn"
          @click="scrollCategories(1)"
          aria-label="Scroll categories right"
        >
          <ChevronRight :size="16" />
        </button>
      </div>
    </div>

    <!-- Main Content split: Trending & Latest Feed (left) vs Learning (right) -->
    <div class="home-split-layout mt-6">
      <!-- Left Column: Feeds -->
      <div class="home-feed-col">
        <!-- Trending Section (Compact: max 3 items, user + title only) -->
        <div class="section-container">
          <div class="row-between mb-3">
            <div class="row" style="gap: 8px;">
              <Flame :size="20" class="text-orange" />
              <h2 class="card-title">Trending & Most Helpful</h2>
            </div>
            <router-link to="/feed?sort=trending" class="btn btn-ghost btn-sm">
              <span>Full Feed</span>
              <ChevronRight :size="16" />
            </router-link>
          </div>

          <div v-if="loading" class="compact-feed-list" aria-label="Loading trending content">
            <div v-for="n in 3" :key="`sk-trend-${n}`" class="card compact-feed-card compact-feed-skeleton">
              <div class="compact-feed-user">
                <div class="skeleton" style="width: 26px; height: 26px; border-radius: 50%; flex-shrink: 0;"></div>
                <div class="skeleton" style="width: 120px; height: 14px; border-radius: 5px;"></div>
              </div>
              <div class="skeleton" style="width: 82%; height: 18px; border-radius: 6px;"></div>
            </div>
          </div>

          <div v-else-if="homeData.trending?.length > 0" class="compact-feed-list">
            <router-link
              v-for="item in homeData.trending.slice(0, 3)"
              :key="item.id"
              :to="`/content/${item.id}`"
              class="card card-hover compact-feed-card"
            >
              <div class="compact-feed-user">
                <div class="avatar" style="width: 26px; height: 26px; font-size: 10px;">
                  <img v-if="item.author?.avatar_url" :src="item.author.avatar_url" :alt="item.author.name" />
                  <span v-else>{{ initials(item.author?.name) }}</span>
                </div>
                <span class="compact-feed-author truncate">{{ item.author?.name }}</span>
              </div>
              <h3 class="compact-feed-title clamp-2">{{ item.title }}</h3>
            </router-link>
          </div>

          <div v-else class="card card-pad empty">
            <div class="empty-icon"><BookOpen :size="28" /></div>
            <h3>No trending content yet</h3>
            <p class="small muted">Be the first to share an inspiring idea!</p>
          </div>
        </div>

        <!-- Recently Viewed History Section (Compact: user + title only, matching Trending) -->
        <div class="section-container mt-6">
          <div class="row-between mb-3">
            <div class="row" style="gap: 8px;">
              <History :size="20" class="text-primary" />
              <h2 class="card-title">Recently Viewed</h2>
            </div>
            <router-link to="/history" class="btn btn-ghost btn-sm">
              <span>View More</span>
              <ChevronRight :size="16" />
            </router-link>
          </div>

          <div v-if="loading" class="compact-feed-list" aria-label="Loading recently viewed content">
            <div v-for="n in 3" :key="`sk-history-${n}`" class="card compact-feed-card compact-feed-skeleton">
              <div class="compact-feed-user">
                <div class="skeleton" style="width: 26px; height: 26px; border-radius: 50%; flex-shrink: 0;"></div>
                <div class="skeleton" style="width: 112px; height: 14px; border-radius: 5px;"></div>
              </div>
              <div class="skeleton" style="width: 78%; height: 18px; border-radius: 6px;"></div>
            </div>
          </div>

          <div v-else-if="homeData.recently_viewed?.length > 0" class="compact-feed-list">
            <router-link
              v-for="item in homeData.recently_viewed.slice(0, 3)"
              :key="item.id"
              :to="`/content/${item.id}`"
              class="card card-hover compact-feed-card"
            >
              <div class="compact-feed-user">
                <div class="avatar" style="width: 26px; height: 26px; font-size: 10px;">
                  <img v-if="item.author?.avatar_url" :src="item.author.avatar_url" :alt="item.author.name" />
                  <span v-else>{{ initials(item.author?.name) }}</span>
                </div>
                <span class="compact-feed-author truncate">{{ item.author?.name }}</span>
              </div>
              <h3 class="compact-feed-title clamp-2">{{ item.title }}</h3>
            </router-link>
          </div>

          <div v-else class="card card-pad empty">
            <div class="empty-icon"><History :size="28" /></div>
            <h3>No reading history yet</h3>
            <p class="small muted">Contents you open will appear here for quick access.</p>
          </div>
        </div>
      </div>

      <!-- Right Column: Learning Micro-courses -->
      <div class="home-side-col">
        <!-- Learning Center Widget -->
        <div class="card card-pad courses-widget-card">
          <div class="row-between mb-3">
            <div class="row" style="gap: 8px;">
              <GraduationCap :size="18" class="text-primary" />
              <span class="card-title">Recommended Modules</span>
            </div>
            <router-link to="/learning" class="small bold text-primary">
              Open
            </router-link>
          </div>

          <div v-if="loading" class="course-list" aria-label="Loading recommended modules">
            <div v-for="n in 3" :key="`sk-course-${n}`" class="course-mini-card course-mini-skeleton">
              <div class="skeleton course-mini-badge-skeleton"></div>
              <div class="course-mini-info">
                <div class="skeleton" style="width: 88%; height: 16px; border-radius: 5px; margin-bottom: 6px;"></div>
                <div class="skeleton" style="width: 58%; height: 13px; border-radius: 4px;"></div>
              </div>
            </div>
          </div>

          <div v-else-if="homeData.courses?.length > 0" class="course-list">
            <router-link
              v-for="course in homeData.courses.slice(0, 3)"
              :key="course.id"
              :to="`/learning/${course.slug}`"
              class="course-mini-card"
            >
              <div class="course-mini-badge" :style="{ background: course.cover_color || '#1e8c45' }">
                <BookOpen :size="14" class="text-white" />
              </div>
              <div class="course-mini-info">
                <span class="course-mini-title clamp-2">{{ course.title }}</span>
                <div class="row small muted" style="gap: 6px;">
                  <span>{{ course.duration_minutes }} mins</span>
                  <span>•</span>
                  <span class="text-primary bold">+{{ course.points_reward }} Pts</span>
                </div>
              </div>
            </router-link>
          </div>

          <div v-else class="course-empty small muted">
            No recommended modules available yet.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import {
  Sparkles, Plus, Compass, BookOpen, Award, Users, TrendingUp,
  ChevronLeft, ChevronRight, Flame, History, Trophy, GraduationCap, Lightbulb,
  Rocket, FileText, MessagesSquare, Camera, Building, Leaf, Crown
} from 'lucide-vue-next'
import api from '@/api/client'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const loading = ref(true)
const catStripRef = ref(null)
const canScrollCatLeft = ref(false)
const canScrollCatRight = ref(false)
const homeData = ref({
  stats: {},
  my_rank: null,
  trending: [],
  latest: [],
  recently_viewed: [],
  top_weekly: [],
  categories: [],
  courses: [],
})

const iconMap = {
  Award, Lightbulb, BookOpen, Rocket, FileText, Trophy,
  MessagesSquare, Camera, Building, Leaf, Crown, Users,
}

const getIcon = (name) => {
  return iconMap[name] || BookOpen
}

const updateCatScrollState = () => {
  const el = catStripRef.value
  if (!el) {
    canScrollCatLeft.value = false
    canScrollCatRight.value = false
    return
  }
  canScrollCatLeft.value = el.scrollLeft > 4
  canScrollCatRight.value = el.scrollLeft + el.clientWidth < el.scrollWidth - 4
}

const categorySkeletonWidths = [78, 92, 86, 108, 96, 84, 102, 88]
const getCategorySkeletonWidth = (index) => {
  return categorySkeletonWidths[(index - 1) % categorySkeletonWidths.length]
}

const scrollCategories = (dir) => {
  const el = catStripRef.value
  if (!el) return
  el.scrollBy({ left: dir * 240, behavior: 'smooth' })
}

const fetchHome = async () => {
  loading.value = true
  try {
    const [res] = await Promise.all([
      api.get('/home'),
      authStore.fetchMe(),
    ])
    homeData.value = res.data
  } catch (err) {
    console.error('Failed to load home data', err)
  } finally {
    loading.value = false
    await nextTick()
    updateCatScrollState()
  }
}

onMounted(() => {
  fetchHome()
  window.addEventListener('resize', updateCatScrollState)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', updateCatScrollState)
})

const formatNumber = (num) => {
  if (!num) return '0'
  return new Intl.NumberFormat('en-US').format(num)
}

const initials = (name) => {
  if (!name) return 'GH'
  return name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()
}
</script>

<style scoped src="@/styles/features/home.css"></style>
