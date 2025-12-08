/**
 * App bootstrapping and page-specific initialization
 */
const App = {
  async init() {
    try {
      if (document.readyState === 'loading') {
        await new Promise((resolve) => document.addEventListener('DOMContentLoaded', resolve));
      }

      window.UI.Navigation.init();
      window.Forms.init();

      // تحقق من حالة المستخدم أولاً
      await window.Auth.checkAuthStatus();

      // ثم تهيئة الصفحة
      this.initPage();
    } catch (e) {
      console.error('App init failed:', e);
      window.UI.Toast.show('حدث خطأ في تحميل التطبيق', 'error');
    }
  },

  initPage() {
    const page = this.getPage();
    if (page === 'index') this.initHomePage();
    else if (page === 'dashboard') this.initDashboardPage();
  },

  getPage() {
    const path = window.location.pathname;
    const page = path.split('/').pop().split('.')[0];
    return (!page || page === 'index') ? 'index' : page;
  },

  initHomePage() {
    document.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', (e) => {
        if (link.getAttribute('href')?.startsWith('#')) {
          e.preventDefault();
          const id = link.getAttribute('href').substring(1);
          window.UI.Navigation.scrollToSection(id);
        }
      });
    });

    // Initialize contact form
    this.initContactForm();

    // Close toast on click
    document.addEventListener('click', (e) => {
      if (e.target.closest('.toast')) window.UI.Toast.hide();
    });
  },

  initContactForm() {
    const form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      await this.handleContactSubmit(form);
    });

    // Real-time validation
    const inputs = form.querySelectorAll('input, textarea');
    inputs.forEach((input) => {
      input.addEventListener('blur', () => this.validateContactField(input));
      input.addEventListener('input', () => {
        if (input.classList.contains('error-border')) {
          input.classList.remove('error-border');
          const error = input.parentNode.querySelector('.field-error');
          if (error) error.style.display = 'none';
        }
      });
    });
  },

  async handleContactSubmit(form) {
    try {
      window.UI.Loading.show('contactSubmitBtn');

      // Validate all fields
      const inputs = form.querySelectorAll('input, textarea');
      let isValid = true;
      inputs.forEach((input) => {
        if (!this.validateContactField(input)) isValid = false;
      });

      if (!isValid) {
        window.UI.Toast.show('يرجى تصحيح الأخطاء في النموذج', 'error');
        return;
      }

      const formData = new FormData(form);
      const contactData = {
        name: formData.get('name')?.trim(),
        email: formData.get('email')?.trim(),
        subject: formData.get('subject')?.trim(),
        message: formData.get('message')?.trim()
      };

      // Here you would send the data to your backend
      // For now, we'll simulate a successful submission
      await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate API call

      window.UI.Toast.show('تم إرسال رسالتك بنجاح! سنتواصل معك قريباً', 'success');
      form.reset();

    } catch (error) {
      console.error('Contact form submission failed:', error);
      window.UI.Toast.show('حدث خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى', 'error');
    } finally {
      window.UI.Loading.hide('contactSubmitBtn');
    }
  },

  validateContactField(field) {
    const value = field.value.trim();
    const label = field.previousElementSibling?.textContent || field.name || field.id;

    // Clear previous errors
    field.classList.remove('error-border');
    const existingError = field.parentNode.querySelector('.field-error');
    if (existingError) existingError.remove();

    // Required validation
    if (field.hasAttribute('required') && !value) {
      this.showFieldError(field, `${label} مطلوب`);
      return false;
    }

    // Email validation
    if (field.type === 'email' && value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(value)) {
        this.showFieldError(field, 'يرجى إدخال بريد إلكتروني صحيح');
        return false;
      }
    }

    // Minimum length validation
    const minLength = field.getAttribute('minlength');
    if (minLength && value && value.length < parseInt(minLength)) {
      this.showFieldError(field, `${label} يجب أن يكون ${minLength} أحرف على الأقل`);
      return false;
    }

    return true;
  },

  showFieldError(field, message) {
    field.classList.add('error-border');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'field-error';
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
    field.parentNode.appendChild(errorDiv);
  },

  initDashboardPage() {
    DashboardManager.init();
  }
};

window.addEventListener('error', (e) => {
  console.error('Global error:', e.error);
  window.UI.Toast.show('حدث خطأ غير متوقع', 'error');
});

window.addEventListener('unhandledrejection', (e) => {
  console.error('Unhandled promise rejection:', e.reason);
  window.UI.Toast.show('حدث خطأ في الاتصال', 'error');
});

// PWA Registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        console.log('SW registered: ', registration);
      })
      .catch(registrationError => {
        console.log('SW registration failed: ', registrationError);
      });
  });
}

// Install prompt for PWA
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;

  // Show install button or notification
  if (window.location.pathname === '/index.html' || window.location.pathname === '/') {
    setTimeout(() => {
      window.UI.Toast.show(
        'يمكنك تثبيت التطبيق على جهازك للحصول على تجربة أفضل',
        'info',
        8000
      );
    }, 3000);
  }
});

// Handle successful installation
window.addEventListener('appinstalled', (evt) => {
  console.log('PWA was installed successfully');
  window.UI.Toast.show('تم تثبيت التطبيق بنجاح!', 'success');
});

document.addEventListener('DOMContentLoaded', () => App.init());
window.App = App;
