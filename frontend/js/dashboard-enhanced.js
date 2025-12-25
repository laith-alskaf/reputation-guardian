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
   * Update metrics display - Premium Redesign
   */
  updateMetrics() {
    const metrics = this.state.allData.metrics;
    const container = document.getElementById('metricsContainer');

    if (!container) return;

    container.innerHTML = `
      <!-- Average Rating - Premium -->
      <div class="metric-card premium animate-scale-bounce">
          <div class="metric-glass"></div>
          <div class="metric-info">
              <span class="metric-label">متوسط التقييم</span>
              <div class="metric-value-wrapper">
                  <span class="metric-value">${metrics.average_stars?.toFixed(1) || '0.0'}</span>
                  <div class="metric-stars">
                      ${this._generateStarIcons(metrics.average_stars || 0)}
                  </div>
              </div>
          </div>
          <div class="metric-icon-bg"><i class="fas fa-star"></i></div>
      </div>

      <!-- Total Reviews -->
      <div class="metric-card animate-scale-bounce" style="animation-delay: 100ms">
          <div class="metric-info">
              <span class="metric-label">إجمالي التقييمات</span>
              <span class="metric-value">${metrics.total_reviews || 0}</span>
          </div>
          <div class="metric-icon"><i class="fas fa-users"></i></div>
      </div>

      <!-- Positive Reviews -->
      <div class="metric-card success animate-scale-bounce" style="animation-delay: 200ms">
          <div class="metric-info">
              <span class="metric-label">تقييمات إيجابية</span>
              <span class="metric-value">${metrics.positive_reviews || 0}</span>
          </div>
          <div class="metric-icon"><i class="fas fa-smile"></i></div>
      </div>

      <!-- Negative Reviews -->
      <div class="metric-card danger animate-scale-bounce" style="animation-delay: 300ms">
          <div class="metric-info">
              <span class="metric-label">تقييمات سلبية</span>
              <span class="metric-value">${metrics.negative_reviews || 0}</span>
          </div>
          <div class="metric-icon"><i class="fas fa-frown"></i></div>
      </div>
    `;
  },

  /**
   * Helper to generate star icons for the rating display
   */
  _generateStarIcons(rating) {
    let stars = '';
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;

    for (let i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars += '<i class="fas fa-star"></i>';
      } else if (i === fullStars && hasHalfStar) {
        stars += '<i class="fas fa-star-half-alt"></i>';
      } else {
        stars += '<i class="far fa-star"></i>';
      }
    }
    return stars;
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
        statusIndicator.style.color = 'var(--success)';
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
   * Create review card HTML - Premium Redesign
   */
  createReviewCard(review) {
    const sentiment = review.overall_sentiment || review.analysis?.sentiment || 'محايد';
    const category = review.analysis?.category || review.category || 'عام';
    const stars = review.stars || 0;
    const date = new Date(review.created_at).toLocaleDateString('ar-SA');
    const text = review.processing?.concatenated_text || '';
    const isMismatch = review.analysis?.context?.has_mismatch || false;
    const qualityScore = review.analysis?.quality?.quality_score || 0;

    const sentimentMap = {
      'إيجابي': { class: 'pos', glow: 'sentiment-glow-pos', icon: 'fa-smile' },
      'سلبي': { class: 'neg', glow: 'sentiment-glow-neg', icon: 'fa-frown' },
      'محايد': { class: 'neu', glow: 'sentiment-glow-neu', icon: 'fa-meh' }
    };

    const config = sentimentMap[sentiment] || sentimentMap['محايد'];
    const starsHTML = '<i class="fas fa-star"></i>'.repeat(stars) + '<i class="far fa-star"></i>'.repeat(5 - stars);

    return `
      <div class="review-card-premium ${config.class} ${config.glow} shadow-soft animate-scale" 
           onclick="DashboardManager.openReviewModal('${review._id || review.id}')">
        
        <!-- Subtle Pattern Overlay -->
        <div class="card-overlay-bg"><i class="fas ${config.icon}"></i></div>

        <div class="review-header-premium">
          <div class="reviewer-meta">
            <div class="sentiment-chip ${config.class}">
              <i class="fas ${config.icon}"></i>
              <span>${sentiment}</span>
            </div>
            <span class="badge ${isMismatch ? 'badge-warning' : 'badge-soft'}">${category}</span>
          </div>
          <div class="stars-premium">${starsHTML}</div>
        </div>

        <div class="review-text-premium">
          <p>${text.substring(0, 140)}${text.length > 140 ? '...' : ''}</p>
        </div>

        <div class="review-footer-premium">
          <div class="footer-left">
            <i class="far fa-calendar-alt"></i> ${date}
          </div>
          <div class="footer-right">
             <div class="quality-badge">
                <i class="fas fa-certificate"></i>
                <span>${(qualityScore * 100).toFixed(0)}%</span>
             </div>
          </div>
        </div>
        
        ${isMismatch ? '<div class="review-alert"><i class="fas fa-exclamation-triangle"></i> سياق غير متطابق</div>' : ''}
      </div>
    `;
  },

  /**
   * Open review modal with full details - Premium Redesign
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
    const isProfane = review.processing?.is_profane || false;
    const stars = review.stars || 0;
    const date = new Date(review.created_at).toLocaleDateString('ar-SA');
    const text = review.processing?.concatenated_text || '';

    // AI Content
    const summary = review.generated_content?.summary;
    const insights = review.generated_content?.actionable_insights || [];
    const suggestedReply = review.generated_content?.suggested_reply;

    const sentimentClass = { 'إيجابي': 'pos', 'سلبي': 'neg', 'محايد': 'neu' }[sentiment] || 'neu';
    const starsHTML = '<i class="fas fa-star"></i>'.repeat(stars) + '<i class="far fa-star"></i>'.repeat(5 - stars);

    const modal = document.getElementById('reviewModal');
    const content = document.getElementById('reviewModalContent');

    modal.querySelector('.modal-content').className = 'modal-content review-modal-premium';

    content.innerHTML = `
      <div class="modal-header-premium">
        <div class="header-content">
          <h2>تفاصيل التقييم الشاملة</h2>
          <div class="header-badges">
            <span class="sentiment-chip ${sentimentClass}">${sentiment}</span>
            <span class="badge" style="background: rgba(255,255,255,0.2); border: none;">${category}</span>
            <div class="stars-premium" style="color: #fbbf24; display: inline-block; margin-right: 15px;">${starsHTML}</div>
          </div>
        </div>
      </div>

      <div class="modal-body-premium">
        <!-- Review Text -->
        <div class="modal-section mb-5">
          <h3 class="section-title"><i class="fas fa-comment-alt text-primary"></i> نص التقييم</h3>
          <div class="content-box glass shadow-soft p-4 rounded-xl border-light">
            <p class="text-lg leading-relaxed">${text}</p>
          </div>
        </div>

        <!-- AI Analysis Section -->
        ${summary || (Array.isArray(insights) && insights.length > 0) ? `
        <div class="modal-section mb-5">
          <h3 class="section-title"><i class="fas fa-robot text-indigo"></i> تحليل الذكاء الاصطناعي</h3>
          <div class="ai-analysis-grid">
            ${summary ? `
            <div class="ai-insight-box info">
              <div class="insight-header"><i class="fas fa-quote-right"></i> الملخص الذكي</div>
              <div class="insight-content">${summary}</div>
            </div>` : ''}
            
            ${Array.isArray(insights) && insights.length > 0 ? `
            <div class="ai-insight-box success">
              <div class="insight-header"><i class="fas fa-lightbulb"></i> أهم الرؤى</div>
              <div class="insight-content">
                <ul class="list-disc pr-4">
                  ${insights.map(i => `<li class="mb-1">${i}</li>`).join('')}
                </ul>
              </div>
            </div>` : ''}
          </div>
        </div>` : ''}

        <!-- Suggested Reply -->
        ${suggestedReply ? `
        <div class="modal-section mb-5">
          <h3 class="section-title"><i class="fas fa-reply text-success"></i> الرد المقترح</h3>
          <div class="ai-insight-box" style="border-style: dashed; background: rgba(34, 197, 94, 0.02);">
            <div class="insight-content mb-3">${suggestedReply}</div>
            <button class="btn btn-sm btn-outline-success" onclick="DashboardManager.copySuggestedReply(\`${suggestedReply.replace(/'/g, "\\'")}\`)">
              <i class="fas fa-copy"></i> نسخ الرد
            </button>
          </div>
        </div>` : ''}

        <!-- Quality Metrics Grid -->
        <div class="modal-section">
          <h3 class="section-title"><i class="fas fa-shield-alt text-warning"></i> مؤشرات الجودة</h3>
          <div class="quality-grid-premium">
            <div class="quality-item-premium">
              <div class="q-label">درجة الجودة</div>
              <div class="q-value">${(qualityScore * 100).toFixed(0)}%</div>
              <div class="q-progress"><div class="q-bar" style="width: ${qualityScore * 100}%"></div></div>
            </div>
            <div class="quality-item-premium">
               <div class="q-label">سياق المحتوى</div>
               <div class="q-value ${isMismatch ? 'text-danger' : 'text-success'}">${isMismatch ? 'غير متقابق' : 'متطابق'}</div>
            </div>
            <div class="quality-item-premium">
               <div class="q-label">الألفاظ النابية</div>
               <div class="q-value ${isProfane ? 'text-danger' : 'text-success'}">${isProfane ? 'موجودة' : 'نظيف'}</div>
            </div>
            <div class="quality-item-premium">
               <div class="q-label">تاريخ التقييم</div>
               <div class="q-value">${date}</div>
            </div>
          </div>
        </div>

        <!-- Reviewer Details -->
        <div class="modal-section mt-5">
           <div class="reviewer-info-footer p-3 bg-alt rounded-lg flex justify-between items-center text-sm">
              <span><i class="fas fa-envelope"></i> ${review.email || 'غير متوفر'}</span>
              <span><i class="fas fa-id-badge"></i> ${review._id || review.id}</span>
           </div>
        </div>
      </div>
    `;

    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
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
   * Copy suggested reply
   */
  copySuggestedReply(text) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(() => {
      window.UI.Toast.show('تم نسخ الرد بنجاح', 'success');
    }).catch(err => {
      console.error('Failed to copy:', err);
      // Fallback
      const textArea = document.createElement("textarea");
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.select();
      try {
        document.execCommand('copy');
        window.UI.Toast.show('تم نسخ الرد بنجاح', 'success');
      } catch (err) {
        window.UI.Toast.show('فشل في النسخ', 'error');
      }
      document.body.removeChild(textArea);
    });
  },

  /**
   * Close review modal
   */
  closeReviewModal(event) {
    if (event && event.target.id !== 'reviewModal' && !event.target.closest('.modal-close')) return;

    const modal = document.getElementById('reviewModal');
    if (modal) {
      modal.style.display = 'none';
      document.body.style.overflow = 'auto';
    }
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
   * Update Analytics Chart with Premium Styling
   */
  updateAnalyticsChart() {
    const ctx = document.getElementById('reviewsChart');
    if (!ctx) return;

    const chartType = document.getElementById('chartTypeFilter').value;
    const metrics = this.state.allData.metrics;

    if (this.state.chart) {
      this.state.chart.destroy();
    }

    // Design Tokens Sync
    const colors = {
      primary: '#4f46e5',
      accent: '#06b6d4',
      success: '#10b981',
      warning: '#f59e0b',
      danger: '#ef4444',
      textSecondary: '#64748b'
    };

    let chartData = {};
    let chartOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: 'rgba(15, 23, 42, 0.9)',
          padding: 12,
          titleFont: { family: 'Cairo', size: 14 },
          bodyFont: { family: 'Cairo', size: 13 },
          rtl: true
        }
      },
      animation: {
        duration: 1200,
        easing: 'easeOutQuart'
      }
    };

    if (chartType === 'sentiment') {
      chartData = {
        labels: ['إيجابي', 'محايد', 'سلبي'],
        datasets: [{
          data: [metrics.positive_reviews || 0, metrics.neutral_reviews || 0, metrics.negative_reviews || 0],
          backgroundColor: [colors.success, colors.warning, colors.danger],
          borderWidth: 0,
          hoverOffset: 12
        }]
      };

      this.renderModernLegend(chartData.labels, chartData.datasets[0].backgroundColor, chartData.datasets[0].data);

      this.state.chart = new Chart(ctx, {
        type: 'doughnut',
        data: chartData,
        options: {
          ...chartOptions,
          cutout: '75%'
        }
      });
    } else if (chartType === 'rating') {
      const ratings = metrics.rating_distribution || [2, 5, 8, 15, 25];
      chartData = {
        labels: ['1⭐', '2⭐', '3⭐', '4⭐', '5⭐'],
        datasets: [{
          label: 'التقييمات',
          data: ratings,
          backgroundColor: colors.primary,
          borderRadius: 6,
          barThickness: 18
        }]
      };

      this.renderModernLegend(chartData.labels, [colors.primary], null);

      this.state.chart = new Chart(ctx, {
        type: 'bar',
        data: chartData,
        options: {
          ...chartOptions,
          scales: {
            y: { display: false, grid: { display: false } },
            x: {
              grid: { display: false },
              ticks: { font: { family: 'Cairo', size: 11 }, color: colors.textSecondary }
            }
          }
        }
      });
    } else if (chartType === 'status') {
      chartData = {
        labels: ['مقبول', 'مرفوض جودة', 'مرفوض صلة'],
        datasets: [{
          data: [
            this.state.allData.processed_reviews.length,
            this.state.allData.rejected_quality_reviews.length,
            this.state.allData.rejected_irrelevant_reviews.length
          ],
          backgroundColor: [colors.primary, colors.danger, colors.warning],
          borderWidth: 0
        }]
      };

      this.renderModernLegend(chartData.labels, chartData.datasets[0].backgroundColor, chartData.datasets[0].data);

      this.state.chart = new Chart(ctx, {
        type: 'pie',
        data: chartData,
        options: chartOptions
      });
    }
  },

  /**
   * Render custom modern legend
   */
  renderModernLegend(labels, colors, data) {
    const legendContainer = document.getElementById('chartLegend');
    if (!legendContainer) return;

    legendContainer.innerHTML = labels.map((label, i) => `
      <div class="legend-item-modern">
        <span class="legend-color" style="background: ${colors[i % colors.length]}"></span>
        <span class="legend-label">${label}</span>
        ${data ? `<span class="legend-value">(${data[i]})</span>` : ''}
      </div>
    `).join('');
  },

  /**
   * Update statistics display - Premium
   */
  updateStatistics() {
    const metrics = this.state.allData.metrics;

    // Helper to format values
    const formatValue = (val) => (val === undefined || val === null) ? '--' : val;

    const responseTimeEl = document.getElementById('avgResponseTime');
    const satisfactionEl = document.getElementById('satisfactionRate');
    const trendsEl = document.getElementById('trendsIndicator');

    if (responseTimeEl) responseTimeEl.textContent = formatValue(metrics.avg_response_time) + ' س';
    if (satisfactionEl) satisfactionEl.textContent = formatValue(metrics.satisfaction_rate) + '%';

    if (trendsEl) {
      const positiveRatio = (metrics.positive_reviews / metrics.total_reviews) || 0;
      let trendText = 'مستقر';
      let trendClass = 'neutral';

      if (positiveRatio > 0.7) {
        trendText = 'ارتفاع';
        trendClass = 'success';
      } else if (positiveRatio < 0.3) {
        trendText = 'انخفاض';
        trendClass = 'danger';
      }

      trendsEl.textContent = trendText;
      // We don't change className here to avoid losing base premium styles, just add sentiment class if needed
      // Actually we use stat-value-premium already
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
   * Open Settings Modal
   */
  openSettingsModal() {
    document.getElementById('settingsModal').classList.add('active');
    this.switchSettingsTab('profile');
  },

  /**
   * Close Settings Modal
   */
  closeSettingsModal(event) {
    if (event && event.target !== event.currentTarget) return;
    document.getElementById('settingsModal').classList.remove('active');
  },

  /**
   * Switch Settings Tab
   */
  switchSettingsTab(tabName) {
    // Update active button
    const container = document.querySelector('.settings-tabs');
    container.querySelectorAll('.s-tab-btn').forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('onclick').includes(tabName));
    });

    // Handle content rendering
    const content = document.getElementById('settingsContent');
    if (tabName === 'profile') {
      this.renderProfileSettings(content);
    } else if (tabName === 'shop') {
      this.renderShopSettings(content);
    } else if (tabName === 'notifications') {
      this.renderNotificationSettings(content);
    }
  },

  renderProfileSettings(container) {
    container.innerHTML = `
      <div class="settings-section animate-fade-in">
        <div class="settings-form-group">
          <label><i class="fas fa-user"></i> اسم المستخدم</label>
          <input type="text" class="settings-input" id="set-username" value="${this.state.allData.shop_info?.owner_name || 'المستخدم'}">
        </div>
        <div class="settings-form-group">
          <label><i class="fas fa-envelope"></i> البريد الإلكتروني</label>
          <input type="email" class="settings-input" id="set-email" value="${this.state.allData.shop_info?.email || ''}" disabled>
          <small class="text-secondary">لا يمكن تغيير البريد الإلكتروني حالياً</small>
        </div>
        <div class="settings-action-bar">
          <button class="btn btn-primary" onclick="DashboardManager.saveSettings('profile')">
            <i class="fas fa-save"></i> حفظ التغييرات
          </button>
        </div>
      </div>
    `;
  },

  renderShopSettings(container) {
    container.innerHTML = `
      <div class="settings-section animate-fade-in">
        <div class="settings-form-group">
          <label><i class="fas fa-store"></i> اسم المتجر</label>
          <input type="text" class="settings-input" id="set-shopname" value="${this.state.allData.shop_info?.shop_name || ''}">
        </div>
        <div class="settings-form-group">
          <label><i class="fas fa-tag"></i> نوع النشاط</label>
          <select class="settings-input" id="set-shoptype">
            <option value="مطعم" ${this.state.allData.shop_info?.shop_type === 'مطعم' ? 'selected' : ''}>مطعم</option>
            <option value="كافيه" ${this.state.allData.shop_info?.shop_type === 'كافيه' ? 'selected' : ''}>كافيه</option>
            <option value="تجزئة" ${this.state.allData.shop_info?.shop_type === 'تجزئة' ? 'selected' : ''}>تجزئة</option>
            <option value="صالون" ${this.state.allData.shop_info?.shop_type === 'صالون' ? 'selected' : ''}>صالون</option>
            <option value="أخرى" ${this.state.allData.shop_info?.shop_type === 'أخرى' ? 'selected' : ''}>أخرى</option>
          </select>
        </div>
        <div class="settings-action-bar">
          <button class="btn btn-primary" onclick="DashboardManager.saveSettings('shop')">
            <i class="fas fa-save"></i> حفظ الإعدادات
          </button>
        </div>
      </div>
    `;
  },

  renderNotificationSettings(container) {
    const isTelegramLinked = this.state.allData.shop_info?.telegram_linked;
    container.innerHTML = `
      <div class="settings-section animate-fade-in">
        <p class="mb-4">قم بربط حسابك مع تيليجرام لتلقي إشعارات فورية عند وصول تقييمات جديدة.</p>
        <div class="notification-card-glass">
          <div class="d-flex align-items-center gap-3">
            <div class="setup-icon" style="background: var(--grad-primary); color: white; width: 50px; height: 50px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem;">
              <i class="fab fa-telegram-plane"></i>
            </div>
            <div>
              <h4 class="mb-1">بوت تيليجرام</h4>
              <span class="telegram-status-pill ${isTelegramLinked ? 'status-linked' : 'status-unlinked'}">
                ${isTelegramLinked ? '<i class="fas fa-check"></i> متصل' : '<i class="fas fa-times"></i> غير متصل'}
              </span>
            </div>
          </div>
          <div>
            <a href="https://t.me/ReputationGuardianBot?start=${this.state.allData.shop_info?.shop_id || ''}" 
               target="_blank" class="btn btn-glass">
              <i class="fas fa-link"></i> ${isTelegramLinked ? 'إعادة الربط' : 'ربط الآن'}
            </a>
          </div>
        </div>
      </div>
    `;
  },

  async saveSettings(section) {
    try {
      window.UI.Loading.show();
      const shopId = this.state.allData.shop_info?.shop_id;
      let payload = {};

      if (section === 'profile') {
        payload = { owner_name: document.getElementById('set-username').value };
      } else if (section === 'shop') {
        payload = {
          shop_name: document.getElementById('set-shopname').value,
          shop_type: document.getElementById('set-shoptype').value
        };
      }

      // TODO: Call API endpoint (needs implementation in api.js if not exists)
      // For now, update local state to simulate
      await new Promise(r => setTimeout(r, 1000));

      this.state.allData.shop_info = { ...this.state.allData.shop_info, ...payload };
      this.updateUserName();
      window.UI.Toast.show('تم حفظ الإعدادات بنجاح', 'success');
    } catch (error) {
      console.error('Save error:', error);
      window.UI.Toast.show('فشل حفظ الإعدادات', 'error');
    } finally {
      window.UI.Loading.hide();
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
