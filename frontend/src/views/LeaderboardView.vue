<template>
  <div class="page leaderboard-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Employee Leaderboard</h1>
        <p class="page-subtitle">
          Recognizing employees most active in sharing knowledge, ideas, and collaborative discussions.
        </p>
        <div v-if="loading" class="row mt-1 flex-wrap" style="gap: 8px;">
          <div class="skeleton sk-pill" style="width: 142px;"></div>
          <div class="skeleton sk-pill" style="width: 196px;"></div>
        </div>
        <div v-else class="row mt-1 flex-wrap" style="gap: 8px;">
          <span class="badge badge-primary small">Top {{ topLimit }} Leaderboard</span>
          <span class="badge small" :class="resetFrequency === 'never' ? 'badge-gray' : 'badge-purple'">
            {{ resetBadgeText }}
          </span>
        </div>
      </div>

      <!-- Department Filter Dropdown -->
      <div class="department-filter">
        <select v-model="selectedDept" @change="fetchLeaderboard" class="select">
          <option value="">All Departments</option>
          <option v-for="d in departments" :key="d" :value="d">{{ d }}</option>
        </select>
      </div>
    </div>

    <!-- Period Tabs -->
    <div class="tabs mb-4">
      <button
        class="tab"
        :class="{ active: period === 'week' }"
        @click="switchPeriod('week')"
      >
        <span>This Week</span>
      </button>

      <button
        class="tab"
        :class="{ active: period === 'month' }"
        @click="switchPeriod('month')"
      >
        <span>This Month</span>
      </button>

      <button
        class="tab"
        :class="{ active: period === 'all' }"
        @click="switchPeriod('all')"
      >
        <span>All-Time</span>
      </button>
    </div>

    <!-- Top 3 Podium Cards (Skeleton when loading) -->
    <div v-if="loading && showPodium" class="podium-grid mb-4" aria-label="Loading podium leaders">
      <div class="podium-card rank-2-card">
        <div class="skeleton sk-circle" style="width: 26px; height: 26px; margin-bottom: 8px;"></div>
        <div class="skeleton sk-circle podium-avatar"></div>
        <div class="skeleton sk-line" style="width: 72%; margin-bottom: 6px;"></div>
        <div class="skeleton sk-line-sm" style="width: 52%; margin-bottom: 10px;"></div>
        <div class="skeleton sk-line-lg" style="width: 68px;"></div>
      </div>

      <div class="podium-card rank-1-card">
        <div class="skeleton sk-circle" style="width: 26px; height: 26px; margin-bottom: 8px;"></div>
        <div class="skeleton sk-circle podium-avatar first-avatar" style="box-shadow: none;"></div>
        <div class="skeleton sk-line" style="width: 78%; margin-bottom: 6px;"></div>
        <div class="skeleton sk-line-sm" style="width: 56%; margin-bottom: 10px;"></div>
        <div class="skeleton sk-line-lg" style="width: 82px; height: 22px;"></div>
      </div>

      <div class="podium-card rank-3-card">
        <div class="skeleton sk-circle" style="width: 26px; height: 26px; margin-bottom: 8px;"></div>
        <div class="skeleton sk-circle podium-avatar"></div>
        <div class="skeleton sk-line" style="width: 72%; margin-bottom: 6px;"></div>
        <div class="skeleton sk-line-sm" style="width: 52%; margin-bottom: 10px;"></div>
        <div class="skeleton sk-line-lg" style="width: 68px;"></div>
      </div>
    </div>

    <div v-else-if="!loading && topThree.length > 0 && showPodium" class="podium-grid mb-4">
      <!-- 2nd Place (Silver) -->
      <div v-if="topThree[1]" class="podium-card rank-2-card">
        <div class="podium-medal silver">2</div>
        <router-link :to="`/profile/${topThree[1].id}`" class="avatar podium-avatar">
          <img v-if="topThree[1].avatar_url" :src="topThree[1].avatar_url" :alt="topThree[1].name" />
          <span v-else>{{ initials(topThree[1].name) }}</span>
        </router-link>
        <router-link :to="`/profile/${topThree[1].id}`" class="bold small text-dark truncate">
          {{ topThree[1].name }}
        </router-link>
        <span class="small muted truncate">{{ topThree[1].department }}</span>
        <div class="podium-score">
          <span class="bold text-primary">{{ formatNumber(topThree[1].score) }}</span>
          <span class="small muted"> Pts</span>
        </div>
      </div>

      <!-- 1st Place (Gold) -->
      <div v-if="topThree[0]" class="podium-card rank-1-card">
        <Crown :size="24" class="text-amber crown-icon" />
        <div class="podium-medal gold">1</div>
        <router-link :to="`/profile/${topThree[0].id}`" class="avatar podium-avatar first-avatar">
          <img v-if="topThree[0].avatar_url" :src="topThree[0].avatar_url" :alt="topThree[0].name" />
          <span v-else>{{ initials(topThree[0].name) }}</span>
        </router-link>
        <router-link :to="`/profile/${topThree[0].id}`" class="bold text-dark truncate">
          {{ topThree[0].name }}
        </router-link>
        <span class="small muted truncate">{{ topThree[0].department }}</span>
        <div class="podium-score">
          <span class="bold text-primary" style="font-size: 18px;">{{ formatNumber(topThree[0].score) }}</span>
          <span class="small muted"> Pts</span>
        </div>
      </div>

      <!-- 3rd Place (Bronze) -->
      <div v-if="topThree[2]" class="podium-card rank-3-card">
        <div class="podium-medal bronze">3</div>
        <router-link :to="`/profile/${topThree[2].id}`" class="avatar podium-avatar">
          <img v-if="topThree[2].avatar_url" :src="topThree[2].avatar_url" :alt="topThree[2].name" />
          <span v-else>{{ initials(topThree[2].name) }}</span>
        </router-link>
        <router-link :to="`/profile/${topThree[2].id}`" class="bold small text-dark truncate">
          {{ topThree[2].name }}
        </router-link>
        <span class="small muted truncate">{{ topThree[2].department }}</span>
        <div class="podium-score">
          <span class="bold text-primary">{{ formatNumber(topThree[2].score) }}</span>
          <span class="small muted"> Pts</span>
        </div>
      </div>
    </div>

    <!-- Leaderboard Table -->
    <div class="card overflow-hidden">
      <table class="table">
        <thead>
          <tr>
            <th style="width: 70px;">Rank</th>
            <th>Employee</th>
            <th>Department</th>
            <th>Streak</th>
            <th style="text-align: right;">Points Earned</th>
          </tr>
        </thead>
        <tbody v-if="loading" aria-label="Loading leaderboard rows">
          <tr v-for="n in 7" :key="`sk-lb-${n}`">
            <td><div class="skeleton sk-circle" style="width: 28px; height: 28px;"></div></td>
            <td>
              <div class="row" style="gap: 10px;">
                <div class="skeleton sk-circle" style="width: 36px; height: 36px;"></div>
                <div class="stack" style="gap: 5px;">
                  <div class="skeleton sk-line" style="width: 136px;"></div>
                  <div class="skeleton sk-line-sm" style="width: 96px;"></div>
                </div>
              </div>
            </td>
            <td><div class="skeleton sk-pill" style="width: 108px; height: 22px;"></div></td>
            <td><div class="skeleton sk-line" style="width: 72px;"></div></td>
            <td style="text-align: right;">
              <div class="skeleton sk-line" style="width: 68px; margin-left: auto;"></div>
            </td>
          </tr>
        </tbody>
        <tbody v-else-if="leaders.length > 0">
          <tr
            v-for="user in leaders"
            :key="user.id"
            :class="{ 'my-rank-row': user.id === authStore.user?.id }"
          >
            <td>
              <span class="rank-badge" :class="`rank-badge-${user.rank}`">
                {{ user.rank }}
              </span>
            </td>
            <td>
              <router-link :to="`/profile/${user.id}`" class="row" style="gap: 10px; text-decoration: none; color: inherit;">
                <div class="avatar" style="width: 36px; height: 36px; font-size: 13px;">
                  <img v-if="user.avatar_url" :src="user.avatar_url" :alt="user.name" />
                  <span v-else>{{ initials(user.name) }}</span>
                </div>
                <div>
                  <div class="bold text-dark hover-green">{{ user.name }}</div>
                  <div v-if="user.position" class="small muted">{{ user.position }}</div>
                </div>
              </router-link>
            </td>
            <td>
              <span class="badge badge-gray small">{{ user.department || 'Employee' }}</span>
            </td>
            <td>
              <span class="row small bold text-orange" style="gap: 4px;">
                <Flame :size="14" />
                <span>{{ user.current_streak }} Days</span>
              </span>
            </td>
            <td style="text-align: right;">
              <span class="bold text-primary" style="font-size: 15px;">
                {{ formatNumber(user.score) }}
              </span>
              <span class="small muted"> Pts</span>
            </td>
          </tr>
        </tbody>
        <tbody v-else>
          <tr>
            <td colspan="5" class="text-center muted small" style="padding: 36px 16px;">
              No leaderboard entries found for the selected filter.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- My Rank Sticky Footer -->
    <div v-if="loading" class="card card-pad card-dark my-rank-sticky mt-4" aria-label="Loading your rank">
      <div class="row" style="gap: 12px;">
        <div class="skeleton skeleton-dark sk-circle" style="width: 44px; height: 44px;"></div>
        <div class="stack" style="gap: 6px;">
          <div class="skeleton skeleton-dark sk-line" style="width: 96px;"></div>
          <div class="skeleton skeleton-dark sk-line-sm" style="width: 240px;"></div>
        </div>
      </div>

      <div class="stack" style="gap: 6px; align-items: flex-end;">
        <div class="skeleton skeleton-dark sk-line-sm" style="width: 112px;"></div>
        <div class="skeleton skeleton-dark sk-line-lg" style="width: 78px;"></div>
      </div>
    </div>

    <div v-else-if="myRankInfo" class="card card-pad card-dark my-rank-sticky mt-4">
      <div class="row" style="gap: 12px;">
        <div class="my-rank-circle">
          {{ displayRank }}
        </div>
        <div>
          <div class="bold">Your Rank</div>
          <div class="small opacity-80">
            <span v-if="myRankInfo.is_outside_limit && showMyRankOutside">
              Peringkat Anda di luar batas Top {{ topLimit }}. Tetap aktif untuk menembus Top {{ topLimit }}!
            </span>
            <span v-else-if="myRankInfo.is_outside_limit && !showMyRankOutside">
              Belum masuk batas Top {{ topLimit }}. Tingkatkan keaktifan Anda!
            </span>
            <span v-else>
              Selamat! Anda berada di dalam Top {{ topLimit }} karyawan terbaik.
            </span>
          </div>
        </div>
      </div>

      <div class="row" style="gap: 16px;">
        <div class="text-right">
          <span class="small opacity-80">Points ({{ periodTitle }}):</span>
          <div class="bold" style="font-size: 18px;">{{ formatNumber(myRankInfo.score || 0) }} Pts</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Crown, Flame } from 'lucide-vue-next'
import api from '@/api/client'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const loading = ref(true)
const period = ref('all')
const selectedDept = ref('')
const leaders = ref([])
const myRankInfo = ref(null)
const departments = ref([])
const topLimit = ref(50)
const showPodium = ref(true)
const showMyRankOutside = ref(true)
const resetFrequency = ref('never')
const resetFrequencyLabel = ref('')
const nextResetAt = ref(null)

const resetBadgeText = computed(() => {
  if (resetFrequency.value === 'weekly') return '🔄 Reset Mingguan (Tiap Senin)'
  if (resetFrequency.value === 'monthly') return '🔄 Reset Bulanan (Tiap Tanggal 1)'
  if (resetFrequency.value === 'quarterly') return '🔄 Reset Triwulan (3 Bulan Sekali)'
  if (resetFrequency.value === 'yearly') return '🔄 Reset Tahunan (Tiap 1 Januari)'
  return '♾️ Tanpa Reset (Sepanjang Waktu)'
})

const fetchLeaderboard = async () => {
  loading.value = true
  try {
    const res = await api.get('/leaderboard', {
      params: {
        period: period.value,
        department: selectedDept.value || undefined,
      },
    })
    leaders.value = res.data.leaders || []
    myRankInfo.value = res.data.me
    departments.value = res.data.departments || []
    topLimit.value = res.data.top_limit || (res.data.settings?.leaderboard_limit ?? 50)
    if (res.data.settings) {
      showPodium.value = res.data.settings.show_podium !== false
      showMyRankOutside.value = res.data.settings.show_my_rank_outside !== false
      resetFrequency.value = res.data.settings.reset_frequency || 'never'
      resetFrequencyLabel.value = res.data.settings.reset_frequency_label || ''
      nextResetAt.value = res.data.settings.next_reset_at || null
    }
  } catch (err) {
    console.error('Failed leaderboard', err)
  } finally {
    loading.value = false
  }
}

const switchPeriod = (p) => {
  period.value = p
  fetchLeaderboard()
}

const topThree = computed(() => {
  return leaders.value.slice(0, 3)
})

const displayRank = computed(() => {
  if (!myRankInfo.value) return '-'
  if (myRankInfo.value.is_outside_limit) {
    return showMyRankOutside.value && myRankInfo.value.rank ? `#${myRankInfo.value.rank}` : '-'
  }
  return myRankInfo.value.rank ? `#${myRankInfo.value.rank}` : '-'
})

const periodTitle = computed(() => {
  if (period.value === 'week') return 'This Week'
  if (period.value === 'month') return 'This Month'
  return 'All-Time'
})

onMounted(() => {
  fetchLeaderboard()
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

<style scoped src="@/styles/features/leaderboard.css"></style>
