/**
 * Authentication: state, forms, UI updates
 */

const AuthManager = {
  currentUser: null,

  async checkAuthStatus() {
    if (window.API.isAuthenticated()) {
      try {
        const profile = await window.API.dashboard.getProfile();
        this.currentUser = profile;
        this.updateUIForAuthenticatedUser();
        return true;
      } catch (e) {
        console.warn('Token validation failed:', e);
        this.logout();
        return false;
      }
    }
    this.updateUIForGuest();
    return false;
  },

  updateUIForAuthenticatedUser() {
    const navLinks = document.getElementById("navLinks");
    const userInfo = document.getElementById("userInfo");
    if (navLinks) navLinks.style.display = "none";
    if (userInfo) {
      userInfo.style.display = "flex";
      document.getElementById("userName").textContent =
        this.currentUser.shop_name || this.currentUser.email || "المستخدم";
    }

    // Hide hero buttons for authenticated users
    const heroButtons = document.querySelector('.hero-buttons');
    if (heroButtons) heroButtons.style.display = 'none';
  },

  updateUIForGuest() {
    const navLinks = document.getElementById("navLinks");
    const userInfo = document.getElementById("userInfo");
    if (navLinks) navLinks.style.display = "flex";
    if (userInfo) userInfo.style.display = "none";

    // Show hero buttons for guest users
    const heroButtons = document.querySelector('.hero-buttons');
    if (heroButtons) heroButtons.style.display = 'flex';
  },

  async login(credentials) {
    try {
      window.UI.Loading.show('loginSubmitBtn');
      if (!window.UI.Validator.isValidEmail(credentials.email)) throw new Error('يرجى إدخال بريد إلكتروني صحيح');
      if (!credentials.password) throw new Error('يرجى إدخال كلمة المرور');

      const data = await window.API.auth.login(credentials);
      this.currentUser = {
        email: credentials.email,
        shop_id: data.shop_id,
        shop_type: data.shop_type,
        shop_name: data.shop_name
      };

      window.UI.Toast.show('تم تسجيل الدخول بنجاح', 'success');
      window.UI.Modal.hide('loginModal');
      this.updateUIForAuthenticatedUser();
      setTimeout(() => {
        window.location.href = 'dashboard-v2.html';
      }, 800);
    } catch (error) {
      window.UI.Toast.show(error.message || 'فشل تسجيل الدخول', 'error');
    } finally {
      window.UI.Loading.hide('loginSubmitBtn');
    }
  },

  async register(userData) {
    try {
      window.UI.Loading.show('registerSubmitBtn');
      if (!window.UI.Validator.isValidEmail(userData.email)) throw new Error('يرجى إدخال بريد إلكتروني صحيح');
      if (!userData.shop_name || userData.shop_name.length < 2) throw new Error('اسم المتجر قصير جداً');
      if (!userData.shop_type) throw new Error('يرجى اختيار نوع المتجر');

      const data = await window.API.auth.register(userData);
      this.currentUser = {
        email: userData.email,
        shop_name: userData.shop_name,
        shop_id: data.shop_id,
        shop_type: data.shop_type
      };

      window.UI.Toast.show('تم إنشاء الحساب بنجاح', 'success');
      window.UI.Modal.hide('registerModal');
      this.updateUIForAuthenticatedUser();
      setTimeout(() => {
        window.location.href = 'dashboard.html';
      }, 1500);
    } catch (error) {
      window.UI.Toast.show(error.message || 'فشل إنشاء الحساب', 'error');
    } finally {
      window.UI.Loading.hide('registerSubmitBtn');
    }
  },

  async logout() {
    try {
      await window.API.auth.logout();
    } catch (error) {
      console.warn('Logout API call failed:', error);
    }
    this.currentUser = null;
    this.updateUIForGuest();
    window.UI.Toast.show('تم تسجيل الخروج بنجاح', 'success');
    // Redirect immediately to ensure it happens
    window.location.href = 'index.html';
  }
};

/** Form handlers */
const FormHandlers = {
  init() {
    this.initLoginForm();
    this.initRegisterForm();
  },
  initLoginForm() {
    const form = document.getElementById('loginForm');
    if (!form) return;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(form);
      const credentials = { email: fd.get('email')?.trim(), password: fd.get('password') };
      await AuthManager.login(credentials);
    });
  },
  initRegisterForm() {
    const form = document.getElementById('registerForm');
    if (!form) return;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(form);
      const userData = {
        email: fd.get('email')?.trim(),
        password: fd.get('password'),
        shop_name: fd.get('shop_name')?.trim(),
        shop_type: fd.get('shop_type')
      };
      await AuthManager.register(userData);
    });

    // Real-time validation
    const inputs = form.querySelectorAll('input, select');
    inputs.forEach((input) => {
      input.addEventListener('blur', () => this.validateField(input));
      input.addEventListener('input', () => {
        if (input.classList.contains('error')) window.UI.Validator.clearError(input.id);
      });
    });
  },
  validateField(field) {
    const value = field.value.trim();
    const label = field.labels?.[0]?.innerText || field.name || field.id;
    window.UI.Validator.clearError(field.id);
    if (field.hasAttribute('required') && !value) {
      window.UI.Validator.showError(field.id, `${label} مطلوب`);
      return false;
    }
    if (field.type === 'email' && value && !window.UI.Validator.isValidEmail(value)) {
      window.UI.Validator.showError(field.id, 'يرجى إدخال بريد إلكتروني صحيح');
      return false;
    }
    if (field.type === 'password' && value) {
      const v = window.UI.Validator.validatePassword(value);
      if (!v.isValid) {
        window.UI.Validator.showError(field.id, v.errors[0]);
        return false;
      }
    }
    const min = field.getAttribute('minlength');
    if (min && value && value.length < parseInt(min)) {
      window.UI.Validator.showError(field.id, `${label} يجب أن يكون ${min} أحرف على الأقل`);
      return false;
    }
    return true;
  }
};

/** Modal helpers */
function showLoginModal() { window.UI.Modal.show('loginModal'); }
function showRegisterModal() { window.UI.Modal.show('registerModal'); }
function closeModal(id) { window.UI.Modal.hide(id); }
function switchToRegister() { window.UI.Modal.hide('loginModal'); window.UI.Modal.show('registerModal'); }
function switchToLogin() { window.UI.Modal.hide('registerModal'); window.UI.Modal.show('loginModal'); }

window.Auth = AuthManager;
window.Forms = FormHandlers;
window.Modals = { switchToRegister, switchToLogin };
