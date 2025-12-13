/**
 * Configuration file for Frontend
 * Manages environment-specific settings
 */

const CONFIG = {
  // API Configuration
  API: {
    // Base URL - Auto-detect environment
    BASE_URL: (() => {
      // Check if running on localhost
      if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://127.0.0.1:5000';
      }
      // Production URL
      return 'https://api-reputation-guardian.vercel.app';
    })(),
    
    TIMEOUT: 60000, // 60 seconds
    RETRIES: 3,
    
    // Endpoints
    ENDPOINTS: {
      REGISTER: '/register',
      LOGIN: '/login',
      LOGOUT: '/logout',
      DASHBOARD: '/dashboard',
      PROFILE: '/profile',
      GENERATE_QR: '/generate-qr',
      GET_QR: '/qr',
      WEBHOOK: '/webhook'
    }
  },

  // App Configuration
  APP: {
    NAME: 'حارس السمعة',
    VERSION: '1.0.0',
    DESCRIPTION: 'نظام إدارة تقييمات العملاء',
    LANGUAGE: 'ar',
    DIRECTION: 'rtl'
  },

  // UI Configuration
  UI: {
    TOAST_DURATION: 4000,
    MODAL_ANIMATION_DURATION: 300,
    LOADING_MIN_DURATION: 500,
    DEBOUNCE_DELAY: 300
  },

  // Validation Rules
  VALIDATION: {
    PASSWORD_MIN_LENGTH: 6,
    SHOP_NAME_MIN_LENGTH: 2,
    EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  },

  // Storage Keys
  STORAGE: {
    AUTH_TOKEN: 'auth_token',
    SHOP_INFO: 'shop_info',
    USER_PREFERENCES: 'user_preferences'
  },

  // Pagination
  PAGINATION: {
    DEFAULT_PAGE_SIZE: 10,
    MAX_PAGE_SIZE: 100
  }
};

// Freeze config to prevent modifications
Object.freeze(CONFIG);
Object.freeze(CONFIG.API);
Object.freeze(CONFIG.API.ENDPOINTS);
Object.freeze(CONFIG.APP);
Object.freeze(CONFIG.UI);
Object.freeze(CONFIG.VALIDATION);
Object.freeze(CONFIG.STORAGE);
Object.freeze(CONFIG.PAGINATION);

// Export to window
window.CONFIG = CONFIG;
