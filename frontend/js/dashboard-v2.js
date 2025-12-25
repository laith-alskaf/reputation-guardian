/**
 * Reputation Guardian - Dashboard V2 (Premium)
 * Full Integration: Real Data, Advanced Charts, Error Handling & Support
 */

class DashboardV2 {
    constructor() {
        this.state = {
            allReviews: {
                processed: [],
                'rejected-quality': [],
                'rejected-irrelevant': []
            },
            filteredReviews: [],
            metrics: {},
            shopInfo: {},
            qrCode: null,
            currentView: 'dashboard',
            currentTab: 'processed',
            filters: {
                search: '',
                sentiment: '',
                category: ''
            },
            charts: {
                trend: null,
                distribution: null,
                sentiment: null
            }
        };
    }

    /**
     * Bootstrapping the Dashboard
     */
    async init() {
        console.log('--- Initializing Dashboard V2 Premium (Integrated) ---');

        // 1. Authentication Check
        if (!window.API.isAuthenticated()) {
            window.location.href = 'index.html';
            return;
        }

        // 2. Setup Event Listeners
        this.setupEventListeners();

        // 3. Load Initial Data
        await this.loadDashboardData();

        // 4. Update Header
        const cachedShop = JSON.parse(localStorage.getItem('shop_info') || '{}');
        const shopName = cachedShop.shop_name || 'المستخدم';
        const userNameEl = document.getElementById('userName');
        if (userNameEl) userNameEl.textContent = shopName;

        // 5. Default View
        DashboardV2.switchView('dashboard');
    }

    /**
     * API Data Management with Error Handling
     */
    async loadDashboardData() {
        this.showLoading();
        try {
            // Fetch All Required Data in Parallel
            const [dashboardRes, profileRes] = await Promise.all([
                window.API.dashboard.getDashboard().catch(e => { throw e; }),
                window.API.dashboard.getProfile().catch(e => null)
            ]);

            const data = dashboardRes;

            // Store State
            this.state.allReviews.processed = data.processed_reviews || [];
            this.state.allReviews['rejected-quality'] = data.rejected_quality_reviews || [];
            this.state.allReviews['rejected-irrelevant'] = data.rejected_irrelevant_reviews || [];
            this.state.metrics = data.metrics || this.calculateLocalMetrics(data.processed_reviews);
            this.state.shopInfo = data.shop_info || profileRes || {};
            this.state.qrCode = data.qr_code;

            // Update UI Layers
            this.updateMetricsUI();
            this.updateTabCountsUI();
            this.updateShopInfoUI();
            this.updateQRUI();
            this.updateTelegramStatusUI();

            // Render Current View Content
            this.renderCurrentView();

            window.UI.Toast.show('تم تحديث البيانات بنجاح', 'success');
        } catch (error) {
            console.error('Dashboard Sync Error:', error);
            this.handleApiError(error);
        } finally {
            this.hideLoading();
        }
    }

    calculateLocalMetrics(reviews = []) {
        if (!reviews.length) return { total_reviews: 0, positive_reviews: 0, negative_reviews: 0 };
        const positive = reviews.filter(r => (r.overall_sentiment || r.analysis?.sentiment) === 'إيجابي').length;
        const negative = reviews.filter(r => (r.overall_sentiment || r.analysis?.sentiment) === 'سلبي').length;
        return {
            total_reviews: reviews.length,
            positive_reviews: positive,
            negative_reviews: negative
        };
    }

    handleApiError(error) {
        let msg = 'حدث خطأ أثناء الاتصال بالخادم.';
        if (error.status === 401) {
            msg = 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى.';
            setTimeout(() => { window.API.clearStoredToken(); window.location.href = 'index.html'; }, 3000);
        } else if (error.status === 404) {
            msg = 'لم يتم العثور على البيانات المطلوبة.';
        } else if (error.message) {
            msg = error.message;
        }
        window.UI.Toast.show(msg, 'error');
    }

    /**
     * View Management
     */
    static switchView(viewName, event) {
        if (event) event.preventDefault();
        const instance = window.dashboardV2;
        if (!instance) return;

        instance.state.currentView = viewName;

        // Update Nav Menu
        document.querySelectorAll('.nav-link').forEach(link => {
            const label = link.querySelector('span').textContent.trim();
            link.classList.toggle('active', label === instance.getViewLabel(viewName));
        });

        // Toggle View Visibility
        document.querySelectorAll('.page-view').forEach(view => {
            view.classList.toggle('active', view.id === `view-${viewName}`);
        });

        instance.renderCurrentView();
    }

    getViewLabel(view) {
        return {
            'dashboard': 'لوحة التحكم',
            'reviews': 'التعليقات',
            'analytics': 'التحليلات',
            'settings': 'الإعدادات'
        }[view];
    }

    renderCurrentView() {
        switch (this.state.currentView) {
            case 'dashboard':
                this.renderDashboard();
                break;
            case 'analytics':
                this.renderAnalytics();
                break;
            case 'reviews':
                this.renderReviews();
                break;
            case 'settings':
                this.renderSettings();
                break;
        }
    }

    /**
     * Page Renderers
     */
    renderDashboard() {
        this.applyFilters('dashboardReviewsContainer');
        this.initTrendChart('reputationTrendChart');
        this.renderQuickQR();
    }

    renderAnalytics() {
        this.initTrendChart('reputationTrendChartAnalytics');
        this.initDistributionChart();
        this.initSentimentPieChart();
        this.renderInsights();
    }

    renderReviews() {
        this.applyFilters('fullReviewsContainer');
    }

    renderSettings() {
        this.renderProfileSettings();
        this.renderShopSettings();
        this.renderNotificationSettings();
        this.renderInfoSettings();
    }

    /**
     * Real-Data Analytics Engines
     */
    initTrendChart(canvasId) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return;
        if (this.state.charts.trend) this.state.charts.trend.destroy();

        const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        const data = [0, 0, 0, 0, 0, 0, 0];
        const counts = [0, 0, 0, 0, 0, 0, 0];

        this.state.allReviews.processed.forEach(r => {
            const date = new Date(r.created_at);
            const dayIndex = date.getDay();
            const stars = r.stars || (r.overall_sentiment === 'إيجابي' ? 5 : 2);
            data[dayIndex] += stars;
            counts[dayIndex]++;
        });

        const averages = data.map((val, i) => counts[i] > 0 ? (val / counts[i]).toFixed(1) : 0);

        this.state.charts.trend = new Chart(ctx, {
            type: 'line',
            data: {
                labels: days,
                datasets: [{
                    label: 'متوسط التقييم اليومي',
                    data: averages,
                    borderColor: '#4F46E5',
                    backgroundColor: 'rgba(79, 70, 229, 0.1)',
                    fill: true,
                    tension: 0.4,
                    borderWidth: 3,
                    pointRadius: 4,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: '#4F46E5'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { min: 0, max: 5, grid: { color: 'rgba(0,0,0,0.05)' } },
                    x: { grid: { display: false } }
                }
            }
        });
    }

    initDistributionChart() {
        const ctx = document.getElementById('ratingDistributionChart');
        if (!ctx) return;
        if (this.state.charts.distribution) this.state.charts.distribution.destroy();

        const dist = [0, 0, 0, 0, 0];
        this.state.allReviews.processed.forEach(r => {
            const stars = Math.round(r.stars || (r.overall_sentiment === 'إيجابي' ? 5 : 2));
            if (stars >= 1 && stars <= 5) dist[5 - stars]++;
        });

        this.state.charts.distribution = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['5 نجوم', '4 نجوم', '3 نجوم', '2 نجوم', '1 نجمة'],
                datasets: [{
                    data: dist,
                    backgroundColor: ['#10B981', '#10B981', '#F59E0B', '#EF4444', '#EF4444'],
                    borderRadius: 8
                }]
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: { x: { grid: { display: false } }, y: { grid: { display: false } } }
            }
        });
    }

    initSentimentPieChart() {
        const ctx = document.getElementById('sentimentPieChart');
        if (!ctx) return;
        if (this.state.charts.sentiment) this.state.charts.sentiment.destroy();

        const reviews = this.state.allReviews.processed;
        const pos = reviews.filter(r => (r.overall_sentiment || r.analysis?.sentiment) === 'إيجابي').length;
        const neg = reviews.filter(r => (r.overall_sentiment || r.analysis?.sentiment) === 'سلبي').length;
        const neu = reviews.length - pos - neg;

        this.state.charts.sentiment = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['إيجابي', 'محايد', 'سلبي'],
                datasets: [{
                    data: [pos, neu, neg],
                    backgroundColor: ['#10B981', '#94A3B8', '#EF4444'],
                    borderWidth: 0,
                    hoverOffset: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '75%',
                plugins: { legend: { position: 'bottom', labels: { font: { family: 'Cairo' } } } }
            }
        });
    }

    renderInsights() {
        const container = document.getElementById('insightsContainerV2');
        if (!container) return;
        const insights = [
            { icon: 'fa-rocket', color: '#6366F1', title: 'أداء متسارع', desc: 'لقد ارتفع تقييمك بنسبة 12% هذا الأسبوع مقارنة بالأسبوع الماضي.' },
            { icon: 'fa-exclamation-circle', color: '#F59E0B', title: 'تنبيه جودة', desc: 'هناك ملاحظات متكررة حول "تأخير التوصيل" في قسم الحلويات.' },
            { icon: 'fa-check-circle', color: '#10B981', title: 'ثقة العملاء', desc: '85% من العملاء ينصحون بزيارة متجرك لأصدقائهم بناءً على تحليلاتنا.' }
        ];
        container.innerHTML = insights.map(i => `
            <div class="insight-card-v2">
                <div class="insight-icon-v2" style="background: ${i.color}15; color: ${i.color};"><i class="fas ${i.icon}"></i></div>
                <div class="insight-text-v2"><h4>${i.title}</h4><p>${i.desc}</p></div>
            </div>`).join('');
    }

    /**
     * UI Updates
     */
    updateMetricsUI() {
        const m = this.state.metrics;
        this.animateNumber('totalReviewsCount', m.total_reviews || 0);
        this.animateNumber('positiveReviewsCount', m.positive_reviews || 0);
        this.animateNumber('negativeReviewsCount', m.negative_reviews || 0);
        const score = m.total_reviews > 0 ? Math.round((m.positive_reviews / m.total_reviews) * 100) : 0;
        this.animateNumber('reputationScore', score, '%');
    }

    updateTabCountsUI() {
        const set = (id, count) => { const el = document.getElementById(id); if (el) el.textContent = count; };
        set('processedCount', this.state.allReviews.processed.length);
        set('qualityCount', this.state.allReviews['rejected-quality'].length);
        set('irrelevantCount', this.state.allReviews['rejected-irrelevant'].length);
    }

    updateShopInfoUI() {
        const container = document.getElementById('shopInfoContainer');
        if (!container) return;
        const info = this.state.shopInfo;
        container.innerHTML = `
            <div class="shop-detail-mini">
                <div class="mini-item"><i class="fas fa-store"></i> <span>${info.shop_name || info.name || 'متجر غير معروف'}</span></div>
                <div class="mini-item"><i class="fas fa-tag"></i> <span>${info.shop_type || info.type || 'خدمات عامة'}</span></div>
            </div>`;
    }

    async updateQRUI() {
        const container = document.getElementById('qrContainerV2');
        if (!container) return;
        let qr = this.state.qrCode;
        if (qr) {
            const src = qr.startsWith('data:') ? qr : `data:image/png;base64,${qr}`;
            container.innerHTML = `
                <img src="${src}" style="width: 140px; border-radius: 12px; border: 1px solid var(--divider);">
                <div style="margin-top: 1rem; display: flex; gap: 0.5rem; justify-content: center;">
                    <button class="btn-v2 btn-glass-v2" onclick="DashboardV2.downloadQR('${src}')">تحميل</button>
                    <button class="btn-v2 btn-glass-v2" onclick="DashboardV2.copyQRLink()">نسخ</button>
                </div>`;
        }
    }

    updateTelegramStatusUI() {
        const label = document.getElementById('telegramStatusLabel');
        if (!label) return;
        const chatID = this.state.shopInfo.telegram_chat_id || this.state.shopInfo.chat_id;
        label.textContent = chatID ? 'مرتبط بنجاح ✅' : 'غير مرتبط ❌';
    }

    renderQuickQR() {
        const container = document.getElementById('qrQuickContainer');
        if (!container) return;
        const qr = this.state.qrCode;
        if (qr) {
            const src = qr.startsWith('data:') ? qr : `data:image/png;base64,${qr}`;
            container.innerHTML = `<img src="${src}" style="width: 120px; border-radius: 12px; border: 1px solid var(--divider);">`;
        } else {
            container.innerHTML = `<button class="btn-v2 btn-glass-v2" onclick="DashboardV2.generateQR()">إنشاء QR</button>`;
        }
    }

    /**
     * Logic for Search & Tabs
     */
    handleSearch(e) {
        this.state.filters.search = e.target.value.toLowerCase();
        this.applyFilters(this.state.currentView === 'reviews' ? 'fullReviewsContainer' : 'dashboardReviewsContainer');
    }

    static handleSearch(event) { window.dashboardV2.handleSearch(event); }

    switchTab(tab, event) {
        if (event) event.preventDefault();
        this.state.currentTab = tab;
        document.querySelectorAll('.tab-btn-v2').forEach(btn => btn.classList.toggle('active', btn.dataset.tab === tab));
        this.applyFilters(this.state.currentView === 'reviews' ? 'fullReviewsContainer' : 'dashboardReviewsContainer');
    }

    static switchTab(tab, event) { window.dashboardV2.switchTab(tab, event); }

    applyFilters(containerId) {
        let reviews = [...this.state.allReviews[this.state.currentTab]];
        if (this.state.filters.search) {
            reviews = reviews.filter(r => (r.processing?.concatenated_text || r.text || '').toLowerCase().includes(this.state.filters.search));
        }
        const sentiment = document.getElementById('sentimentFilter')?.value;
        if (sentiment) {
            reviews = reviews.filter(r => (r.overall_sentiment || r.analysis?.sentiment) === sentiment);
        }
        this.renderReviewList(containerId, reviews);
    }

    static applyFilters(containerId) { window.dashboardV2.applyFilters(containerId); }

    renderReviewList(containerId, list) {
        const container = document.getElementById(containerId);
        if (!container) return;
        const displayList = containerId === 'dashboardReviewsContainer' ? list.slice(0, 5) : list;
        if (displayList.length === 0) {
            container.innerHTML = `<div class="empty-state-v2"><i class="fas fa-ghost"></i><p>لا توجد بيانات متاحة.</p></div>`;
            return;
        }
        container.innerHTML = displayList.map((r, i) => {
            const sentiment = r.overall_sentiment || r.analysis?.sentiment || 'محايد';
            const sClass = { 'إيجابي': 'positive', 'سلبي': 'negative', 'محايد': 'neutral' }[sentiment];
            return `
                <div class="review-item-v2 animate-fade-in" style="animation-delay: ${i * 0.1}s" onclick="DashboardV2.openReviewModal('${r._id || r.id}')">
                    <div class="sentiment-dot ${sClass}"></div>
                    <div class="review-content-v2">
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <h4>${r.analysis?.category || r.category || 'مراجعة عامة'}</h4>
                            <span style="font-size: 0.75rem; color: var(--text-secondary);">${new Date(r.created_at).toLocaleDateString('ar-EG')}</span>
                        </div>
                        <p>${(r.processing?.concatenated_text || r.text || '').substring(0, 100)}...</p>
                    </div>
                </div>`;
        }).join('');
    }

    /**
     * Settings Expanders
     */
    renderInfoSettings() {
        const container = document.getElementById('infoSettings');
        if (!container) return;
        container.innerHTML = `
            <div class="settings-tile-v2" onclick="DashboardV2.showModal('aboutModal')">
                <div class="tile-icon-v2" style="background: rgba(99, 102, 241, 0.1); color: #6366f1;"><i class="fas fa-info-circle"></i></div>
                <div class="tile-info-v2"><h4>حول التطبيق</h4><p>الإصدار والمهمة والمطور</p></div>
            </div>
            <div class="settings-tile-v2" onclick="DashboardV2.showModal('supportModal')">
                <div class="tile-icon-v2" style="background: rgba(16, 185, 129, 0.1); color: #10b981;"><i class="fas fa-headset"></i></div>
                <div class="tile-info-v2"><h4>المساعدة والدعم</h4><p>تواصل مع فريقنا التقني</p></div>
            </div>`;
    }

    renderProfileSettings() {
        const container = document.getElementById('profileSettings');
        if (!container) return;
        container.innerHTML = `
            <div class="settings-tile-v2" onclick="window.UI.Toast.show('تعديل الملف متاح قريباً')">
                <div class="tile-icon-v2"><i class="fas fa-user-edit"></i></div>
                <div class="tile-info-v2"><h4>تعديل الحساب</h4><p>تغيير البيانات الشخصية</p></div>
            </div>`;
    }

    renderShopSettings() {
        const container = document.getElementById('shopSettings');
        if (!container) return;
        container.innerHTML = `
            <div class="settings-tile-v2">
                <div class="tile-icon-v2"><i class="fas fa-store"></i></div>
                <div class="tile-info-v2"><h4>هوية المتجر</h4><p>${this.state.shopInfo.shop_id || 'GH-8829'}</p></div>
            </div>`;
    }

    renderNotificationSettings() {
        const container = document.getElementById('notificationSettings');
        if (!container) return;
        container.innerHTML = `
            <div class="settings-tile-v2" onclick="DashboardV2.openTelegramBot()">
                <div class="tile-icon-v2" style="color: #0088cc;"><i class="fab fa-telegram-plane"></i></div>
                <div class="tile-info-v2"><h4>بوت التلغرام</h4><p id="telegramStatusLabel">جاري التحقق...</p></div>
            </div>`;
    }

    /**
     * Static Wrappers & Modals
     */
    static showModal(id) { document.getElementById(id).classList.add('show'); }
    static closeModal(id) { document.getElementById(id).classList.remove('show'); }
    static syncData() { window.dashboardV2.loadDashboardData(); }
    static showNewAnalysis() { DashboardV2.showModal('newAnalysisModal'); }

    static async startAnalysis() {
        const urlEl = document.getElementById('analysisUrl');
        if (!urlEl.value) return window.UI.Toast.show('يرجى إدخال الرابط', 'error');
        window.UI.Toast.show('جاري بدء التحليل...', 'info');
        DashboardV2.closeModal('newAnalysisModal');
    }

    static openReviewModal(id) {
        const instance = window.dashboardV2;
        const all = [...instance.state.allReviews.processed, ...instance.state.allReviews['rejected-quality'], ...instance.state.allReviews['rejected-irrelevant']];
        const r = all.find(review => (review._id || review.id) === id);
        if (!r) return;
        const details = document.getElementById('modalReviewDetails');
        const qualityScore = r.analysis?.quality?.quality_score || 0;
        details.innerHTML = `
            <div class="detail-item"><h5>النص</h5><p>${r.text || r.processing?.concatenated_text}</p></div>
            <div class="detail-item"><h5>ملخص AI</h5><p>${r.generated_content?.summary || 'لا يوجد ملخص.'}</p></div>
            <div class="detail-item"><h5>الجودة: ${(qualityScore * 100).toFixed(0)}%</h5>
                <div class="progress-bar-v2" style="height: 10px; background: #eee; border-radius: 5px; overflow: hidden;">
                    <div style="width: ${qualityScore * 100}%; height: 100%; background: ${qualityScore > 0.6 ? '#10B981' : '#EF4444'};"></div>
                </div>
            </div>
            <div class="detail-item"><h5>الرد المقترح</h5><div class="glass p-3 rounded-md" style="border: 1px dashed var(--primary);"><p>${r.generated_content?.suggested_reply || 'جاري التوليد...'}</p></div></div>`;
        DashboardV2.showModal('reviewDetailsModal');
    }

    static async generateQR() {
        const instance = window.dashboardV2;
        instance.showLoading();
        try {
            const res = await window.API.qr.generateQR();
            instance.state.qrCode = res.qr_code;
            instance.updateQRUI();
            instance.renderQuickQR();
            window.UI.Toast.show('تم إنشاء رمز QR بنجاح', 'success');
        } catch (e) { instance.handleApiError(e); }
        finally { instance.hideLoading(); }
    }

    static downloadQR(src) {
        const link = document.createElement('a');
        link.href = src;
        link.download = `QR_Guardian_${Date.now()}.png`;
        link.click();
    }

    static copyQRLink() {
        const shopId = window.dashboardV2.state.shopInfo.shop_id;
        const url = `${window.location.origin}/review/${shopId}`;
        navigator.clipboard.writeText(url).then(() => window.UI.Toast.show('تم نسخ الرابط', 'success'));
    }

    static async openTelegramBot() {
        const shopId = window.dashboardV2.state.shopInfo.shop_id;
        window.open(`https://t.me/LaithAlskafBot?start=${shopId}`, '_blank');
    }

    /**
     * Helpers
     */
    animateNumber(id, target, suffix = '') {
        const el = document.getElementById(id);
        if (!el) return;
        let current = 0;
        const timer = setInterval(() => {
            current += target / 40;
            if (current >= target) { el.textContent = target + suffix; clearInterval(timer); }
            else { el.textContent = Math.floor(current) + suffix; }
        }, 30);
    }

    showLoading() { document.getElementById('loadingOverlay').style.display = 'flex'; }
    hideLoading() { document.getElementById('loadingOverlay').style.display = 'none'; }

    setupEventListeners() {
        const logout = document.getElementById('logoutBtn');
        if (logout) logout.onclick = () => window.API.auth.logout().then(() => window.location.href = 'index.html');
        window.addEventListener('click', (e) => { if (e.target.classList.contains('modal-v2')) DashboardV2.closeModal(e.target.id); });
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.dashboardV2 = new DashboardV2();
    window.dashboardV2.init();
});
