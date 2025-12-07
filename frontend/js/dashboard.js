/**
 * Dashboard rendering & interactions
 */

const DashboardManager = {
  async init() {
    if (!window.API.isAuthenticated()) {
      window.UI.Toast.show('يرجى تسجيل الدخول أولاً', 'error');
      setTimeout(() => (window.location.href = 'index.html'), 1500);
      return;
    }
    await this.loadDashboardData();
    this.initDashboardFeatures();
    this.updateUserName();
  },

  async loadDashboardData() {
    try {
      window.UI.Loading.show('dashboardContainer');
      const data = await window.API.dashboard.getDashboard();
      this.renderDashboard(data);
      window.UI.Toast.show('تم تحديث البيانات بنجاح', 'success');
    } catch (e) {
      console.error('Failed to load dashboard:', e);
      window.UI.Toast.show('فشل في تحميل بيانات لوحة التحكم', 'error');
    } finally {
      window.UI.Loading.hide('dashboardContainer');
    }
  },

  renderDashboard(data) {
    // Normalize data shape from API sample:
    const metrics = data.metrics || {};
    const reviews = data.recent_reviews || [];
    const shopInfo = data.shop_info || {};
    const lastUpdated = data.last_updated;

    this.updateMetrics(metrics);
    renderReviewsChart(metrics);
    this.updateRecentReviews(reviews);
    this.updateShopInfo(shopInfo);
    this.updateLastUpdated(lastUpdated);
  },

  updateMetrics(m) {
    const el = document.querySelector('.metrics-grid');
    if (!el) return;
    el.innerHTML = `
      <div class="metric-card">
        <div class="metric-icon"><i class="fas fa-star"></i></div>
        <div class="metric-value">${m.average_stars ?? 0}</div>
        <div class="metric-label">متوسط النجوم</div>
      </div>
      <div class="metric-card">
        <div class="metric-icon"><i class="fas fa-chart-line"></i></div>
        <div class="metric-value">${m.total_reviews ?? 0}</div>
        <div class="metric-label">إجمالي التقييمات</div>
      </div>
      <div class="metric-card positive">
        <div class="metric-icon"><i class="fas fa-thumbs-up"></i></div>
        <div class="metric-value">${m.positive_reviews ?? 0}</div>
        <div class="metric-label">التقييمات الإيجابية</div>
      </div>
      <div class="metric-card negative">
        <div class="metric-icon"><i class="fas fa-exclamation-triangle"></i></div>
        <div class="metric-value">${m.negative_reviews ?? 0}</div>
        <div class="metric-label">التقييمات السلبية</div>
      </div>
      <div class="metric-card">
        <div class="metric-icon"><i class="fas fa-balance-scale"></i></div>
        <div class="metric-value">${m.neutral_reviews ?? 0}</div>
        <div class="metric-label">التقييمات المحايدة</div>
      </div>
    `;
  },

  updateRecentReviews(reviews) {
    const container = document.querySelector('.recent-reviews');
    if (!container) return;
    if (!reviews.length) {
      container.innerHTML = '<p class="no-data">لا توجد تقييمات حديثة</p>';
      return;
    }

    const cards = reviews.map((r) => {
      // API sample: text is inside original_fields.text, review_type inside technical_analysis.review_type
      const text = r.text || r.original_fields?.text || '';
      const type = r.review_type || r.technical_analysis?.review_type || 'محايد';
      const typeClass = this.getReviewTypeClass(type);
      const stars = '⭐'.repeat(r.stars || 0);
      const date = window.UI.Utils.formatDate(r.timestamp);

      return `
        <div class="review-card">
          <div class="review-header">
            <div class="review-stars">${stars}</div>
            <div class="review-date">${date}</div>
          </div>
          <div class="review-text">${window.UI.Utils.truncate(text, 160)}</div>
          <div class="review-type ${typeClass}">${this.getReviewTypeLabel(type)}</div>

          ${r.solutions ? `
          <div class="review-solution mt-3">
            <strong>الحل المقترح:</strong>
            <p>${window.UI.Utils.truncate(r.solutions, 300)}</p>
          </div>` : ''}

          ${r.suggested_reply ? `
          <div class="review-solution mt-3">
            <strong>الرد المقترح:</strong>
            <p>${window.UI.Utils.truncate(r.suggested_reply, 300)}</p>
          </div>` : ''}

          ${r.organized_feedback ? `
          <div class="review-solution mt-3">
            <strong>ملخص آراء العميل:</strong>
            <p>${r.organized_feedback}</p>
          </div>` : ''}
        </div>
      `;
    }).join('');

    container.innerHTML = cards;
  },

  updateShopInfo(info) {
    const el = document.querySelector('.shop-info');
    if (!el) return;
    el.innerHTML = `
      <h3>${info.shop_name || 'المتجر'}</h3>
      <p><strong>نوع المتجر:</strong> ${info.shop_type || 'غير محدد'}</p>
      <p><strong>معرف المتجر:</strong> ${info.shop_id || 'غير محدد'}</p>
      <p><strong>تاريخ التسجيل:</strong> ${window.UI.Utils.formatDate(info.created_at)}</p>
    `;
  },

  updateUserName: async function () {
    try {
      const profile = await window.API.dashboard.getProfile();
      const el = document.getElementById('userName');
      if (el && profile) el.textContent = profile.shop_name || profile.email || 'المستخدم';
    } catch (e) {
      console.warn('Failed to load profile:', e);
    }
  },

  updateLastUpdated(ts) {
    const elements = document.querySelectorAll('.last-updated');
    const text = ts ? window.UI.Utils.formatDate(ts) : 'الآن';
    elements.forEach((e) => (e.textContent = `آخر تحديث: ${text}`));
  },

  initDashboardFeatures() {
    const refreshBtn = document.getElementById('refreshDashboard');
    if (refreshBtn) refreshBtn.addEventListener('click', () => this.loadDashboardData());

    const generateQRBtn = document.getElementById('generateQR');
    if (generateQRBtn) generateQRBtn.addEventListener('click', () => this.generateNewQR());

    const reviewFilter = document.getElementById('reviewFilter');
    if (reviewFilter) reviewFilter.addEventListener('change', (e) => this.filterReviews(e.target.value));
  },

  async generateNewQR() {
    try {
      window.UI.Loading.show('generateQR');
      const qrData = await window.API.qr.generateQR();
      this.displayGeneratedQR(qrData);
      window.UI.Toast.show('تم إنشاء رمز QR بنجاح', 'success');
      setTimeout(() => this.loadDashboardData(), 800);
    } catch (e) {
      console.error('QR generation failed:', e);
      window.UI.Toast.show('فشل في إنشاء رمز QR', 'error');
    } finally {
      window.UI.Loading.hide('generateQR');
    }
  },

  displayGeneratedQR(qrData) {
    const container = document.getElementById('qrDisplay');
    if (!container || !qrData.qr_code) return;
    container.innerHTML = `
      <div class="qr-success">
        <img src="data:image/png;base64,${qrData.qr_code}" alt="Generated QR Code" class="qr-image">
        <div class="qr-info">
          <p><strong>تم إنشاء رمز QR جديد بنجاح!</strong></p>
          <p>يمكنك الآن طباعة هذا الرمز ووضعه في متجرك.</p>
          <button class="btn btn-primary" onclick="DashboardManager.downloadQR('${qrData.qr_code}')">
            <i class="fas fa-download"></i> تحميل QR
          </button>
        </div>
      </div>
    `;
  },

  downloadQR(base64) {
    const link = document.createElement('a');
    link.download = `qr-code-${Date.now()}.png`;
    link.href = `data:image/png;base64,${base64}`;
    link.click();
  },

  filterReviews(type) {
    const cards = document.querySelectorAll('.review-card');
    const map = { 'إيجابي': 'positive', 'نقد': 'warning', 'شكوى': 'negative' };
    cards.forEach((card) => {
      if (!type) { card.style.display = 'block'; return; }
      const badge = card.querySelector('.review-type');
      const cls = badge ? badge.className.split(' ').find(c => c !== 'review-type') : '';
      card.style.display = (map[type] === cls) ? 'block' : 'none';
    });
  },

  getReviewTypeClass(t) {
    switch (t) {
      case 'إيجابي': return 'positive';
      case 'نقد': return 'warning';
      case 'شكوى': return 'negative';
      default: return 'neutral';
    }
  },
  getReviewTypeLabel(t) {
    switch (t) {
      case 'إيجابي': return 'إيجابي';
      case 'نقد': return 'نقد بناء';
      case 'شكوى': return 'شكوى';
      default: return 'محايد';
    }
  }
};
function renderReviewsChart(metrics) {
  const ctx = document.getElementById('reviewsChart').getContext('2d');
  if (!ctx) return;

  // لو فيه مخطط قديم نحذفه
  if (window.reviewsChartInstance) {
    window.reviewsChartInstance.destroy();
  }

  window.reviewsChartInstance = new Chart(ctx, {
    type: 'pie',
    data: {
      labels: ['إيجابي', 'سلبي', 'محايد'],
      datasets: [{
        data: [
          metrics.positive_reviews || 0,
          metrics.negative_reviews || 0,
          metrics.neutral_reviews || 0
        ],
        backgroundColor: [
          '#10b981', // أخضر للإيجابي
          '#ef4444', // أحمر للسلبي
          '#64748b'  // رمادي للمحايد
        ],
        borderColor: '#ffffff',
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
          labels: {
            font: { size: 14 }
          }
        },
        title: {
          display: true,
          text: 'توزيع التقييمات',
          font: { size: 18 }
        }
      }
    }
  });
}
function generateWeeklyReport() { /* server-side in future */ window.UI.Toast.show('سيتم إضافة إرسال التقارير قريباً', 'warning'); }
function exportData() { DashboardManagerExportCSV(); }

async function DashboardManagerExportCSV() {
  try {
    const data = await window.API.dashboard.getDashboard();
    const reviews = data.recent_reviews || [];
    if (!reviews.length) return window.UI.Toast.show('لا توجد بيانات للتصدير', 'warning');

    const headers = ['Date', 'Stars', 'Review Type', 'Text', 'Solutions'];
    const rows = reviews.map(r => {
      const text = (r.text || r.original_fields?.text || '').replace(/"/g, '""');
      const type = r.review_type || r.technical_analysis?.review_type || '';
      const solutions = (r.solutions || '').replace(/"/g, '""');
      return [r.timestamp || '', r.stars || 0, type, `"${text}"`, `"${solutions}"`].join(',');
    });
    const csv = [headers.join(','), ...rows].join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `reviews-export-${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    window.UI.Toast.show('تم تصدير البيانات بنجاح', 'success');
  } catch (e) {
    console.error('Export failed:', e);
    window.UI.Toast.show('فشل في تصدير البيانات', 'error');
  }
}

document.addEventListener('DOMContentLoaded', () => {
  if (window.location.pathname.includes('dashboard')) {
    DashboardManager.init();
  }
});

window.DashboardManager = DashboardManager;