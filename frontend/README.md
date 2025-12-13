# 🎨 Reputation Guardian - Frontend

<div align="center">

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?logo=javascript&logoColor=black)
![Responsive](https://img.shields.io/badge/Responsive-Mobile%20First-success)

**Modern, Responsive Dashboard built with Vanilla JavaScript**

[العربية](#arabic-docs) | [English](#english)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [File Structure](#file-structure)
- [Components](#components)
- [Styling](#styling)
- [Development](#development)

---

## 🌟 Overview

The frontend is a **lightweight, responsive Single Page Application (SPA)** built with vanilla JavaScript. No frameworks, no build tools - just clean, modern web technologies optimized for performance and mobile devices.

### Key Highlights

- 📱 **Mobile-First Design** - Perfect on all screen sizes (375px - 1440px+)
- 🎨 **Modern UI/UX** - Glassmorphism, smooth animations, gradients
- ⚡ **Fast Performance** - No frameworks, minimal dependencies
- 🌐 **RTL Support** - Full Arabic language support
- ♿ **Accessible** - WCAG 2.1 compliant, reduced motion support
- 🎯 **Component-Based** - Modular, reusable code architecture

---

## ✨ Features

### 🏠 Landing Page (`index.html`)

- **Hero Section** with call-to-action
- **Features Showcase** with icons and animations
- **Contact Form** with validation
- **Responsive Navigation** with mobile hamburger menu
- **Smooth Scroll** navigation

### 📊 Dashboard (`dashboard.html`)

#### Metrics & Analytics
- **Real-time Metrics Cards**
  - Total reviews count
  - Average rating
  - Sentiment distribution
  - Quality indicators
- **Interactive Charts** (Chart.js)
  - Sentiment distribution pie chart
  - Category breakdown
  - Rating trends
  - Status overview

#### Review Management
- **Tabbed Interface**
  - Processed reviews
  - Low-quality rejections
  - Irrelevant reviews
- **Advanced Filtering**
  - By sentiment (positive/negative/neutral)
  - By category (complaint/suggestion/praise)
  - By rating (1-5 stars)
  - By date range
  - By quality score
  - Context match filtering
- **Search Functionality**
  - Real-time text search
  - Highlighted results
- **Pagination** for large datasets

#### Review Cards
- **Rich Information Display**
  - ⭐ Star ratings
  - 😊 Sentiment badges with emojis
  - 📊 Quality score percentage
  - ⚠️ Profanity warnings
  - 🏷️ Key themes tags
  - 🔴 Mismatch indicators
- **Expandable Content**
  - Original customer review
  - AI-generated summary
  - Actionable insights
  - Suggested customer reply
- **Copy Functionality** for replies

#### Additional Features
- **QR Code Display** with download
- **Export Options** (CSV/JSON)
- **Print-Friendly** reports
- **Telegram Integration** setup
- **Weekly Reports** generation

---

## 🏗️ Architecture

### Component-Based Structure

```
Frontend/
├── index.html              # Landing page
├── dashboard.html          # Main dashboard
│
├── css/
│   ├── style.css           # Main styles (65KB)
│   └── schema-enhancements.css  # New schema features (responsive)
│
└── js/
    ├── config.js           # API configuration
    ├── api.js              # API client (fetch wrapper)
    ├── ui.js               # UI utilities & helpers
    ├── auth.js             # Authentication logic
    ├── main.js             # Global initialization
    ├── dashboard.js        # Dashboard manager ⭐
    └── dashboard-enhanced.js  # Enhanced version (optional)
```

### Design Patterns

**Manager Pattern**:
```javascript
const DashboardManager = {
  currentTab: 'processed',
  currentFilters: {},
  
  init() { ... },
  loadDashboard() { ... },
  updateRecentReviews(reviews) { ... },
  normalizeReview(review) { ... },  // NEW - Schema compatibility
  applyFilters() { ... },
  exportData() { ... }
};
```

**Singleton Pattern** for global managers  
**Module Pattern** for encapsulation  
**Observer Pattern** for event handling  

---

## 🚀 Installation

### Option 1: Simple HTTP Server

```bash
cd frontend

# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000

# Node.js (if installed)
npx http-server -p 8000
```

Then open: `http://localhost:8000`

### Option 2: Direct File Access

Simply open `index.html` or `dashboard.html` in your browser.

⚠️ **Note**: Some features (like API calls) require CORS configuration if running from `file://` protocol.

### Option 3: Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

Configuration in `vercel.json`:
```json
{
  "cleanUrls": true,
  "trailingSlash": false,
  "rewrites": [
    {"source": "/(.*)", "destination": "/$1.html"}
  ]
}
```

---

## 📁 File Structure

```
frontend/
├── index.html                    # Landing page
├── dashboard.html                # Main dashboard
├── manifest.json                 # PWA manifest
├── vercel.json                   # Deployment config
│
├── css/
│   ├── style.css                 # Base styles (3550 lines)
│   │   ├── CSS Variables         # Colors, spacing, fonts
│   │   ├── Global Styles         # Typography, resets
│   │   ├── Components            # Buttons, cards, forms
│   │   ├── Dashboard Styles      # Metrics, reviews, charts
│   │   └── Responsive            # Media queries
│   │
│   └── schema-enhancements.css   # NEW (500+ lines)
│       ├── Key Themes Tags       # Pill-shaped tags
│       ├── Quality Badges        # High/low indicators
│       ├── Profanity Warnings    # Red alert badges
│       ├── Insights Lists        # Bullet points with icons
│       ├── Filter Enhancements   # Grid layout
│       └── Responsive Design     # Mobile/tablet/desktop
│
└── js/
    ├── config.js                 # API_BASE_URL
    │
    ├── api.js                    # HTTP client
    │   └── API                   # get, post, put, delete
    │
    ├── ui.js                     # UI utilities
    │   └── UI.Utils              # formatDate, showToast, etc.
    │
    ├── auth.js                   # Authentication
    │   └── AuthManager           # login, register, logout, checkAuth
    │
    ├── main.js                   # Global init
    │   └── Initialize navbar, smooth scroll
    │
    ├── dashboard.js              # Main dashboard ⭐
    │   └── DashboardManager
    │       ├── normalizeReview() # Schema compatibility
    │       ├── updateRecentReviews()
    │       ├── applyFilters()
    │       ├── switchTab()
    │       ├── exportData()
    │       └── ...
    │
    └── dashboard-enhanced.js     # Alternative version
```

---

## 🧩 Components

### DashboardManager (Core)

**Key Methods**:

#### `normalizeReview(review)` ⭐ NEW
Handles both old and new review schemas:
```javascript
normalizeReview(review) {
  return {
    id: review._id || review.id,
    rating: review.source?.rating || review.stars,
    text: review.processing?.concatenated_text || review.text,
    sentiment: review.analysis?.sentiment || review.overall_sentiment,
    category: review.analysis?.category || review.category,
    qualityScore: review.analysis?.quality?.quality_score,
    isProfane: review.processing?.is_profane,
    keyThemes: review.analysis?.key_themes || [],
    contextMatch: !review.analysis?.context?.has_mismatch,
    // ... and more
  };
}
```

#### `updateRecentReviews(reviews)`
Renders review cards with:
- Star ratings and badges
- Quality scores and warnings
- Key themes tags
- AI-generated content tabs
- Customer information

#### `applyFilters()`
Advanced filtering:
```javascript
let filtered = allReviews
  .filter(r => !sentimentFilter || r.sentiment === sentimentFilter)
  .filter(r => !categoryFilter || r.category === categoryFilter)
  .filter(r => !starsFilter || r.rating === parseInt(starsFilter))
  .filter(r => !dateFrom || new Date(r.date) >= dateFrom)
  .filter(r => qualityScore >= minQualityScore);
```

#### `exportData(format)`
Export reviews as CSV or JSON with all fields.

---

## 🎨 Styling

### CSS Architecture

**1. CSS Variables** (Design Tokens)
```css
:root {
  /* Colors */
  --primary: #2563eb;
  --success: #10b981;
  --error: #ef4444;
  
  /* Spacing */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing: 1rem;
  
  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 10px 15px -3px rgba(0,0,0,0.1);
  
  /* Radius */
  --radius: 0.75rem;
  --radius-full: 9999px;
}
```

**2. Component Classes**
```css
.review-card { ... }
.metric-card { ... }
.quality-badge { ... }
.theme-tag { ... }
.profanity-badge { ... }
```

**3. Utility Classes**
```css
.animate-float-up { ... }
.loading-dots { ... }
.no-data { ... }
```

### Responsive Breakpoints

```css
/* Mobile First */
@media (max-width: 480px) { 
  /* Stacked layout, compact badges */
}

@media (max-width: 768px) { 
  /* Tablet: 2-column grids */
}

@media (min-width: 1440px) { 
  /* Desktop: 5-column filters */
}
```

### New Schema Enhancements

**Key Themes Tags**:
```css
.theme-tag {
  background: linear-gradient(135deg, #eff6ff, #dbeafe);
  border-radius: 9999px;
  padding: 0.375rem 0.75rem;
  font-size: 0.8125rem;
}
```

**Quality Badges**:
```css
.quality-badge.high {
  background: linear-gradient(135deg, #f0fdf4, #dcfce7);
  color: var(--success);
}

.quality-badge.low {
  background: linear-gradient(135deg, #fef3c7, #fde68a);
  color: #92400e;
}
```

---

## 🔧 Development

### Making Changes

**1. Add New Filter**:
```javascript
// dashboard.html - Add select element
<select id="newFilter" onchange="DashboardManager.applyFilters()">
  <option value="">All</option>
</select>

// dashboard.js - Update applyFilters()
const newFilterValue = document.getElementById('newFilter').value;
filtered = filtered.filter(r => !newFilterValue || r.field === newFilterValue);
```

**2. Add New Metric**:
```javascript
// In updateMetrics()
const newMetric = calculateNewMetric(reviews);

metricsHTML += `
  <div class="metric-card">
    <div class="metric-value">${newMetric}</div>
    <div class="metric-label">New Metric</div>
  </div>
`;
```

**3. Add New Badge**:
```css
/* schema-enhancements.css */
.new-badge {
  background: gradient(...);
  color: var(--color);
  padding: 0.25rem 0.75rem;
  border-radius: var(--radius-full);
}
```

```javascript
// dashboard.js - In review card template
${condition ? `<span class="new-badge">Label</span>` : ''}
```

### Best Practices

✅ **Use CSS Variables** for consistency  
✅ **Mobile-First** responsive design  
✅ **Semantic HTML** for accessibility  
✅ **DRY Principle** - reuse components  
✅ **Progressive Enhancement** - works without JS  
✅ **Performance** - minimize DOM manipulation  

---

## 📱 Responsive Design

### Mobile (375px - 480px)
- Single column layout
- Stacked metrics
- Compact badges (smaller text)
- Full-width buttons
- Hidden icons in switchers

### Tablet (481px - 768px)
- 2-column grids
- Medium-sized badges
- Wrapped filter groups
- Side-by-side content switchers

### Desktop (769px+)
- Multi-column layouts
- Full-sized badges
- Horizontal filter bars
- Expanded content areas

### Print Styles
```css
@media print {
  .filter-section,
  .header-actions,
  .content-switcher {
    display: none !important;
  }
  
  .review-card {
    page-break-inside: avoid;
  }
}
```

---

## 🌐 Browser Support

| Browser | Version |
|---------|---------|
| Chrome | 90+ |
| Firefox | 88+ |
| Safari | 14+ |
| Edge | 90+ |
| Mobile Safari | iOS 14+ |
| Chrome Mobile | Latest |

**Required Features**:
- ES6+ (arrow functions, template literals, destructuring)
- Fetch API
- CSS Grid & Flexbox
- CSS Custom Properties (variables)

---

## 🔌 API Integration

### Configuration

```javascript
// config.js
const API_BASE_URL = 'http://localhost:5000';
```

### API Client

```javascript
// api.js
const API = {
  async get(endpoint, token) {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    return response.json();
  },
  
  async post(endpoint, data, token) { ... },
  async put(endpoint, data, token) { ... },
  async delete(endpoint, token) { ... }
};
```

### Usage Example

```javascript
// dashboard.js
async loadDashboard() {
  const token = localStorage.getToken('token');
  const response = await API.get('/api/dashboard', token);
  
  if (response.success) {
    this.updateMetrics(response.data.metrics);
    this.updateReviews(response.data.reviews);
  }
}
```

---

## 🎯 Performance Optimization

### Techniques Used

1. **Debounced Search** - Reduce API calls
2. **Pagination** - Load data in chunks
3. **Lazy Loading** - Images and charts on demand
4. **CSS Containment** - Optimize repaints
5. **Minimal Dependencies** - Only 4 external libs
6. **Code Splitting** - Separate dashboard.js
7. **Caching** - LocalStorage for tokens

### Bundle Size

- HTML: ~38 KB (total)
- CSS: ~70 KB (total, uncompressed)
- JS: ~50 KB (total, uncompressed)
- **Total**: ~158 KB (before gzip)
- **Gzipped**: ~40 KB

No build step required! ⚡

---

## 📚 Dependencies

### External Libraries (CDN)

```html
<!-- Chart.js - Data visualization -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@3"></script>

<!-- Marked.js - Markdown parsing -->
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>

<!-- DOMPurify - XSS protection -->
<script src="https://cdn.jsdelivr.net/npm/dompurify/dist/purify.min.js"></script>

<!-- Font Awesome - Icons -->
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
```

**Why CDN?**
- ⚡ Faster loading (cached across sites)
- 🔄 Automatic updates
- 🌍 Global distribution
- 💾 Reduced hosting costs

---

<a name="arabic-docs"></a>
## 🇸🇦 الدليل العربي

### التشغيل السريع

```bash
# افتح مجلد الفرونت إند
cd frontend

# شغل سيرفر محلي
python -m http.server 8000

# افتح المتصفح
# http://localhost:8000
```

### الملفات الرئيسية

- `index.html` - الصفحة الرئيسية
- `dashboard.html` - لوحة التحكم
- `css/style.css` - التنسيقات الأساسية  
- `css/schema-enhancements.css` - التحسينات الجديدة
- `js/dashboard.js` - منطق لوحة التحكم

### المميزات

- 📱 تصميم متجاوب للموبايل
- 🎨 واجهة عصرية وجذابة
- ⚡ أداء سريع بدون frameworks
- 🌐 دعم كامل للغة العربية RTL

---

<div align="center">

**Built with ❤️ using Vanilla JavaScript**

No frameworks, just modern web standards! 🚀

</div>
