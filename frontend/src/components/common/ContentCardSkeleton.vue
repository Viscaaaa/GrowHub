<template>
  <div class="stack" aria-label="Loading content cards">
    <div v-for="n in count" :key="`content-sk-${n}`" class="card card-pad stack">
      <!-- Author & Badges Row -->
      <div class="row-between flex-wrap" style="gap: 12px;">
        <div class="row" style="gap: 12px;">
          <div class="skeleton sk-circle" style="width: 44px; height: 44px;"></div>
          <div class="stack" style="gap: 6px;">
            <div class="skeleton sk-line" style="width: 144px;"></div>
            <div class="skeleton sk-line-sm" style="width: 184px;"></div>
          </div>
        </div>
        <div class="row" style="gap: 8px;">
          <div class="skeleton sk-pill" style="width: 96px;"></div>
          <div class="skeleton sk-pill" style="width: 76px;"></div>
        </div>
      </div>

      <!-- Title & Body Excerpt -->
      <div class="stack" style="gap: 8px;">
        <div class="skeleton sk-title" style="width: 72%;"></div>
        <div class="skeleton sk-line" style="width: 100%;"></div>
        <div class="skeleton sk-line" style="width: 92%;"></div>
        <div class="skeleton sk-line" style="width: 60%;"></div>
      </div>

      <!-- Action Footer -->
      <div class="row-between pt-2" style="border-top: 1px solid var(--border);">
        <div class="row" style="gap: 14px;">
          <div class="skeleton sk-line" style="width: 52px;"></div>
          <div class="skeleton sk-line" style="width: 52px;"></div>
          <div class="skeleton sk-line" style="width: 52px;"></div>
        </div>
        <div class="skeleton sk-btn" style="width: 74px; height: 30px;"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  count: {
    type: Number,
    default: 3,
  },
})
</script>

