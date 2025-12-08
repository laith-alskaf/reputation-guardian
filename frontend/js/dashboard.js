/**
 * Dashboard rendering & interactions
 */

const DashboardManager = {
  cache: new Map(),
  realtimeInterval: null,
  notifications: [],

  async init() {
    const isAuth = await AuthManager.checkAuthStatus();
    if (!isAuth) {
      window.UI.Toast.show('يرجى تسجيل الدخول أولاً', 'error');
      window.location.href = 'index.html';
      return;
    }

    // Show user info since authenticated
    document.getElementById('userInfo').style.display = 'flex';

    this.initRealtimeUpdates();
    await this.loadDashboardData();
    this.initDashboardFeatures();
    this.updateUserName();
    this.initNotifications();
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
    const el = document.getElementById('metricsContainer');
    if (!el) return;

    const metrics = [
      { icon: 'fas fa-star', value: m.average_stars ?? 0, label: 'متوسط النجوم', class: '' },
      { icon: 'fas fa-chart-line', value: m.total_reviews ?? 0, label: 'إجمالي التقييمات', class: '' },
      { icon: 'fas fa-thumbs-up', value: m.positive_reviews ?? 0, label: 'التقييمات الإيجابية', class: 'positive' },
      { icon: 'fas fa-exclamation-triangle', value: m.negative_reviews ?? 0, label: 'التقييمات السلبية', class: 'negative' },
      { icon: 'fas fa-balance-scale', value: m.neutral_reviews ?? 0, label: 'التقييمات المحايدة', class: '' }
    ];

    el.innerHTML = metrics.map((metric, index) => `
      <div class="metric-card ${metric.class} animate-scale-bounce animate-stagger-${index + 1}">
        <div class="metric-icon"><i class="${metric.icon} animate-sentiment-wave"></i></div>
        <div class="metric-value animate-data-flow">${metric.value}</div>
        <div class="metric-label">${metric.label}</div>
      </div>
    `).join('');
  },

  updateRecentReviews(reviews) {
    const container = document.querySelector('.recent-reviews');
    if (!container) return;
    if (!reviews.length) {
      container.innerHTML = '<p class="no-data">لا توجد تقييمات حديثة</p>';
      return;
    }

    const cards = reviews.map((r) => {
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
  },

  // Real-time Updates
  initRealtimeUpdates() {
    // Check for new data every 30 seconds
    this.realtimeInterval = setInterval(async () => {
      try {
        const data = await window.API.dashboard.getDashboard();
        this.checkForUpdates(data);
      } catch (e) {
        console.warn('Realtime update failed:', e);
      }
    }, 30000);
  },

  checkForUpdates(newData) {
    const cacheKey = 'dashboard_data';
    const cached = this.cache.get(cacheKey);

    if (cached) {
      const hasNewReviews = (newData.metrics?.total_reviews || 0) > (cached.metrics?.total_reviews || 0);
      if (hasNewReviews) {
        this.addNotification({
          type: 'new_review',
          message: 'تقييم جديد تم استلامه!',
          icon: 'fas fa-star',
          timestamp: new Date()
        });
        this.updateMetrics(newData.metrics);
        this.updateRecentReviews(newData.recent_reviews);
        this.updateLastUpdated(newData.last_updated);
      }
    }

    this.cache.set(cacheKey, newData);
  },

  // Notifications System
  initNotifications() {
    this.renderNotifications();
  },

  addNotification(notification) {
    this.notifications.unshift(notification);
    if (this.notifications.length > 10) {
      this.notifications = this.notifications.slice(0, 10);
    }
    this.renderNotifications();
    this.showNotificationPanel();
  },

  renderNotifications() {
    const container = document.getElementById('notificationsList');
    if (!container) return;

    if (!this.notifications.length) {
      container.innerHTML = '<p class="no-data">لا توجد إشعارات جديدة</p>';
      return;
    }

    container.innerHTML = this.notifications.map(notification => `
      <div class="notification-item animate-notification">
        <div class="notification-icon">
          <i class="${notification.icon}"></i>
        </div>
        <div class="notification-content">
          <p class="notification-message">${notification.message}</p>
          <span class="notification-time">${this.formatNotificationTime(notification.timestamp)}</span>
        </div>
      </div>
    `).join('');
  },

  formatNotificationTime(timestamp) {
    const now = new Date();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'الآن';
    if (minutes < 60) return `منذ ${minutes} دقيقة`;

    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `منذ ${hours} ساعة`;

    return timestamp.toLocaleDateString('ar-SA');
  },

  showNotificationPanel() {
    const panel = document.getElementById('notificationsPanel');
    if (panel) {
      panel.style.display = 'block';
      panel.classList.add('animate-float-up');
    }
  },

  // Sentiment Details Modal
  showSentimentDetails(sentiment, count) {
    const modal = document.createElement('div');
    modal.className = 'modal';
    modal.innerHTML = `
      <div class="modal-content">
        <div class="modal-header">
          <h3>تفاصيل التقييمات ${sentiment}</h3>
          <span class="modal-close" onclick="this.closest('.modal').remove()">&times;</span>
        </div>
        <div class="modal-body">
          <div class="sentiment-stats">
            <div class="metric-card ${sentiment === 'إيجابي' ? 'positive' : sentiment === 'سلبي' ? 'negative' : ''}">
              <div class="metric-icon">
                <i class="${sentiment === 'إيجابي' ? 'fas fa-thumbs-up' : sentiment === 'سلبي' ? 'fas fa-exclamation-triangle' : 'fas fa-balance-scale'} animate-sentiment-wave"></i>
              </div>
              <div class="metric-value">${count}</div>
              <div class="metric-label">عدد التقييمات ${sentiment}</div>
            </div>
          </div>
          <div class="sentiment-insights">
            <h4>رؤى وتوصيات:</h4>
            <ul>
              ${this.getSentimentInsights(sentiment, count)}
            </ul>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
    modal.classList.add('show');
  },

  getSentimentInsights(sentiment, count) {
    const insights = {
      'إيجابي': [
        'استمر في تقديم نفس الجودة العالية',
        'شارك قصص النجاح مع العملاء',
        'استخدم هذه التقييمات في التسويق'
      ],
      'سلبي': [
        'ركز على حل المشاكل المذكورة في التقييمات',
        'تواصل مع العملاء المستائين لتحسين الخدمة',
        'راجع عملياتك الداخلية للكشف عن المشاكل'
      ],
      'محايد': [
        'حاول تحويل التقييمات المحايدة إلى إيجابية',
        'اطلب المزيد من التفاصيل من العملاء',
        'ركز على نقاط القوة لتعزيز الرضا'
      ]
    };

    return (insights[sentiment] || []).map(insight => `<li>${insight}</li>`).join('');
  },

  clearNotifications() {
    this.notifications = [];
    this.renderNotifications();
    const panel = document.getElementById('notificationsPanel');
    if (panel) panel.style.display = 'none';
  },

  // Advanced Analytics
  showAdvancedAnalytics() {
    window.UI.Toast.show('سيتم إضافة التحليلات المتقدمة قريباً', 'info');
  },

  // Export Functions
  async exportData() {
    try {
      const data = await window.API.dashboard.getDashboard();
      const csvContent = this.convertToCSV(data.recent_reviews || []);
      this.downloadCSV(csvContent, `reviews-${Date.now()}.csv`);
      window.UI.Toast.show('تم تصدير البيانات بنجاح', 'success');
    } catch (e) {
      console.error('Export failed:', e);
      window.UI.Toast.show('فشل في تصدير البيانات', 'error');
    }
  },

  convertToCSV(reviews) {
    const headers = ['التاريخ', 'النجوم', 'النوع', 'النص'];
    const rows = reviews.map(review => [
      window.UI.Utils.formatDate(review.timestamp),
      review.stars || 0,
      this.getReviewTypeLabel(review.review_type || 'محايد'),
      (review.text || '').replace(/"/g, '""')
    ]);

    const csvContent = [headers, ...rows]
      .map(row => row.map(cell => `"${cell}"`).join(','))
      .join('\n');

    return csvContent;
  },

  downloadCSV(content, filename) {
    const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
  },

  // Report Functions
  async generateWeeklyReport() {
    try {
      const data = await window.API.dashboard.getDashboard();
      const report = this.generateReportContent(data);
      this.downloadReport(report);
      window.UI.Toast.show('تم إرسال التقرير الأسبوعي', 'success');
    } catch (e) {
      console.error('Report generation failed:', e);
      window.UI.Toast.show('فشل في إنشاء التقرير', 'error');
    }
  },

  generateReportContent(data) {
    const metrics = data.metrics || {};
    const shop = data.shop_info || {};

    return `
إحصائية أداء المتجر الأسبوعية

المتجر: ${shop.shop_name || 'غير محدد'}
الفترة: ${new Date().toLocaleDateString('ar-SA')}

الإحصائيات:
- إجمالي التقييمات: ${metrics.total_reviews || 0}
- متوسط النجوم: ${metrics.average_stars || 0}
- التقييمات الإيجابية: ${metrics.positive_reviews || 0}
- التقييمات السلبية: ${metrics.negative_reviews || 0}
- التقييمات المحايدة: ${metrics.neutral_reviews || 0}

أحدث التقييمات:
${(data.recent_reviews || []).slice(0, 5).map(review =>
  `- ${this.getReviewTypeLabel(review.review_type || 'محايد')}: ${window.UI.Utils.truncate(review.text || '', 50)}`
).join('\n')}

تم إنشاء هذا التقرير بواسطة نظام حارس السمعة
    `.trim();
  },

  downloadReport(content) {
    const blob = new Blob([content], { type: 'text/plain;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `weekly-report-${Date.now()}.txt`;
    link.click();
  }
};

/**
 * رسم مخطط التقييمات باستخدام Chart.js مع animations محسنة
 */
function renderReviewsChart(metrics) {
  const ctx = document.getElementById('reviewsChart');
  if (!ctx) return;

  // Hide loading and show chart
  const container = ctx.parentElement;
  const loading = container.querySelector('.loading-dots');
  if (loading) loading.style.display = 'none';
  ctx.style.display = 'block';

  const data = {
    labels: ['إيجابي', 'سلبي', 'محايد'],
    datasets: [{
      label: 'عدد التقييمات',
      data: [
        metrics.positive_reviews ?? 0,
        metrics.negative_reviews ?? 0,
        metrics.neutral_reviews ?? 0
      ],
      backgroundColor: [
        'rgba(76, 175, 80, 0.8)',
        'rgba(244, 67, 54, 0.8)',
        'rgba(255, 193, 7, 0.8)'
      ],
      borderColor: [
        'rgba(76, 175, 80, 1)',
        'rgba(244, 67, 54, 1)',
        'rgba(255, 193, 7, 1)'
      ],
      borderWidth: 2,
      borderRadius: 8,
      borderSkipped: false,
    }]
  };

  const chart = new Chart(ctx, {
    type: 'bar',
    data: data,
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: {
        duration: 2000,
        easing: 'easeOutBounce',
        onComplete: function() {
          ctx.classList.add('animate-chart-grow');
        }
      },
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: true,
          text: 'إحصائيات التقييمات',
          font: {
            size: 16,
            weight: 'bold'
          },
          padding: 20
        },
        tooltip: {
          backgroundColor: 'rgba(0,0,0,0.8)',
          titleColor: '#fff',
          bodyColor: '#fff',
          cornerRadius: 8,
          displayColors: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: {
            color: 'rgba(0,0,0,0.1)'
          },
          ticks: {
            stepSize: 1
          }
        },
        x: {
          grid: {
            display: false
          }
        }
      },
      onHover: (event, activeElements) => {
        event.native.target.style.cursor = activeElements.length > 0 ? 'pointer' : 'default';
      }
    }
  });

  // Add click interaction for detailed view
  ctx.onclick = function(evt) {
    const activePoints = chart.getElementsAtEventForMode(evt, 'nearest', { intersect: true }, true);
    if (activePoints.length > 0) {
      const index = activePoints[0].index;
      const sentiment = data.labels[index];
      const count = data.datasets[0].data[index];

      DashboardManager.showSentimentDetails(sentiment, count);
    }
  };

  return chart;
}

window.DashboardManager = DashboardManager;
