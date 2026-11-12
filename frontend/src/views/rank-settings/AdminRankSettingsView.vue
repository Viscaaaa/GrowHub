<template>
  <div class="page admin-rank-settings-page">
    <!-- Header with Breadcrumb Badge & Actions -->
    <div class="page-header">
      <div>
        <div class="header-badge mb-1">
          <ShieldCheck :size="14" />
          <span>Administration Console</span>
        </div>
        <h1 class="page-title">Leaderboard & Rank Settings</h1>
        <p class="page-subtitle">
          Atur batas kuota peringkat teratas (Top Ranks) dan tentukan jadwal siklus reset berkala atau tanpa reset pada Leaderboard GrowHub.
        </p>
      </div>

      <div class="header-actions">
        <button
          type="button"
          class="btn btn-outline"
          @click="isResetModalOpen = true"
          :disabled="loading || saving"
        >
          <RotateCcw :size="16" />
          <span>Reset Default</span>
        </button>

        <button
          type="button"
          class="btn btn-primary"
          @click="saveSettings"
          :disabled="loading || saving || !isModified"
        >
          <Check :size="16" />
          <span>{{ saving ? 'Menyimpan...' : (isModified ? 'Simpan Perubahan' : 'Tersimpan') }}</span>
        </button>
      </div>
    </div>

    <!-- Stats Overview Cards -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon-wrapper bg-green-soft">
          <Trophy :size="20" class="text-primary" />
        </div>
        <div class="stat-meta">
          <span class="stat-label">Batas Top Leaderboard</span>
          <span v-if="loading" class="skeleton sk-stat-val"></span>
          <span v-else class="stat-val text-primary">Top {{ form.leaderboard_limit }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon-wrapper bg-blue-soft">
          <LayoutDashboard :size="20" class="text-blue" />
        </div>
        <div class="stat-meta">
          <span class="stat-label">Batas Widget Beranda</span>
          <span v-if="loading" class="skeleton sk-stat-val"></span>
          <span v-else class="stat-val">Top {{ form.home_widget_limit }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon-wrapper bg-purple-soft">
          <CalendarSync :size="20" class="text-purple" />
        </div>
        <div class="stat-meta">
          <span class="stat-label">Siklus Reset Leaderboard</span>
          <span v-if="loading" class="skeleton sk-stat-val"></span>
          <span v-else class="stat-val text-purple" style="font-size: 15px;">{{ getFrequencyShortLabel(form.reset_frequency) }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon-wrapper bg-amber-soft">
          <Crown :size="20" class="text-amber" />
        </div>
        <div class="stat-meta">
          <span class="stat-label">Podium Visual Top 3</span>
          <span v-if="loading" class="skeleton sk-stat-val"></span>
          <span v-else class="stat-val" :class="form.show_podium ? 'text-primary' : 'text-muted'">
            {{ form.show_podium ? 'Aktif' : 'Non-aktif' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Loading Skeleton -->
    <div v-if="loading" class="rank-settings-grid" aria-label="Loading rank settings">
      <div class="settings-col">
        <div v-for="n in 3" :key="`sk-rset-${n}`" class="settings-box stack" style="gap: 14px;">
          <div class="row" style="gap: 12px;">
            <div class="skeleton sk-box" style="width: 36px; height: 36px; border-radius: 8px;"></div>
            <div class="stack flex-1" style="gap: 6px;">
              <div class="skeleton sk-line-lg" style="width: 58%;"></div>
              <div class="skeleton sk-line-sm" style="width: 86%;"></div>
            </div>
          </div>
          <div class="skeleton" style="height: 54px; border-radius: 10px;"></div>
          <div class="skeleton" style="height: 54px; border-radius: 10px;"></div>
        </div>
      </div>
      <div class="settings-col">
        <div class="settings-box stack" style="gap: 14px;">
          <div class="skeleton sk-line-lg" style="width: 52%;"></div>
          <div class="skeleton" style="height: 150px; border-radius: 12px;"></div>
          <div v-for="n in 4" :key="`sk-rprev-${n}`" class="skeleton" style="height: 44px; border-radius: 10px;"></div>
        </div>
      </div>
    </div>

    <!-- Main Content: Two Columns (Form Settings & Live Preview) -->
    <div v-else class="rank-settings-grid">
      <!-- Left Column: Form Settings -->
      <div class="settings-col">
        <!-- 1. Reset Schedule Settings Box (FITUR BARU) -->
        <div class="settings-box">
          <div class="settings-box-header">
            <div class="settings-box-icon bg-purple-soft text-purple">
              <CalendarSync :size="20" />
            </div>
            <div>
              <h3 class="settings-box-title">Jadwal & Siklus Reset Leaderboard</h3>
              <p class="settings-box-desc">
                Tentukan kapan perolehan skor pada Leaderboard akan direset otomatis, atau pilih <strong>Tidak Pernah Reset</strong> agar poin terhitung sepanjang masa.
              </p>
            </div>
          </div>

          <div class="setting-item">
            <div class="setting-item-top">
              <div>
                <span class="setting-title">Pilih Kebijakan Siklus Reset:</span>
                <p class="setting-help">Pilih salah satu jadwal reset otomatis di bawah ini:</p>
              </div>
            </div>

            <!-- Radio Options Cards -->
            <div class="cycle-options-grid">
              <!-- Option: Never -->
              <label
                class="cycle-card"
                :class="{ selected: form.reset_frequency === 'never' }"
                @click="form.reset_frequency = 'never'"
              >
                <input
                  type="radio"
                  name="reset_frequency"
                  value="never"
                  v-model="form.reset_frequency"
                  class="cycle-radio"
                />
                <span class="cycle-icon">♾️</span>
                <div class="cycle-meta">
                  <div class="cycle-title-row">
                    <span class="cycle-title">Tidak Pernah Reset (Sepanjang Waktu)</span>
                    <span v-if="form.reset_frequency === 'never'" class="badge badge-primary small">Aktif</span>
                  </div>
                  <p class="cycle-desc">
                    Skor peringkat dihitung dari akumulasi seluruh poin yang diperoleh karyawan tanpa batas waktu kadaluarsa.
                  </p>
                </div>
              </label>

              <!-- Option: Weekly -->
              <label
                class="cycle-card"
                :class="{ selected: form.reset_frequency === 'weekly' }"
                @click="form.reset_frequency = 'weekly'"
              >
                <input
                  type="radio"
                  name="reset_frequency"
                  value="weekly"
                  v-model="form.reset_frequency"
                  class="cycle-radio"
                />
                <span class="cycle-icon">📅</span>
                <div class="cycle-meta">
                  <div class="cycle-title-row">
                    <span class="cycle-title">Reset Mingguan (Setiap Hari Senin)</span>
                    <span v-if="form.reset_frequency === 'weekly'" class="badge badge-primary small">Aktif</span>
                  </div>
                  <p class="cycle-desc">
                    Peringkat direset otomatis setiap awal minggu (Senin pukul 00:00). Cocok untuk program sprint kompetisi mingguan.
                  </p>
                </div>
              </label>

              <!-- Option: Monthly -->
              <label
                class="cycle-card"
                :class="{ selected: form.reset_frequency === 'monthly' }"
                @click="form.reset_frequency = 'monthly'"
              >
                <input
                  type="radio"
                  name="reset_frequency"
                  value="monthly"
                  v-model="form.reset_frequency"
                  class="cycle-radio"
                />
                <span class="cycle-icon">🗓️</span>
                <div class="cycle-meta">
                  <div class="cycle-title-row">
                    <span class="cycle-title">Reset Bulanan (Setiap Tanggal 1)</span>
                    <span v-if="form.reset_frequency === 'monthly'" class="badge badge-primary small">Aktif</span>
                  </div>
                  <p class="cycle-desc">
                    Peringkat direset otomatis setiap awal bulan (Tanggal 1 pukul 00:00). Sangat ideal untuk target bulanan.
                  </p>
                </div>
              </label>

              <!-- Option: Quarterly -->
              <label
                class="cycle-card"
                :class="{ selected: form.reset_frequency === 'quarterly' }"
                @click="form.reset_frequency = 'quarterly'"
              >
                <input
                  type="radio"
                  name="reset_frequency"
                  value="quarterly"
                  v-model="form.reset_frequency"
                  class="cycle-radio"
                />
                <span class="cycle-icon">🏢</span>
                <div class="cycle-meta">
                  <div class="cycle-title-row">
                    <span class="cycle-title">Reset Triwulan (Setiap 3 Bulan)</span>
                    <span v-if="form.reset_frequency === 'quarterly'" class="badge badge-primary small">Aktif</span>
                  </div>
                  <p class="cycle-desc">
                    Peringkat direset per kuartal (Januari, April, Juli, Oktober) untuk evaluasi kinerja per musim.
                  </p>
                </div>
              </label>

              <!-- Option: Yearly -->
              <label
                class="cycle-card"
                :class="{ selected: form.reset_frequency === 'yearly' }"
                @click="form.reset_frequency = 'yearly'"
              >
                <input
                  type="radio"
                  name="reset_frequency"
                  value="yearly"
                  v-model="form.reset_frequency"
                  class="cycle-radio"
                />
                <span class="cycle-icon">🎆</span>
                <div class="cycle-meta">
                  <div class="cycle-title-row">
                    <span class="cycle-title">Reset Tahunan (Setiap 1 Januari)</span>
                    <span v-if="form.reset_frequency === 'yearly'" class="badge badge-primary small">Aktif</span>
                  </div>
                  <p class="cycle-desc">
                    Peringkat direset setiap tahun baru (1 Januari pukul 00:00) untuk penghargaan tahunan karyawan terbaik (*Employee of the Year*).
                  </p>
                </div>
              </label>
            </div>

            <!-- Reset Status & Manual Action Box -->
            <div class="reset-status-box">
              <div class="reset-status-grid">
                <div class="reset-status-item">
                  <span class="reset-status-label">Siklus Aktif:</span>
                  <span class="reset-status-val">{{ getFrequencyLabel(form.reset_frequency) }}</span>
                </div>

                <div class="reset-status-item">
                  <span class="reset-status-label">Reset Otomatis Berikutnya:</span>
                  <span class="reset-status-val">
                    {{ form.reset_frequency === 'never' ? 'Tidak ada (Sepanjang Waktu)' : formatDate(stats.next_reset_at) }}
                  </span>
                </div>

                <div class="reset-status-item">
                  <span class="reset-status-label">Reset Terakhir Dilakukan:</span>
                  <span class="reset-status-val">
                    {{ stats.last_reset_at ? formatDate(stats.last_reset_at) : 'Belum pernah direset' }}
                  </span>
                </div>

                <div class="reset-status-item">
                  <span class="reset-status-label">Perhitungan Skor Dimulai Sejak:</span>
                  <span class="reset-status-val text-primary">
                    {{ stats.leaderboard_start_date ? formatDate(stats.leaderboard_start_date) : 'Awal Bergabung (Sepanjang Masa)' }}
                  </span>
                </div>
              </div>

              <!-- Manual Reset Action Bar -->
              <div class="reset-action-row">
                <div>
                  <span v-if="stats.last_reset_at" class="badge badge-amber small">
                    ⚠️ Reset manual sedang aktif sejak {{ formatDate(stats.last_reset_at) }}
                  </span>
                  <span v-else class="small muted">
                    Ingin memulai musim kompetisi baru sekarang di luar jadwal?
                  </span>
                </div>

                <div class="row" style="gap: 8px;">
                  <button
                    v-if="stats.last_reset_at"
                    type="button"
                    class="btn btn-ghost btn-sm text-muted"
                    @click="isClearManualResetModalOpen = true"
                    :disabled="saving"
                  >
                    Batalkan Reset Manual
                  </button>

                  <button
                    type="button"
                    class="btn btn-outline btn-sm text-amber"
                    @click="isManualResetModalOpen = true"
                    :disabled="saving"
                  >
                    <RotateCcw :size="15" />
                    <span>Reset Leaderboard Sekarang</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. Leaderboard Limit Settings Box -->
        <div class="settings-box">
          <div class="settings-box-header">
            <div class="settings-box-icon bg-green-soft text-primary">
              <Trophy :size="20" />
            </div>
            <div>
              <h3 class="settings-box-title">Batas Jumlah Peringkat Leaderboard</h3>
              <p class="settings-box-desc">Tentukan berapa banyak karyawan teratas yang diambil dan tampil pada halaman Leaderboard utama.</p>
            </div>
          </div>

          <div class="setting-item">
            <div class="setting-item-top">
              <div>
                <span class="setting-title">Pilih Preset Cepat Kuota:</span>
                <p class="setting-help">Klik salah satu kuota bawaan atau sesuaikan nilainya secara manual di bawah.</p>
              </div>
            </div>

            <div class="preset-chips">
              <button
                v-for="p in [10, 20, 25, 50, 100]"
                :key="p"
                type="button"
                class="preset-chip-btn"
                :class="{ active: form.leaderboard_limit === p }"
                @click="form.leaderboard_limit = p"
              >
                Top {{ p }}
              </button>
            </div>

            <!-- Stepper & Range Slider -->
            <div class="stepper-range-wrap">
              <div class="range-slider-wrap">
                <input
                  type="range"
                  min="3"
                  max="100"
                  step="1"
                  v-model.number="form.leaderboard_limit"
                  class="range-slider"
                />
                <div class="range-meta">
                  <span>Min: 3 Karyawan</span>
                  <span>Max: 100+ Karyawan</span>
                </div>
              </div>

              <div class="stepper-control">
                <button
                  type="button"
                  class="stepper-btn"
                  @click="adjustLeaderboardLimit(-1)"
                  :disabled="form.leaderboard_limit <= 3"
                >
                  -
                </button>
                <input
                  type="number"
                  min="3"
                  max="500"
                  v-model.number="form.leaderboard_limit"
                  class="stepper-input"
                />
                <button
                  type="button"
                  class="stepper-btn"
                  @click="adjustLeaderboardLimit(1)"
                  :disabled="form.leaderboard_limit >= 500"
                >
                  +
                </button>
              </div>
            </div>

            <p class="small muted mt-2">
              💡 <em>Contoh: Jika disetel ke <strong>Top {{ form.leaderboard_limit }}</strong>, maka sistem hanya memuat <strong>{{ form.leaderboard_limit }} besar karyawan</strong> teraktif pada tabel peringkat.</em>
            </p>
          </div>
        </div>

        <!-- 3. Home Widget Limit Settings Box -->
        <div class="settings-box">
          <div class="settings-box-header">
            <div class="settings-box-icon bg-blue-soft text-blue">
              <LayoutDashboard :size="20" />
            </div>
            <div>
              <h3 class="settings-box-title">Batas Widget Peringkat di Beranda (Home)</h3>
              <p class="settings-box-desc">Atur jumlah karyawan terbaik mingguan yang tampil pada kartu ringkasan halaman Beranda.</p>
            </div>
          </div>

          <div class="setting-item">
            <div class="preset-chips">
              <button
                v-for="h in [3, 5, 10]"
                :key="h"
                type="button"
                class="preset-chip-btn"
                :class="{ active: form.home_widget_limit === h }"
                @click="form.home_widget_limit = h"
              >
                Top {{ h }} Mingguan
              </button>
            </div>

            <div class="stepper-range-wrap">
              <div class="range-slider-wrap">
                <input
                  type="range"
                  min="1"
                  max="15"
                  step="1"
                  v-model.number="form.home_widget_limit"
                  class="range-slider"
                />
                <div class="range-meta">
                  <span>Min: 1 Karyawan</span>
                  <span>Max: 15 Karyawan</span>
                </div>
              </div>

              <div class="stepper-control">
                <button
                  type="button"
                  class="stepper-btn"
                  @click="adjustHomeLimit(-1)"
                  :disabled="form.home_widget_limit <= 1"
                >
                  -
                </button>
                <input
                  type="number"
                  min="1"
                  max="20"
                  v-model.number="form.home_widget_limit"
                  class="stepper-input"
                />
                <button
                  type="button"
                  class="stepper-btn"
                  @click="adjustHomeLimit(1)"
                  :disabled="form.home_widget_limit >= 20"
                >
                  +
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 4. Visual & Behavior Settings Box -->
        <div class="settings-box">
          <div class="settings-box-header">
            <div class="settings-box-icon bg-amber-soft text-amber">
              <Sliders :size="20" />
            </div>
            <div>
              <h3 class="settings-box-title">Preferensi Tampilan & Perilaku Ranking</h3>
              <p class="settings-box-desc">Konfigurasi visual elemen podium dan transparansi posisi ranking pribadi karyawan.</p>
            </div>
          </div>

          <!-- Switch 1: Podium Top 3 -->
          <div class="setting-item">
            <div class="switch-item">
              <div class="switch-label-col">
                <div class="switch-title">Tampilkan Panggung Podium Top 3 (Emas, Perak, Perunggu)</div>
                <div class="switch-desc">
                  Menampilkan kartu panggung visual untuk 3 besar karyawan di atas tabel leaderboard. Jika dinonaktifkan, peringkat langsung dimulai dari tabel baris ke-1.
                </div>
              </div>

              <label class="switch-toggle">
                <input type="checkbox" v-model="form.show_podium" />
                <span class="switch-slider"></span>
              </label>
            </div>
          </div>

          <!-- Switch 2: Show Actual Rank if Outside Top Limit -->
          <div class="setting-item">
            <div class="switch-item">
              <div class="switch-label-col">
                <div class="switch-title">Tampilkan Posisi Nyata jika di Luar Batas Top</div>
                <div class="switch-desc">
                  Jika peringkat karyawan berada di bawah batas Top {{ form.leaderboard_limit }} (misal rank #{{ form.leaderboard_limit + 14 }}), kartu sticky "Your Rank" tetap menunjukkan nomor posisi aslinya agar karyawan termotivasi mengejar kuota Top X.
                </div>
              </div>

              <label class="switch-toggle">
                <input type="checkbox" v-model="form.show_my_rank_outside" />
                <span class="switch-slider"></span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Live Interactive Simulation Preview -->
      <div class="preview-col">
        <div class="preview-card">
          <div class="preview-header">
            <div class="preview-title-row">
              <Sparkles :size="18" class="text-amber" />
              <h4 class="preview-title">Live Preview Leaderboard</h4>
            </div>
            <span class="preview-badge">Top {{ form.leaderboard_limit }}</span>
          </div>

          <!-- Simulated Reset Policy Indicator -->
          <div class="row items-center mb-3" style="gap: 6px;">
            <span class="badge badge-purple small">
              {{ getFrequencyShortLabel(form.reset_frequency) }}
            </span>
            <span class="small muted" style="font-size: 11.5px;">
              {{ form.reset_frequency === 'never' ? 'Tanpa Reset' : 'Reset Otomatis Aktif' }}
            </span>
          </div>

          <p class="small muted mb-3">
            Berikut simulasi bagaimana halaman Leaderboard akan tampil di layar karyawan dengan kombinasi kuota dan jadwal reset saat ini:
          </p>

          <!-- Simulated Podium (if show_podium is true) -->
          <div v-if="form.show_podium" class="mini-podium">
            <!-- Rank 2 -->
            <div class="mini-podium-card mini-podium-rank-2">
              <div class="mini-podium-medal medal-silver">2</div>
              <span class="mini-podium-name">{{ previewSample[1]?.name || 'Siti Aminah' }}</span>
              <span class="mini-podium-score">{{ previewSample[1]?.score || 450 }} Pts</span>
            </div>

            <!-- Rank 1 -->
            <div class="mini-podium-card mini-podium-rank-1">
              <div class="mini-podium-medal medal-gold">1</div>
              <span class="mini-podium-name">{{ previewSample[0]?.name || 'Budi Santoso' }}</span>
              <span class="mini-podium-score">{{ previewSample[0]?.score || 620 }} Pts</span>
            </div>

            <!-- Rank 3 -->
            <div class="mini-podium-card mini-podium-rank-3">
              <div class="mini-podium-medal medal-bronze">3</div>
              <span class="mini-podium-name">{{ previewSample[2]?.name || 'Rian Hidayat' }}</span>
              <span class="mini-podium-score">{{ previewSample[2]?.score || 380 }} Pts</span>
            </div>
          </div>

          <div v-else class="card card-pad bg-subtle text-center py-2 mb-3">
            <span class="small muted"><em>Panggung podium Top 3 dinonaktifkan (tabel langsung mulai dari Rank #1).</em></span>
          </div>

          <!-- Simulated Table Sample -->
          <table class="mini-table">
            <thead>
              <tr>
                <th style="width: 40px;">Rank</th>
                <th>Karyawan</th>
                <th style="text-align: right;">Poin</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(u, idx) in previewSample.slice(0, Math.min(form.leaderboard_limit, 4))" :key="idx">
                <td>
                  <span class="rank-indicator" :class="`rank-indicator-${idx + 1}`">{{ idx + 1 }}</span>
                </td>
                <td>
                  <div class="bold truncate" style="max-width: 130px;">{{ u.name }}</div>
                  <div class="small muted truncate">{{ u.department || 'Employee' }}</div>
                </td>
                <td style="text-align: right;">
                  <span class="bold text-primary">{{ u.score || (500 - idx * 60) }}</span>
                  <span class="small muted"> Pts</span>
                </td>
              </tr>
              <tr v-if="form.leaderboard_limit > 4">
                <td colspan="3" class="text-center py-2 muted small" style="background: #fafbfa;">
                  ... dan {{ form.leaderboard_limit - 4 }} karyawan lainnya hingga batas <strong>Top {{ form.leaderboard_limit }}</strong> ...
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Simulated Sticky User Rank Footer -->
          <div class="mini-sticky-rank">
            <div class="mini-sticky-left">
              <div class="mini-rank-pill">
                {{ form.show_my_rank_outside ? `#${form.leaderboard_limit + 12}` : '-' }}
              </div>
              <div>
                <div class="mini-sticky-text">Posisi Anda (Simulasi)</div>
                <div class="mini-sticky-sub">
                  <span v-if="form.show_my_rank_outside">
                    Peringkat #{{ form.leaderboard_limit + 12 }} (Di luar batas Top {{ form.leaderboard_limit }})
                  </span>
                  <span v-else>
                    Belum masuk batas Top {{ form.leaderboard_limit }}
                  </span>
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="bold text-green-light">120 Pts</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Confirmation Modal Reset Default -->
    <div v-if="isResetModalOpen" class="modal-overlay" @click.self="isResetModalOpen = false">
      <div class="modal-card">
        <div class="modal-header">
          <RotateCcw :size="20" class="text-amber" />
          <h3 class="modal-title">Konfirmasi Reset Default</h3>
        </div>
        <p class="modal-body">
          Apakah Anda yakin ingin mengembalikan pengaturan batas ranking ke konfigurasi default sistem?
          <br /><br />
          • Siklus Reset: <strong>Tidak Pernah Reset (Sepanjang Waktu)</strong><br />
          • Batas Leaderboard: <strong>Top 50</strong><br />
          • Batas Widget Beranda: <strong>Top 5</strong><br />
          • Tampilkan Podium: <strong>Aktif</strong><br />
          • Posisi di Luar Batas: <strong>Aktif</strong>
        </p>
        <div class="modal-actions">
          <button type="button" class="btn btn-outline" @click="isResetModalOpen = false">
            Batal
          </button>
          <button type="button" class="btn btn-primary" @click="confirmReset" :disabled="saving">
            {{ saving ? 'Mereset...' : 'Ya, Reset ke Default' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Confirmation Modal Manual Reset Now -->
    <div v-if="isManualResetModalOpen" class="modal-overlay" @click.self="isManualResetModalOpen = false">
      <div class="modal-card">
        <div class="modal-header">
          <RotateCcw :size="20" class="text-amber" />
          <h3 class="modal-title">Reset Leaderboard Sekarang?</h3>
        </div>
        <p class="modal-body">
          Tindakan ini akan <strong>mereset seluruh skor perolehan pada papan peringkat Leaderboard</strong> sekarang juga.
          <br /><br />
          🏆 Perhitungan poin leaderboard musim baru akan dimulai dari 0 sejak saat ini.<br />
          🌱 <em>Catatan: Level akumulasi karyawan (Seedling–Evergreen) tidak terpengaruh dan tetap aman.</em>
        </p>
        <div class="modal-actions">
          <button type="button" class="btn btn-outline" @click="isManualResetModalOpen = false">
            Batal
          </button>
          <button type="button" class="btn btn-primary bg-amber text-dark" @click="confirmManualReset" :disabled="saving">
            {{ saving ? 'Mereset...' : 'Ya, Reset Leaderboard Sekarang' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Confirmation Modal Clear Manual Reset -->
    <div v-if="isClearManualResetModalOpen" class="modal-overlay" @click.self="isClearManualResetModalOpen = false">
      <div class="modal-card">
        <div class="modal-header">
          <RotateCcw :size="20" class="text-primary" />
          <h3 class="modal-title">Batalkan Reset Manual?</h3>
        </div>
        <p class="modal-body">
          Apakah Anda ingin membatalkan status reset manual? Leaderboard akan kembali menghitung perolehan skor mengikuti jadwal siklus otomatis normal Anda.
        </p>
        <div class="modal-actions">
          <button type="button" class="btn btn-outline" @click="isClearManualResetModalOpen = false">
            Tutup
          </button>
          <button type="button" class="btn btn-primary" @click="confirmClearManualReset" :disabled="saving">
            {{ saving ? 'Memproses...' : 'Ya, Batalkan Reset Manual' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import {
  ShieldCheck, Trophy, LayoutDashboard, Crown, Users,
  RotateCcw, Check, Sliders, Sparkles, CalendarSync
} from 'lucide-vue-next'
import api from '@/api/client'
import { useToastStore } from '@/stores/toast'

const toastStore = useToastStore()

const loading = ref(true)
const saving = ref(false)
const isResetModalOpen = ref(false)
const isManualResetModalOpen = ref(false)
const isClearManualResetModalOpen = ref(false)

const stats = reactive({
  current_leaderboard_limit: 50,
  current_home_limit: 5,
  show_podium: true,
  show_my_rank_outside: true,
  reset_frequency: 'never',
  reset_frequency_label: 'Tidak Pernah Reset (Sepanjang Waktu)',
  last_reset_at: null,
  next_reset_at: null,
  leaderboard_start_date: null,
  total_active_employees: 0,
  total_employees_with_points: 0,
})

const form = reactive({
  leaderboard_limit: 50,
  home_widget_limit: 5,
  show_podium: true,
  show_my_rank_outside: true,
  reset_frequency: 'never',
})

const initialForm = reactive({
  leaderboard_limit: 50,
  home_widget_limit: 5,
  show_podium: true,
  show_my_rank_outside: true,
  reset_frequency: 'never',
})

const previewLeaders = ref([])

const previewSample = computed(() => {
  if (previewLeaders.value && previewLeaders.value.length >= 3) {
    return previewLeaders.value
  }
  // Fallback dummy for mockup
  return [
    { id: 1, name: 'Budi Santoso', department: 'Store Operations', score: 620 },
    { id: 2, name: 'Siti Aminah', department: 'Cashier & Customer Care', score: 450 },
    { id: 3, name: 'Rian Hidayat', department: 'Visual Merchandising', score: 380 },
    { id: 4, name: 'Dewi Lestari', department: 'Inventory & Stock', score: 290 },
    { id: 5, name: 'Agus Wijaya', department: 'Store Operations', score: 210 },
  ]
})

const isModified = computed(() => {
  return (
    form.leaderboard_limit !== initialForm.leaderboard_limit ||
    form.home_widget_limit !== initialForm.home_widget_limit ||
    form.show_podium !== initialForm.show_podium ||
    form.show_my_rank_outside !== initialForm.show_my_rank_outside ||
    form.reset_frequency !== initialForm.reset_frequency
  )
})

const adjustLeaderboardLimit = (delta) => {
  const newVal = form.leaderboard_limit + delta
  if (newVal >= 3 && newVal <= 500) {
    form.leaderboard_limit = newVal
  }
}

const adjustHomeLimit = (delta) => {
  const newVal = form.home_widget_limit + delta
  if (newVal >= 1 && newVal <= 20) {
    form.home_widget_limit = newVal
  }
}

const getFrequencyLabel = (freq) => {
  switch (freq) {
    case 'weekly': return 'Mingguan (Setiap Hari Senin)'
    case 'monthly': return 'Bulanan (Setiap Tanggal 1)'
    case 'quarterly': return 'Triwulan / Kuartal (3 Bulan Sekali)'
    case 'yearly': return 'Tahunan (Setiap 1 Januari)'
    default: return 'Tidak Pernah Reset (Sepanjang Waktu)'
  }
}

const getFrequencyShortLabel = (freq) => {
  switch (freq) {
    case 'weekly': return 'Reset Mingguan'
    case 'monthly': return 'Reset Bulanan'
    case 'quarterly': return 'Reset Triwulan'
    case 'yearly': return 'Reset Tahunan'
    default: return 'Tidak Pernah Reset'
  }
}

const formatDate = (isoStr) => {
  if (!isoStr) return '-'
  try {
    const d = new Date(isoStr)
    return new Intl.DateTimeFormat('id-ID', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(d)
  } catch (e) {
    return isoStr
  }
}

const fetchSettings = async () => {
  loading.value = true
  try {
    const res = await api.get('/admin/rank-settings')
    if (res.data) {
      const s = res.data.settings || {}
      if (s.leaderboard_limit) form.leaderboard_limit = Number(s.leaderboard_limit.value)
      if (s.home_widget_limit) form.home_widget_limit = Number(s.home_widget_limit.value)
      if (s.show_podium !== undefined) form.show_podium = Boolean(s.show_podium.value)
      if (s.show_my_rank_outside !== undefined) form.show_my_rank_outside = Boolean(s.show_my_rank_outside.value)
      if (s.reset_frequency) form.reset_frequency = String(s.reset_frequency.value)

      // Copy to initialForm for dirty tracking
      Object.assign(initialForm, form)

      if (res.data.stats) {
        Object.assign(stats, res.data.stats)
      }

      if (res.data.preview_leaders && res.data.preview_leaders.length > 0) {
        previewLeaders.value = res.data.preview_leaders
      }
    }
  } catch (err) {
    console.error('Failed to fetch rank settings', err)
    toastStore.error('Gagal memuat pengaturan batas peringkat.')
  } finally {
    loading.value = false
  }
}

const saveSettings = async () => {
  if (saving.value) return
  saving.value = true

  try {
    const payload = {
      leaderboard_limit: form.leaderboard_limit,
      home_widget_limit: form.home_widget_limit,
      show_podium: form.show_podium,
      show_my_rank_outside: form.show_my_rank_outside,
      reset_frequency: form.reset_frequency,
    }

    const res = await api.put('/admin/rank-settings', payload)
    toastStore.success(res.data.message || 'Pengaturan batas ranking dan jadwal reset berhasil disimpan!')
    Object.assign(initialForm, form)

    if (res.data.stats) {
      Object.assign(stats, res.data.stats)
    }
  } catch (err) {
    console.error('Failed to save rank settings', err)
    const msg = err.response?.data?.message || 'Gagal menyimpan pengaturan.'
    toastStore.error(msg)
  } finally {
    saving.value = false
  }
}

const confirmManualReset = async () => {
  if (saving.value) return
  saving.value = true

  try {
    const res = await api.post('/admin/rank-settings/manual-reset')
    toastStore.success(res.data.message || 'Leaderboard berhasil direset sekarang!')
    isManualResetModalOpen.value = false
    await fetchSettings()
  } catch (err) {
    console.error('Failed to manual reset leaderboard', err)
    toastStore.error('Gagal melakukan reset leaderboard.')
  } finally {
    saving.value = false
  }
}

const confirmClearManualReset = async () => {
  if (saving.value) return
  saving.value = true

  try {
    const res = await api.post('/admin/rank-settings/clear-manual-reset')
    toastStore.success(res.data.message || 'Reset manual berhasil dibatalkan.')
    isClearManualResetModalOpen.value = false
    await fetchSettings()
  } catch (err) {
    console.error('Failed to clear manual reset', err)
    toastStore.error('Gagal membatalkan reset manual.')
  } finally {
    saving.value = false
  }
}

const confirmReset = async () => {
  if (saving.value) return
  saving.value = true

  try {
    const res = await api.post('/admin/rank-settings/reset-defaults')
    toastStore.success(res.data.message || 'Pengaturan berhasil dikembalikan ke default!')
    isResetModalOpen.value = false
    await fetchSettings()
  } catch (err) {
    console.error('Failed to reset rank settings', err)
    toastStore.error('Gagal mengembalikan ke default.')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  fetchSettings()
})
</script>

<style scoped src="@/styles/features/admin-rank-settings.css"></style>
