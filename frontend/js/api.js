const API_CONFIG = {
  BASE_URL: 'https://api-reputation-guardian.vercel.app',
  TIMEOUT: 1000000,
  RETRIES: 3
};

async function apiRequest(endpoint, options = {}) {
  const url = `${API_CONFIG.BASE_URL}${endpoint}`;
  const config = {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    timeout: API_CONFIG.TIMEOUT,
    ...options
  };

  // Attach JWT if present
  const token = getStoredToken();
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  let lastError;
  for (let attempt = 1; attempt <= API_CONFIG.RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), config.timeout);

      const response = await fetch(url, { ...config, signal: controller.signal });
      clearTimeout(timeoutId);

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new APIError(response.status, errData.message || errData.error || `HTTP ${response.status}`, errData);
      }

      // Server returns { status, message, data: {...} }
      const json = await response.json();
      return json;

    } catch (error) {
      lastError = error;

      if (error.name === 'AbortError') {
        throw new APIError(408, 'Request timeout');
      }
      if (attempt === API_CONFIG.RETRIES) break;

      await new Promise((r) => setTimeout(r, Math.pow(2, attempt) * 1000)); // backoff
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
  try { localStorage.removeItem('auth_token'); } catch (e) { console.warn('Failed to clear token:', e); }
}

/** Auth APIs (normalized to return data object) */
const authAPI = {
  async register(userData) {
    try {
      const res = await apiRequest('/register', { method: 'POST', body: JSON.stringify(userData) });
      const data = res.data || res;

      if (data.token) storeToken(data.token);
      // Return normalized data to callers
      return data;
    } catch (err) {
      throw handleAuthError(err);
    }
  },

  async login(credentials) {
    try {
      const res = await apiRequest('/login', { method: 'POST', body: JSON.stringify(credentials) });
      const data = res.data || res;

      if (data.token) storeToken(data.token);
      return data;
    } catch (err) {
      throw handleAuthError(err);
    }
  },

  async logout() {
    try {
      await apiRequest('/logout', { method: 'POST' });
    } catch (err) {
      // even if API fails, we still clear token
      console.warn('Logout API failed:', err);
    } finally {
      clearStoredToken();
      return { message: 'Logged out locally' };
    }
  }
};

/** Dashboard APIs (normalized to return data object) */
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