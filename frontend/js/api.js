/**
 * Enhanced API Client with better error handling and loading states
 */

async function apiRequest(endpoint, options = {}) {
  const url = `${window.CONFIG.API.BASE_URL}${endpoint}`;
  const config = {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    timeout: window.CONFIG.API.TIMEOUT,
    ...options
  };

  // Attach JWT if present
  const token = getStoredToken();
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  let lastError;
  for (let attempt = 1; attempt <= window.CONFIG.API.RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), config.timeout);

      const response = await fetch(url, { ...config, signal: controller.signal });
      clearTimeout(timeoutId);

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new APIError(response.status, errData.message || errData.error || `HTTP ${response.status}`, errData);
      }

      const json = await response.json();
      return json;

    } catch (error) {
      lastError = error;

      // Handle abort errors
      if (error.name === 'AbortError') {
        throw new APIError(408, 'انتهى وقت الطلب. يرجى المحاولة مرة أخرى.');
      }

      // Handle network errors
      if (error.message === 'Failed to fetch' || error.message.includes('NetworkError')) {
        throw new APIError(0, 'لا يمكن الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.');
      }

      // Don't retry for client errors (400/401/409)
      if (error instanceof APIError && error.status >= 400 && error.status < 500) break;

      // Retry for server errors
      if (attempt === window.CONFIG.API.RETRIES) break;

      // Exponential backoff
      await new Promise((r) => setTimeout(r, Math.pow(2, attempt) * 1000));
    }
  }
  throw lastError;
}

class APIError extends Error {
  constructor(status, message, data = {}) {
    super(message);
    this.name = 'APIError';
    this.status = status;
    this.data = data;
  }
}

/** Token storage */
function storeToken(token) {
  try { localStorage.setItem('auth_token', token); } catch (e) { console.warn('Failed to store token:', e); }
}
function getStoredToken() {
  try { return localStorage.getItem('auth_token'); } catch (e) { console.warn('Failed to retrieve token:', e); return null; }
}
function clearStoredToken() {
  try { localStorage.removeItem('auth_token'); localStorage.removeItem('shop_info'); } catch (e) { console.warn('Failed to clear token:', e); }
}

/** Auth APIs */
const authAPI = {
  async register(userData) {
    try {
      const res = await apiRequest('/register', { method: 'POST', body: JSON.stringify(userData) });
      const data = res.data || res;

      if (data.token) {
        storeToken(data.token);
        localStorage.setItem('shop_info', JSON.stringify({
          shop_id: data.shop_id,
          shop_type: data.shop_type,
          shop_name: data.shop_name
        }));
      }
      return data;
    } catch (err) {
      throw handleAuthError(err);
    }
  },

  async login(credentials) {
    try {
      const res = await apiRequest('/login', { method: 'POST', body: JSON.stringify(credentials) });
      const data = res.data || res;

      if (data.token) {
        storeToken(data.token);
        localStorage.setItem('shop_info', JSON.stringify({
          shop_id: data.shop_id,
          shop_type: data.shop_type,
          shop_name: data.shop_name
        }));
      }
      return data;
    } catch (err) {
      throw handleAuthError(err);
    }
  },

  async logout() {
    try {
      await apiRequest('/logout', { method: 'POST' });
    } catch (err) {
      console.warn('Logout API failed:', err);
    } finally {
      clearStoredToken();
      return { message: 'Logged out locally' };
    }
  }
};

/** Dashboard APIs */
const dashboardAPI = {
  async getDashboard() {
    const res = await apiRequest('/dashboard');
    return res.data || res;
  },
  async getProfile() {
    const res = await apiRequest('/profile');
    return res.data || res;
  }
};

/** QR APIs */
const qrAPI = {
  async generateQR() {
    const res = await apiRequest('/generate-qr', { method: 'POST' });
    return res.data || res;
  },
  async getQR(shopId) {
    const res = await apiRequest(`/qr/${shopId}`);
    return res.data || res;
  }
};

/** Error mapping for authentication */
function handleAuthError(error) {
  if (error instanceof APIError) {
    switch (error.status) {
      case 400: return new Error('بيانات غير صحيحة. يرجى التحقق من المدخلات.');
      case 401: return new Error('بيانات الدخول غير صحيحة.');
      case 409: return new Error('البريد الإلكتروني مستخدم مسبقاً.');
      case 429: return new Error('تم تجاوز عدد المحاولات المسموحة. يرجى المحاولة لاحقاً.');
      default:  return new Error(error.message || 'حدث خطأ في المصادقة.');
    }
  }
  if (error.message?.includes('Failed to fetch') || error.message?.includes('NetworkError')) {
    return new Error('لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.');
  }
  return new Error('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
}

/** Simple JWT exp check */
function isAuthenticated() {
  const token = getStoredToken();
  if (!token) return false;
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    const now = Date.now() / 1000;
    return payload.exp > now;
  } catch (e) {
    clearStoredToken();
    return false;
  }
}

/** Export */
window.API = {
  auth: authAPI,
  dashboard: dashboardAPI,
  qr: qrAPI,
  isAuthenticated,
  clearStoredToken
};