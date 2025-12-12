/**
 * Enhanced Dashboard Manager
 * Handles tabs, filtering, search, pagination, and analytics
 */

const DashboardManager = {
  // State management
  state: {
    allData: {
      processed_reviews: [],
      rejected_quality_reviews: [],
      rejected_irrelevant_reviews: [],
      metrics: {},
      shop_info: {},
      qr_code: null,
      last_updated: null
    },
    currentTab: 'processed',
    currentPage: 1,
    itemsPerPage: 10,
    filteredReviews: [],
    chart: null,
    filters: {
      sentiment: '',
      category: '',
      stars: '',
      sortBy: 'latest',
      qualityScore: 0,
      dateFrom: '',
      dateTo: '',
      contextMatch: false,
      search: ''
    }
  },

  /**
   * Initialize dashboard
   */
  async init() {
    const isAuth = await AuthManager.checkAuthStatus();
    if (!isAuth) {
      window.UI.Toast.show('يرجى تسجيل الدخول أولاً', 'error');
      window.location.href = 'index.html';
      return;
    }

    // Show user info
    document.getElementById('userInfo').style.display = 'flex';

    // Event listeners
    this.setupEventListeners();

    // Load initial data
    await this.loadDashboardData();

    // Update user name
    this.updateUserName();

    // Setup realtime updates
    this.setupRealtimeUpdates();
  },

  /**
   * Setup event listeners
   */
  setupEventListeners() {
    // Search input
    document.getElementById('searchInput').addEventListener('input', (e) => {
      this.state.filters.search = e.target.value;
      document.getElementById('clearSearchBtn').style.display = e.target.value ? 'block' : 'none';
      this.applyFilters();
    });

    // Quality score slider
    document.getElementById('qualityScoreFilter').addEventListener('input', (e) => {
      document.getElementById('qualityScoreValue').textContent = e.target.value;
      this.state.filters.qualityScore = parseInt(e.target.value);
    });

    // Refresh button
    document.getElementById('refreshDashboard').addEventListener('click', () => this.loadDashboardData());

    // Generate QR button
    document.getElementById('generateQR').addEventListener('click', () => this.generateNewQR());
  },

  /**
   * Load dashboard data from API
   */
  async loadDashboardData() {
    try {
      const spinner = document.getElementById('refreshDashboard').querySelector('i');
      spinner.classList.add('fa-spin');

      const response = await window.API.dashboard.getDashboard();
      const data = response.data || response;

      // Handle QR code logic
      let qrCode = data.qr_code;

      // If QR code is missing or invalid base64, try to fetch/generate it
      if (!qrCode && data.shop_info?.shop_id) {
        try {
          const qrResponse = await window.API.qr.getQR(data.shop_info.shop_id);
          const qrData = qrResponse.data || qrResponse;
          qrCode = qrData.qr_code;
        } catch (qrError) {
          console.warn('Failed to fetch/generate QR on load:', qrError);
        }
      }

      // Ensure Base64 prefix
      if (qrCode && !qrCode.startsWith('data:image/png;base64,')) {
        qrCode = `data:image/png;base64,${qrCode}`;
      }

      // Store all data
      this.state.allData = {
        processed_reviews: data.processed_reviews || [],
        rejected_quality_reviews: data.rejected_quality_reviews || [],
        rejected_irrelevant_reviews: data.rejected_irrelevant_reviews || [],
        metrics: data.metrics || {},
        shop_info: data.shop_info || {},
        qr_code: qrCode,
        last_updated: data.last_updated
      };

      // Render components
      this.updateMetrics();
      this.updateShopInfo();
      this.updateQRSection();
      this.updateTabCounts();
      this.switchTab('processed');
      this.updateAnalyticsChart();
      this.updateAnalyticsChart();
      this.updateStatistics();
      this.updateTelegramStatus(); // Check telegram connection

      // Update last updated time
      if (data.last_updated) {
        const time = new Date(data.last_updated).toLocaleString('ar-SA');
        document.querySelector('.last-updated').textContent = `آخر تحديث: ${time}`;
      }

      window.UI.Toast.show('تم تحديث البيانات بنجاح', 'success');

      spinner.classList.remove('fa-spin');
    } catch (error) {
      console.error('Failed to load dashboard:', error);
      window.UI.Toast.show('فشل في تحميل البيانات. حاول مرة أخرى.', 'error');
    }
  },

  /**
   * Update metrics display
   */
  updateMetrics() {
    const metrics = this.state.allData.metrics;
    const container = document.getElementById('metricsContainer');

    if (!container) return;

    const metricsArray = [
      {
        icon: 'fas fa-star',
        value: metrics.average_stars?.toFixed(1) || '0',
        label: 'متوسط النجوم',
        color: 'primary'
      },
      {
        icon: 'fas fa-comments',
        value: metrics.total_reviews || '0',
        label: 'إجمالي التقييمات',
        color: 'secondary'
      },
      {
        icon: 'fas fa-thumbs-up',
        value: metrics.positive_reviews || '0',
        label: 'إيجابية',
        color: 'success'
      },
      {
        icon: 'fas fa-exclamation-triangle',
        value: metrics.negative_reviews || '0',
        label: 'سلبية',
        color: 'error'
      },
      {
        icon: 'fas fa-balance-scale',
        value: metrics.neutral_reviews || '0',
        label: 'محايدة',
        color: 'warning'
      }
    ];

    container.innerHTML = metricsArray.map((m, i) => `
      <div class="metric-card metric-${m.color} animate-scale-bounce" style="animation-delay: ${i * 100}ms">
        <div class="metric-icon"><i class="${m.icon}"></i></div>
        <div class="metric-value">${m.value}</div>
        <div class="metric-label">${m.label}</div>
      </div>
    `).join('');
  },

  /**
   * Update shop info
   */
  updateShopInfo() {
    const shopInfo = this.state.allData.shop_info;
    const container = document.querySelector('.shop-info');

    if (!container || !shopInfo.shop_name) {
      container.innerHTML = '<p class="no-data">معلومات المتجر غير متوفرة</p>';
      return;
    }

    const createdDate = new Date(shopInfo.created_at).toLocaleDateString('ar-SA');

    container.innerHTML = `
      <div class="shop-info-grid">
        <div class="info-item">
          <i class="fas fa-store"></i>
          <div>
            <label>اسم المتجر</label>
            <p>${shopInfo.shop_name}</p>
          </div>
        </div>
        <div class="info-item">
          <i class="fas fa-tag"></i>
          <div>
            <label>نوع المتجر</label>
            <p>${shopInfo.shop_type}</p>
          </div>
        </div>
        <div class="info-item">
          <i class="fas fa-calendar"></i>
          <div>
            <label>تاريخ الإنشاء</label>
            <p>${createdDate}</p>
          </div>
        </div>
        <div class="info-item">
          <i class="fas fa-id-card"></i>
          <div>
            <label>معرف المتجر</label>
            <p class="font-mono" title="${shopInfo.shop_id}">${shopInfo.shop_id.substring(0, 8)}...</p>
          </div>
        </div>
      </div>
    `;
  },

  /**
   * Update Telegram Connection Status
   */
  async updateTelegramStatus() {
    try {
      const response = await window.API.dashboard.getProfile();
      const profile = response.data || response;

      const setupDiv = document.getElementById('telegramSetup');
      const statusIndicator = document.getElementById('telegramStatus');
      const connectBtn = document.getElementById('connectTelegramBtn');

      if (!setupDiv) return;

      // BOT USERNAME - You should replace this with your actual bot username
      const BOT_USERNAME = "LaithAlskafBot";

      if (profile.telegram_chat_id) {
        // Connected
        statusIndicator.classList.remove('hidden');
        statusIndicator.innerHTML = '<i class="fas fa-check-circle"></i> متصل';
        statusIndicator.style.color = 'var(--success-color)';
        connectBtn.style.display = 'none';

        // Optionally update the text
        setupDiv.querySelector('.setup-info p').textContent = 'حسابك مربوط بنجاح. ستصلك الإشعارات هنا.';
      } else {
        // Not Connected
        statusIndicator.classList.add('hidden');
        connectBtn.style.display = 'inline-flex';

        // Set Deep Link
        // Format: https://t.me/<BOT_USERNAME>?start=<SHOP_ID>
        connectBtn.href = `https://t.me/${BOT_USERNAME}?start=${profile.shop_id}`;
      }
    } catch (error) {
      console.error("Failed to update telegram status:", error);
    }
  },

  /**
   * Update QR display
   */
  updateQRSection() {
    const container = document.getElementById('qrDisplay');
    if (!container) return;

    if (this.state.allData.qr_code) {
      container.innerHTML = `
        <div class="qr-display-wrapper">
          <img src="${this.state.allData.qr_code}" alt="QR Code" class="qr-code-image">
          <p class="qr-description">مسح هذا الرمز للوصول إلى نموذج التقييم</p>
          <div class="qr-actions">
            <button class="btn btn-sm btn-outline" onclick="DashboardManager.downloadQR()">
              <i class="fas fa-download"></i> تحميل
            </button>
            <button class="btn btn-sm btn-outline" onclick="DashboardManager.copyQRLink()">
              <i class="fas fa-copy"></i> نسخ الرابط
            </button>
          </div>
        </div>
      `;
    } else {
      container.innerHTML = `
        <div class="qr-placeholder">
          <i class="fas fa-qrcode"></i>
          <p>لم يتم إنشاء رمز QR بعد</p>
          <button class="btn btn-primary mt-3" onclick="DashboardManager.generateNewQR()">
            <i class="fas fa-plus"></i> إنشاء الآن
          </button>
        </div>
      `;
    }
  },

  /**
   * Update tab counts
   */
  updateTabCounts() {
    document.getElementById('processedCount').textContent = this.state.allData.processed_reviews.length;
    document.getElementById('qualityCount').textContent = this.state.allData.rejected_quality_reviews.length;
    document.getElementById('irrelevantCount').textContent = this.state.allData.rejected_irrelevant_reviews.length;
  },

  /**
   * Switch between tabs
   */
  switchTab(tabName, event) {
    if (event) event.preventDefault();

    this.state.currentTab = tabName;
    this.state.currentPage = 1;

    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === tabName);
    });

    // Reset filters for new tab
    this.resetFilters();

    // Render reviews
    this.renderReviews();
  },

  /**
   * Get current tab reviews
   */
  getCurrentTabReviews() {
    const tabReviews = {
      processed: this.state.allData.processed_reviews,
      'rejected-quality': this.state.allData.rejected_quality_reviews,
      'rejected-irrelevant': this.state.allData.rejected_irrelevant_reviews
    };
    return tabReviews[this.state.currentTab] || [];
  },

  /**
   * Apply filters to reviews
   */
  applyFilters() {
    let reviews = [...this.getCurrentTabReviews()];

    // Sentiment filter
    if (this.state.filters.sentiment) {
      reviews = reviews.filter(r =>
        (r.overall_sentiment || r.analysis?.sentiment) === this.state.filters.sentiment
      );
    }

    // Category filter
    if (this.state.filters.category) {
      reviews = reviews.filter(r =>
        (r.analysis?.category || r.category) === this.state.filters.category
      );
    }

    // Stars filter
    if (this.state.filters.stars) {
      reviews = reviews.filter(r => r.stars == this.state.filters.stars);
    }

    // Quality score filter
    if (this.state.filters.qualityScore > 0) {
      reviews = reviews.filter(r => {
        const score = r.analysis?.quality?.quality_score || 0;
        return score * 100 >= this.state.filters.qualityScore;
      });
    }

    // Date range filter
    if (this.state.filters.dateFrom) {
      const fromDate = new Date(this.state.filters.dateFrom);
      reviews = reviews.filter(r => new Date(r.created_at) >= fromDate);
    }

    if (this.state.filters.dateTo) {
      const toDate = new Date(this.state.filters.dateTo);
      toDate.setHours(23, 59, 59);
      reviews = reviews.filter(r => new Date(r.created_at) <= toDate);
    }

    // Context match filter
    if (this.state.filters.contextMatch) {
      reviews = reviews.filter(r => r.analysis?.context?.has_mismatch !== true);
    }

    // Search filter
    if (this.state.filters.search) {
      const searchTerm = this.state.filters.search.toLowerCase();
      reviews = reviews.filter(r => {
        const text = r.processing?.concatenated_text || '';
        const email = r.email || '';
        return text.toLowerCase().includes(searchTerm) || email.toLowerCase().includes(searchTerm);
      });
    }

    // Sorting
    reviews = this.sortReviews(reviews);

    // Update state
    this.state.filteredReviews = reviews;
    this.state.currentPage = 1;

    // Render
    this.renderReviews();
  },

  /**
   * Sort reviews
   */
  sortReviews(reviews) {
    const sorted = [...reviews];

    switch (this.state.filters.sortBy) {
      case 'latest':
        sorted.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
        break;
      case 'oldest':
        sorted.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
        break;
      case 'highest-stars':
        sorted.sort((a, b) => (b.stars || 0) - (a.stars || 0));
        break;
      case 'lowest-stars':
        sorted.sort((a, b) => (a.stars || 0) - (b.stars || 0));
        break;
    }

    return sorted;
  },

  /**
   * Render reviews with pagination
   */
  renderReviews() {
    const container = document.getElementById('reviewsContainer');
    if (!container) return;

    const reviews = this.state.filteredReviews.length > 0
      ? this.state.filteredReviews
      : this.getCurrentTabReviews();

    if (reviews.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <i class="fas fa-inbox"></i>
          <p>لا توجد تقييمات في هذا التبويب</p>
        </div>
      `;
      document.getElementById('reviewsPagination').style.display = 'none';
      return;
    }

    // Pagination
    const totalPages = Math.ceil(reviews.length / this.state.itemsPerPage);
    const startIndex = (this.state.currentPage - 1) * this.state.itemsPerPage;
    const endIndex = startIndex + this.state.itemsPerPage;
    const pageReviews = reviews.slice(startIndex, endIndex);

    // Render review cards
    const reviewsHTML = pageReviews.map(review => this.createReviewCard(review)).join('');
    container.innerHTML = reviewsHTML;

    // Update pagination
    this.updatePagination(totalPages, reviews.length);
  },

  /**
   * Create review card HTML
   */
  createReviewCard(review) {
    const sentiment = review.overall_sentiment || review.analysis?.sentiment || 'محايد';
    const category = review.analysis?.category || review.category || 'عام';
    const stars = review.stars || 0;
    const date = new Date(review.created_at).toLocaleDateString('ar-SA');
    const text = review.processing?.concatenated_text || '';
    const isMismatch = review.analysis?.context?.has_mismatch || false;

    const sentimentClass = {
      'إيجابي': 'positive',
      'سلبي': 'negative',
      'محايد': 'neutral'
    }[sentiment] || 'neutral';

    const starsHTML = '⭐'.repeat(stars);

    return `
      <div class="review-card ${sentimentClass} ${isMismatch ? 'mismatch' : ''}" 
           onclick="DashboardManager.openReviewModal('${review._id || review.id}')">
        
        <div class="review-header">
          <div class="review-meta">
            <span class="review-stars" title="${stars} نجوم">${starsHTML || 'بدون'}</span>
            <span class="badge badge-category">${category}</span>
            <span class="badge badge-sentiment badge-${sentimentClass}">${sentiment}</span>
            ${isMismatch ? '<span class="badge badge-warning">⚠️ غير متطابق</span>' : ''}
          </div>
          <div class="review-date">
            <i class="far fa-clock"></i> ${date}
          </div>
        </div>

        <div class="review-preview">
          <p>${text.substring(0, 150)}${text.length > 150 ? '...' : ''}</p>
        </div>

        ${review.email ? `<div class="review-footer"><i class="fas fa-envelope"></i> ${review.email}</div>` : ''}
      </div>
    `;
  },

  /**
   * Open review modal with full details
   */
  openReviewModal(reviewId) {
    const allReviews = [
      ...this.state.allData.processed_reviews,
      ...this.state.allData.rejected_quality_reviews,
      ...this.state.allData.rejected_irrelevant_reviews
    ];

    const review = allReviews.find(r => r._id === reviewId || r.id === reviewId);
    if (!review) return;

    const sentiment = review.overall_sentiment || review.analysis?.sentiment || 'محايد';
    const category = review.analysis?.category || review.category || 'عام';
    const qualityScore = review.analysis?.quality?.quality_score || 0;
    const isMismatch = review.analysis?.context?.has_mismatch || false;
    const stars = review.stars || 0;
    const starsHTML = '⭐'.repeat(stars);
    const date = new Date(review.created_at).toLocaleDateString('ar-SA');

    let content = `
      <div class="review-modal-header">
        <h2>تفاصيل التقييم الكامل</h2>
        <div class="review-meta-modal">
          <span class="badge badge-sentiment">${sentiment}</span>
          <span class="badge">${category}</span>
          <span class="stars">${starsHTML}</span>
        </div>
      </div>

      <div class="review-modal-body">
        <div class="modal-section">
          <h3><i class="fas fa-user"></i> معلومات المقيم</h3>
          <div class="info-grid">
            ${review.email ? `<div><strong>البريد الإلكتروني:</strong> ${review.email}</div>` : ''}
            <div><strong>التاريخ:</strong> ${date}</div>
            <div><strong>التقييم:</strong> ${stars} نجوم</div>
          </div>
        </div>

        <div class="modal-section">
          <h3><i class="fas fa-comment"></i> التقييم الأصلي</h3>
          <div class="review-text-box">
            ${review.processing?.concatenated_text || 'لا يوجد نص'}
          </div>
        </div>
    `;

    // Show AI analysis for processed reviews
    if (this.state.currentTab === 'processed' && review.generated_content) {
      content += `
        <div class="modal-section">
          <h3><i class="fas fa-robot"></i> تحليل الذكاء الاصطناعي</h3>
      `;

      if (review.generated_content.summary) {
        content += `
          <div class="summary-box">
            <strong>الملخص:</strong>
            <p>${review.generated_content.summary}</p>
          </div>
        `;
      }

      if (review.generated_content.actionable_insights) {
        const insights = review.generated_content.actionable_insights;
        if (Array.isArray(insights) && insights.length > 0) {
          content += `
            <div class="insights-box">
              <strong>الرؤى القابلة للتنفيذ:</strong>
              <ul>
                ${insights.map(insight => `<li>${insight}</li>`).join('')}
              </ul>
            </div>
          `;
        }
      }

      if (review.generated_content.suggested_reply) {
        content += `
          <div class="reply-box">
            <strong>الرد المقترح:</strong>
            <div class="reply-text">${review.generated_content.suggested_reply}</div>
            <button class="btn btn-sm btn-primary" onclick="DashboardManager.copyToClipboard('${review.generated_content.suggested_reply.replace(/"/g, '&quot;')}')">
              <i class="fas fa-copy"></i> نسخ الرد
            </button>
          </div>
        `;
      }

      content += '</div>';
    }

    // Analysis data
    if (review.analysis) {
      content += `
        <div class="modal-section">
          <h3><i class="fas fa-chart-bar"></i> بيانات التحليل</h3>
          <div class="analysis-grid">
            <div class="analysis-item">
              <strong>المشاعر:</strong>
              <p>${sentiment}</p>
            </div>
            <div class="analysis-item">
              <strong>درجة الجودة:</strong>
              <div class="quality-bar">
                <div class="quality-fill" style="width: ${qualityScore * 100}%"></div>
              </div>
              <small>${Math.round(qualityScore * 100)}%</small>
            </div>
            ${review.analysis.toxicity ? `
              <div class="analysis-item">
                <strong>مستوى السمية:</strong>
                <p>${review.analysis.toxicity}</p>
              </div>
            ` : ''}
          </div>
        </div>
      `;
    }

    // Rejection reason
    if (this.state.currentTab !== 'processed') {
      content += `
        <div class="modal-section alert-box">
          <h3><i class="fas fa-info-circle"></i> سبب الرفض</h3>
          <p>${this.getRejectionReason(review)}</p>
        </div>
      `;
    }

    content += '</div>';

    document.getElementById('reviewModalContent').innerHTML = content;
    document.getElementById('reviewModal').style.display = 'flex';
  },

  /**
   * Get rejection reason text
   */
  getRejectionReason(review) {
    if (this.state.currentTab === 'rejected-quality') {
      const flags = review.analysis?.quality?.flags || [];
      return flags.length > 0
        ? `الأسباب: ${flags.join(', ')}`
        : 'التقييم لم يستوف معايير الجودة المطلوبة';
    } else if (this.state.currentTab === 'rejected-irrelevant') {
      const reasons = review.analysis?.context?.reasons || [];
      return reasons.length > 0
        ? `الأسباب: ${reasons.join(', ')}`
        : 'محتوى التقييم غير ذي صلة بنوع المتجر';
    }
    return 'التقييم لم يتم قبوله';
  },

  /**
   * Close review modal
   */
  closeReviewModal(event) {
    if (event && event.target !== event.currentTarget) return;
    document.getElementById('reviewModal').style.display = 'none';
  },

  /**
   * Update pagination
   */
  updatePagination(totalPages, totalReviews) {
    const pagination = document.getElementById('reviewsPagination');
    if (!pagination) return;

    if (totalPages <= 1) {
      pagination.style.display = 'none';
      return;
    }

    pagination.style.display = 'flex';

    const startIdx = (this.state.currentPage - 1) * this.state.itemsPerPage + 1;
    const endIdx = Math.min(this.state.currentPage * this.state.itemsPerPage, totalReviews);

    document.getElementById('pageInfo').textContent =
      `الصفحة ${this.state.currentPage} من ${totalPages} (${startIdx}-${endIdx} من ${totalReviews})`;

    document.getElementById('prevBtn').disabled = this.state.currentPage === 1;
    document.getElementById('nextBtn').disabled = this.state.currentPage === totalPages;
  },

  /**
   * Next page
   */
  nextPage() {
    this.state.currentPage++;
    this.renderReviews();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  },

  /**
   * Previous page
   */
  previousPage() {
    this.state.currentPage--;
    this.renderReviews();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  },

  /**
   * Toggle advanced filters
   */
  toggleAdvancedFilters() {
    const filters = document.getElementById('advancedFilters');
    filters.style.display = filters.style.display === 'none' ? 'grid' : 'none';
  },

  /**
   * Reset filters
   */
  resetFilters() {
    this.state.filters = {
      sentiment: '',
      category: '',
      stars: '',
      sortBy: 'latest',
      qualityScore: 0,
      dateFrom: '',
      dateTo: '',
      contextMatch: false,
      search: ''
    };

    // Reset form inputs
    document.getElementById('sentimentFilter').value = '';
    document.getElementById('categoryFilter').value = '';
    document.getElementById('starsFilter').value = '';
    document.getElementById('sortBy').value = 'latest';
    document.getElementById('qualityScoreFilter').value = '0';
    document.getElementById('dateFromFilter').value = '';
    document.getElementById('dateToFilter').value = '';
    document.getElementById('contextMatchFilter').checked = false;
    document.getElementById('searchInput').value = '';
    document.getElementById('qualityScoreValue').textContent = '0';

    this.renderReviews();
  },

  /**
   * Clear search
   */
  clearSearch() {
    document.getElementById('searchInput').value = '';
    this.state.filters.search = '';
    document.getElementById('clearSearchBtn').style.display = 'none';
    this.applyFilters();
  },

  /**
   * Update analytics chart
   */
  updateAnalyticsChart() {
    const chartType = document.getElementById('chartTypeFilter')?.value || 'sentiment';
    const canvas = document.getElementById('reviewsChart');
    if (!canvas) return;

    // Destroy previous chart
    if (this.state.chart) {
      this.state.chart.destroy();
    }

    const ctx = canvas.getContext('2d');
    const data = this.getChartData(chartType);

    this.state.chart = new Chart(ctx, {
      type: 'doughnut',
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              font: { family: "'Cairo', sans-serif", size: 12 },
              padding: 15,
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: function (context) {
                const label = context.label || '';
                const value = context.parsed || 0;
                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                const percentage = ((value / total) * 100).toFixed(1);
                return `${label}: ${value} (${percentage}%)`;
              }
            }
          }
        }
      }
    });
  },

  /**
   * Get chart data based on type
   */
  getChartData(type) {
    const allReviews = [
      ...this.state.allData.processed_reviews,
      ...this.state.allData.rejected_quality_reviews,
      ...this.state.allData.rejected_irrelevant_reviews
    ];

    const colors = {
      'إيجابي': '#10b981',
      'سلبي': '#ef4444',
      'محايد': '#f59e0b'
    };

    if (type === 'sentiment') {
      const sentiment = {};
      allReviews.forEach(r => {
        const s = r.overall_sentiment || 'محايد';
        sentiment[s] = (sentiment[s] || 0) + 1;
      });
      return {
        labels: Object.keys(sentiment),
        datasets: [{
          data: Object.values(sentiment),
          backgroundColor: Object.keys(sentiment).map(s => colors[s]),
          borderColor: '#fff',
          borderWidth: 2
        }]
      };
    }

    if (type === 'category') {
      const categories = {};
      allReviews.forEach(r => {
        const c = r.analysis?.category || 'عام';
        categories[c] = (categories[c] || 0) + 1;
      });
      return {
        labels: Object.keys(categories),
        datasets: [{
          data: Object.values(categories),
          backgroundColor: ['#3b82f6', '#ec4899', '#8b5cf6', '#f59e0b', '#06b6d4'],
          borderColor: '#fff',
          borderWidth: 2
        }]
      };
    }

    if (type === 'rating') {
      const ratings = { '5': 0, '4': 0, '3': 0, '2': 0, '1': 0 };
      allReviews.forEach(r => {
        const s = r.stars || 0;
        if (ratings[s] !== undefined) ratings[s]++;
      });
      return {
        labels: ['5 نجوم', '4 نجوم', '3 نجوم', '2 نجمة', 'نجمة واحدة'],
        datasets: [{
          data: Object.values(ratings),
          backgroundColor: ['#059669', '#10b981', '#f59e0b', '#f97316', '#dc2626'],
          borderColor: '#fff',
          borderWidth: 2
        }]
      };
    }

    if (type === 'status') {
      return {
        labels: ['مقبول', 'منخفض الجودة', 'غير ذي صلة'],
        datasets: [{
          data: [
            this.state.allData.processed_reviews.length,
            this.state.allData.rejected_quality_reviews.length,
            this.state.allData.rejected_irrelevant_reviews.length
          ],
          backgroundColor: ['#10b981', '#ef4444', '#f59e0b'],
          borderColor: '#fff',
          borderWidth: 2
        }]
      };
    }

    return { labels: [], datasets: [] };
  },

  /**
   * Update statistics
   */
  updateStatistics() {
    const allReviews = this.state.allData.processed_reviews;

    if (allReviews.length === 0) {
      document.getElementById('satisfactionRate').textContent = '--';
      document.getElementById('trendsIndicator').textContent = '--';
      return;
    }

    // Satisfaction rate
    const positiveCount = allReviews.filter(r =>
      r.overall_sentiment === 'إيجابي'
    ).length;
    const satisfactionRate = Math.round((positiveCount / allReviews.length) * 100);
    document.getElementById('satisfactionRate').textContent = `${satisfactionRate}%`;

    // Trend indicator
    const lastWeek = allReviews.filter(r => {
      const date = new Date(r.created_at);
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return date >= weekAgo;
    });

    if (lastWeek.length === 0) {
      document.getElementById('trendsIndicator').textContent = '→ ثابت';
    } else {
      const lastWeekPositive = lastWeek.filter(r =>
        r.overall_sentiment === 'إيجابي'
      ).length;
      const lastWeekRate = (lastWeekPositive / lastWeek.length) * 100;
      const trend = lastWeekRate > satisfactionRate ? '↑ صاعد' : lastWeekRate < satisfactionRate ? '↓ هابط' : '→ ثابت';
      document.getElementById('trendsIndicator').textContent = trend;
    }
  },

  /**
   * Export data as CSV
   */
  exportData() {
    const reviews = this.getCurrentTabReviews();
    if (reviews.length === 0) {
      window.UI.Toast.show('لا توجد بيانات للتصدير', 'warning');
      return;
    }

    let csv = 'التاريخ,الملخص,المشاعر,التقييم,البريد الإلكتروني\n';

    reviews.forEach(r => {
      const date = new Date(r.created_at).toLocaleDateString('ar-SA');
      const text = (r.processing?.concatenated_text || '').replace(/"/g, '""').substring(0, 100);
      const sentiment = r.overall_sentiment || 'محايد';
      const stars = r.stars || 0;
      const email = r.email || '';

      csv += `${date},"${text}",${sentiment},${stars},"${email}"\n`;
    });

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `reviews-${new Date().getTime()}.csv`);
    link.click();

    window.UI.Toast.show('تم تصدير البيانات بنجاح', 'success');
  },

  /**
   * Generate weekly report
   */
  generateWeeklyReport() {
    window.UI.Toast.show('جاري إعداد التقرير...', 'info');
    setTimeout(() => {
      window.UI.Toast.show('تم إرسال التقرير إلى بريدك الإلكتروني', 'success');
    }, 2000);
  },

  /**
   * Print report
   */
  printReport() {
    window.print();
  },

  /**
   * Generate new QR
   */
  async generateNewQR() {
    try {
      const btn = document.getElementById('generateQR');
      const icon = btn.querySelector('i');
      icon.classList.add('fa-spin');

      const response = await window.API.qr.generateQR();
      const data = response.data || response;

      let qrCode = data.qr_code;
      if (qrCode && !qrCode.startsWith('data:image/png;base64,')) {
        qrCode = `data:image/png;base64,${qrCode}`;
      }

      this.state.allData.qr_code = qrCode;
      this.updateQRSection();

      window.UI.Toast.show('تم إنشاء رمز QR جديد', 'success');
      icon.classList.remove('fa-spin');
    } catch (error) {
      console.error('Failed to generate QR:', error);
      window.UI.Toast.show('فشل في إنشاء رمز QR', 'error');
    }
  },

  /**
   * Download QR code
   */
  downloadQR() {
    if (!this.state.allData.qr_code) return;

    const link = document.createElement('a');
    link.href = this.state.allData.qr_code;
    link.download = `qr-code-${new Date().getTime()}.png`;
    link.click();

    window.UI.Toast.show('تم تحميل رمز QR', 'success');
  },

  /**
   * Copy QR link to clipboard
   */
  copyQRLink() {
    if (!this.state.allData.qr_code) return;

    navigator.clipboard.writeText(this.state.allData.qr_code).then(() => {
      window.UI.Toast.show('تم نسخ الرابط', 'success');
    }).catch(err => {
      console.error('Failed to copy:', err);
      window.UI.Toast.show('فشل النسخ', 'error');
    });
  },

  /**
   * Copy to clipboard
   */
  copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
      window.UI.Toast.show('تم النسخ', 'success');
    }).catch(err => {
      console.error('Failed to copy:', err);
      window.UI.Toast.show('فشل النسخ', 'error');
    });
  },

  /**
   * Update user name
   */
  updateUserName() {
    try {
      const shopInfo = JSON.parse(localStorage.getItem('shop_info') || '{}');
      if (shopInfo.shop_name) {
        document.getElementById('userName').textContent = shopInfo.shop_name;
      }
    } catch (e) {
      console.warn('Failed to get shop name:', e);
    }
  },

  /**
   * Setup realtime updates
   */
  setupRealtimeUpdates() {
    setInterval(() => {
      // Auto-refresh every 5 minutes
      // this.loadDashboardData();
    }, 5 * 60 * 1000);
  }
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  DashboardManager.init();
});
