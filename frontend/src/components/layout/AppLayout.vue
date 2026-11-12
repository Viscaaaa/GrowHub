<template>
  <div class="app-layout">
    <Navbar @toggle-sidebar="handleToggleSidebar" />

    <div class="app-main">
      <!-- Mobile backdrop -->
      <div
        v-if="sidebarOpen"
        class="sidebar-backdrop"
        @click="sidebarOpen = false"
      ></div>

      <Sidebar
        :is-open="sidebarOpen"
        :is-hidden="isSidebarHidden"
        @close="sidebarOpen = false"
        @hide="isSidebarHidden = true"
        @show="isSidebarHidden = false"
        @toggle="isSidebarHidden = !isSidebarHidden"
      />

      <main class="app-content">
        <router-view />
      </main>
    </div>

    <ToastContainer />

    <EthicsNoticeModal
      :is-open="authStore.isAuthenticated && authStore.showEthicsModal"
      @acknowledge="authStore.acknowledgeEthicsNotice()"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import Navbar from './Navbar.vue'
import Sidebar from './Sidebar.vue'
import ToastContainer from '@/components/common/ToastContainer.vue'
import EthicsNoticeModal from '@/components/common/EthicsNoticeModal.vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(() => {
  if (authStore.isAuthenticated) {
    authStore.fetchMe()
  }
})

const sidebarOpen = ref(false)
const isSidebarHidden = ref(false)

const handleToggleSidebar = () => {
  if (typeof window !== 'undefined' && window.innerWidth <= 992) {
    sidebarOpen.value = !sidebarOpen.value
  } else {
    isSidebarHidden.value = !isSidebarHidden.value
  }
}
</script>

<style scoped src="@/styles/components/app-layout.css"></style>
