<template>
  <div class="page dashboard-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">My Dashboard</h1>
        <p class="page-subtitle">Track your points progress, level achievements, daily streak, and gamification badges.</p>
      </div>

      <router-link to="/create" class="btn btn-primary">
        <Plus :size="18" />
        <span>Share Content (+5 Pts)</span>
      </router-link>
    </div>

    <div class="stack dashboard-stack">
      <!-- Top Gamification Showcase Cards -->
      <div class="grid grid-3 gamify-summary-grid">
        <!-- Level & Progression Card -->
        <div class="card card-pad card-dark level-card summary-card">
          <div class="row-between mb-2">
            <span class="badge badge-light-blur">Skill Level</span>
            <div v-if="loading" class="skeleton skeleton-dark" style="width: 96px; height: 18px; border-radius: 999px;"></div>
            <span v-else class="bold small">Rank #{{ data.rank || '-' }} Global</span>
          </div>

          <template v-if="loading">
            <div class="level-name-row my-2">
              <div class="skeleton skeleton-dark" style="width: 122px; height: 31px; border-radius: 8px;"></div>
              <div class="skeleton skeleton-dark mt-2" style="width: 148px; height: 21px; border-radius: 6px;"></div>
            </div>

            <div class="skeleton skeleton-dark mt-3" style="width: 100%; height: 8px; border-radius: 999px;"></div>

            <div class="row-between mt-2">
              <div class="skeleton skeleton-dark" style="width: 68px; height: 18px; border-radius: 6px;"></div>
              <div class="skeleton skeleton-dark" style="width: 112px; height: 18px; border-radius: 6px;"></div>
            </div>
          </template>

          <template v-else>
            <div class="level-name-row my-2">
              <h2 class="level-big-title">Level {{ authStore.userLevel.level }}</h2>
              <div class="level-subtitle">{{ authStore.userLevel.name }}</div>
            </div>

            <div class="progress mt-3">
              <span :style="{ width: `${authStore.userLevel.progress}%` }"></span>
            </div>

            <div class="row-between small opacity-90 mt-2">
              <span>{{ formatNumber(authStore.userPoints) }} Pts</span>
              <span v-if="authStore.userLevel.points_to_next > 0">
                {{ authStore.userLevel.points_to_next }} Pts to Lv.{{ authStore.userLevel.next_level }}
              </span>
              <span v-else>Maximum Level Reached! 🌟</span>
            </div>
          </template>
        </div>

        <!-- Daily Streak Card -->
        <div class="card card-pad streak-card summary-card">
          <div class="row-between mb-2">
            <span class="bold small text-2">Daily Consistency</span>
            <span class="badge badge-amber">+2 Pts / active day</span>
          </div>

          <template v-if="loading">
            <div class="streak-center">
              <div class="skeleton streak-circle-skeleton"></div>
              <div class="skeleton" style="width: 98px; height: 34px; border-radius: 8px; margin-bottom: 6px;"></div>
              <div class="skeleton" style="width: 148px; height: 17px; border-radius: 6px;"></div>
            </div>

            <div class="row-between small muted streak-footer">
              <span>Longest Streak:</span>
              <div class="skeleton" style="width: 68px; height: 17px; border-radius: 6px;"></div>
            </div>
          </template>

          <template v-else>
            <div class="streak-center">
              <div class="streak-flame-circle">
                <Flame :size="32" class="text-orange flicker" />
              </div>
              <div class="streak-value">{{ authStore.userStreak }} <span class="streak-unit">Days</span></div>
              <div class="streak-desc small muted">Consecutive Active Streak</div>
            </div>

            <div class="row-between small muted streak-footer">
              <span>Longest Streak:</span>
              <span class="bold text-dark">{{ data.user?.longest_streak || authStore.userStreak }} Days 🔥</span>
            </div>
          </template>
        </div>

        <!-- Point Stats Summary -->
        <div class="card card-pad points-breakdown-card summary-card">
          <span class="bold small text-2 mb-2">Points Earned</span>

          <template v-if="loading">
            <div class="point-stat-item">
              <span class="muted small">Today</span>
              <div class="skeleton" style="width: 64px; height: 18px; border-radius: 6px;"></div>
            </div>

            <div class="point-stat-item">
              <span class="muted small">This Week</span>
              <div class="skeleton" style="width: 64px; height: 18px; border-radius: 6px;"></div>
            </div>

            <div class="point-stat-item">
              <span class="muted small">This Month</span>
              <div class="skeleton" style="width: 64px; height: 18px; border-radius: 6px;"></div>
            </div>

            <div class="point-stat-item total-item">
              <span class="bold text-dark">Total Accumulated</span>
              <div class="skeleton" style="width: 92px; height: 24px; border-radius: 6px;"></div>
            </div>
          </template>

          <template v-else>
            <div class="point-stat-item">
              <span class="muted small">Today</span>
              <span class="bold" :class="(data.user?.points_today || 0) < 0 ? 'text-red' : 'text-primary'">
                {{ formatSignedPts(data.user?.points_today) }}
              </span>
            </div>

            <div class="point-stat-item">
              <span class="muted small">This Week</span>
              <span class="bold" :class="(data.points_this_week || 0) < 0 ? 'text-red' : 'text-dark'">
                {{ formatSignedPts(data.points_this_week) }}
              </span>
            </div>

            <div class="point-stat-item">
              <span class="muted small">This Month</span>
              <span class="bold" :class="(data.points_this_month || 0) < 0 ? 'text-red' : 'text-dark'">
                {{ formatSignedPts(data.points_this_month) }}
              </span>
            </div>

            <div class="point-stat-item total-item">
              <span class="bold text-dark">Total Accumulated</span>
              <span class="bold text-primary" style="font-size: 18px;">{{ formatNumber(authStore.userPoints) }} Pts</span>
            </div>
          </template>
        </div>
      </div>

      <!-- Point 30-Day Activity Trend Bar Chart -->
      <div class="card card-pad chart-card mt-4">
        <div class="row-between section-head-wrap mb-3">
          <div>
            <h2 class="card-title">Points Trend (Last 30 Days)</h2>
            <p class="small text-2">Your daily knowledge sharing activity and engagement</p>
          </div>
          <span class="badge badge-gray small">30 Days</span>
        </div>

        <div v-if="loading" class="chart-container" aria-label="Loading points chart">
          <div
            v-for="idx in 30"
            :key="`sk-bar-${idx}`"
            class="chart-bar-wrapper"
          >
            <div class="chart-bar-track">
              <div
                class="skeleton chart-bar-skeleton"
                :style="{ height: `${getSkeletonBarHeight(idx)}%` }"
              ></div>
            </div>
            <div class="chart-label-slot">
              <span v-if="(idx - 1) % 5 === 0" class="skeleton chart-label-skeleton"></span>
            </div>
          </div>
        </div>

        <div v-else class="chart-container">
          <div
            v-for="(day, idx) in chartDays"
            :key="day.date || idx"
            class="chart-bar-wrapper"
            :title="day.date ? `${day.date}: ${day.points} Pts` : `${day.points} Pts`"
          >
            <div class="chart-bar-track">
              <div
                class="chart-bar-fill"
                :style="{ height: `${Math.min(100, Math.max(8, (day.points / maxChartPoint) * 100))}%` }"
                :class="{ 'has-points': day.points > 0 }"
              ></div>
            </div>
            <div class="chart-label-slot">
              <span class="chart-label" v-if="idx % 5 === 0 && day.date">{{ formatDay(day.date) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Badges & Achievements Section -->
      <div class="card card-pad badges-section-card mt-4">
        <div class="row-between section-head-wrap mb-3">
          <div>
            <h2 class="card-title">Badges & Achievements</h2>
            <p class="small text-2">Unlock achievement badges by actively contributing to the community</p>
          </div>
          <div v-if="loading" class="skeleton" style="width: 96px; height: 24px; border-radius: 999px;"></div>
          <span v-else class="badge badge-primary">{{ unlockedBadgesCount }}/{{ data.badges?.length || 8 }} Unlocked</span>
        </div>

        <div v-if="loading" class="grid grid-4 badges-grid" aria-label="Loading badges">
          <div
            v-for="n in 8"
            :key="`sk-badge-${n}`"
            class="badge-card badge-card-skeleton"
          >
            <div class="skeleton badge-icon-skeleton"></div>
            <div class="skeleton" style="width: 72%; height: 17px; border-radius: 6px; margin-bottom: 6px;"></div>
            <div class="skeleton" style="width: 94%; height: 14px; border-radius: 5px; margin-bottom: 4px;"></div>
            <div class="skeleton" style="width: 60%; height: 14px; border-radius: 5px;"></div>

            <div class="badge-progress-wrap">
              <div class="skeleton" style="width: 100%; height: 5px; border-radius: 999px;"></div>
              <div class="row-between mt-1">
                <div class="skeleton" style="width: 28px; height: 12px; border-radius: 4px;"></div>
                <div class="skeleton" style="width: 58px; height: 12px; border-radius: 4px;"></div>
              </div>
            </div>
          </div>
        </div>

        <div v-else-if="data.badges?.length" class="grid grid-4 badges-grid">
          <div
            v-for="b in data.badges"
            :key="b.key"
            class="badge-card"
            :class="{ 'badge-unlocked': b.earned }"
          >
            <div class="badge-icon-box">
              <component :is="getIcon(b.icon)" :size="24" />
            </div>
            <div class="badge-title bold small">{{ b.name }}</div>
            <p class="badge-desc small muted">{{ b.desc }}</p>

            <div class="badge-progress-wrap">
              <div class="progress" style="height: 5px;">
                <span :style="{ width: `${(b.progress / b.target) * 100}%` }"></span>
              </div>
              <div class="row-between small muted mt-1" style="font-size: 11px;">
                <span>{{ b.progress }}/{{ b.target }}</span>
                <span>{{ b.earned ? 'Unlocked 🏆' : 'In Progress' }}</span>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="badges-empty small muted">
          No achievement badges available yet.
        </div>
      </div>

      <!-- Activity Heatmap & Recent Ledger Split -->
      <div class="dashboard-split-grid mt-4">
        <!-- Point Ledger (Recent Transactions) -->
        <div class="card card-pad split-card">
          <div class="row-between mb-3">
            <h2 class="card-title">Recent Points Ledger</h2>
            <span class="small muted">Last 12 Activities</span>
          </div>

          <div class="split-list-container">
            <div v-if="loading" class="ledger-list stack" aria-label="Loading recent points ledger">
              <div v-for="n in 6" :key="`sk-tx-${n}`" class="ledger-item">
                <div class="skeleton ledger-icon-skeleton"></div>
                <div class="ledger-info">
                  <div class="skeleton" style="width: 78%; height: 16px; border-radius: 5px; margin-bottom: 5px;"></div>
                  <div class="skeleton" style="width: 34%; height: 13px; border-radius: 4px;"></div>
                </div>
                <div class="skeleton" style="width: 56px; height: 18px; border-radius: 6px; flex-shrink: 0;"></div>
              </div>
            </div>

            <div v-else-if="data.recent_points?.length" class="ledger-list stack">
              <div
                v-for="tx in data.recent_points"
                :key="tx.id"
                class="ledger-item"
              >
                <div class="ledger-icon" :class="tx.points > 0 ? 'bg-green-soft' : tx.points < 0 ? 'bg-red-soft' : 'bg-gray'">
                  <Plus v-if="tx.points > 0" :size="16" class="text-primary" />
                  <Minus v-else-if="tx.points < 0" :size="16" class="text-red" />
                  <Sparkles v-else :size="16" />
                </div>
                <div class="ledger-info truncate">
                  <span class="bold small truncate text-dark">{{ tx.description }}</span>
                  <span class="small muted">{{ timeAgo(tx.created_at) }}</span>
                </div>
                <div class="ledger-pts bold" :class="tx.points < 0 ? 'text-red' : 'text-primary'">
                  {{ formatSignedPts(tx.points) }}
                </div>
              </div>
            </div>

            <div v-else class="split-empty small muted">
              No recent point transactions yet.
            </div>
          </div>
        </div>

        <!-- Breakdown by Action -->
        <div class="card card-pad split-card">
          <h2 class="card-title mb-3">Your Point Sources</h2>

          <div class="split-list-container">
            <div v-if="loading" class="breakdown-list stack" aria-label="Loading point sources">
              <div v-for="n in 7" :key="`sk-src-${n}`" class="breakdown-row">
                <div class="skeleton" style="width: 58%; height: 16px; border-radius: 5px;"></div>
                <div class="skeleton" style="width: 54px; height: 16px; border-radius: 5px;"></div>
              </div>
            </div>

            <div v-else-if="hasBreakdown" class="breakdown-list stack">
              <div
                v-for="(total, action) in data.breakdown"
                :key="action"
                class="breakdown-row"
              >
                <span class="bold small text-dark capitalize">{{ formatAction(action) }}</span>
                <div class="row" style="gap: 8px; flex-shrink: 0;">
                  <span class="small bold" :class="total < 0 ? 'text-red' : 'text-primary'">{{ formatSignedPts(total) }}</span>
                </div>
              </div>
            </div>

            <div v-else class="split-empty small muted">
              No point sources recorded yet.
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  Plus, Minus, Sparkles, Flame, Sprout, BookOpen, Heart,
  Zap, MessageCircle, GraduationCap, Crown
} from 'lucide-vue-next'
import api from '@/api/client'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const loading = ref(true)
const data = ref({})

const iconMap = {
  Sprout, BookOpen, Heart, Flame, Zap, MessageCircle, GraduationCap, Crown, Sparkles,
}
const getIcon = (name) => iconMap[name] || Sparkles

const fetchDashboard = async () => {
  loading.value = true
  try {
    const res = await api.get('/dashboard')
    data.value = res.data
    if (res.data?.user) {
      authStore.updateUser(res.data.user)
    }
  } catch (err) {
    console.error('Failed to load dashboard', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchDashboard()
})

const skeletonBarHeights = [28, 46, 34, 62, 78, 42, 24, 54, 68, 84, 38, 50, 72, 30, 58]
const getSkeletonBarHeight = (idx) => skeletonBarHeights[idx % skeletonBarHeights.length]

const chartDays = computed(() => {
  if (data.value.chart?.length) return data.value.chart
  return Array.from({ length: 30 }, () => ({ date: '', points: 0 }))
})

const hasBreakdown = computed(() => {
  return Boolean(data.value.breakdown && Object.keys(data.value.breakdown).length > 0)
})

const maxChartPoint = computed(() => {
  if (!data.value.chart?.length) return 20
  const max = Math.max(...data.value.chart.map((c) => c.points))
  return Math.max(max, 15)
})

const unlockedBadgesCount = computed(() => {
  return data.value.badges?.filter((b) => b.earned).length || 0
})

const formatNumber = (num) => {
  if (!num) return '0'
  return new Intl.NumberFormat('en-US').format(num)
}

const formatSignedPts = (val) => {
  const num = Number(val) || 0
  return num > 0 ? `+${num} Pts` : `${num} Pts`
}

const formatDay = (dateStr) => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleDateString('en-US', { day: 'numeric', month: 'short' })
}

const formatAction = (act) => {
  const map = {
    daily_login: 'Daily Activity (Streak)',
    content_submitted: 'Content Submitted',
    content_published: 'Content Published',
    like_received: 'Likes Received',
    comment_given: 'Comments Posted',
    comment_received: 'Comments Received',
    share_given: 'Content Shared',
    share_received: 'Content Shared by Peers',
    save_received: 'Content Bookmarked',
    course_completed: 'Learning Center Module',
    review_done: 'Reviewer Reward',
    policy_violation: 'Pelanggaran Etika Komunikasi',
  }
  return map[act] || act.replace(/_/g, ' ')
}

const timeAgo = (dateStr) => {
  if (!dateStr) return ''
  const diff = (Date.now() - new Date(dateStr).getTime()) / 1000
  if (diff < 60) return 'Just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
</script>

<style scoped src="@/styles/features/dashboard.css"></style>
