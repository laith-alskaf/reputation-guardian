/** Modals */
const ModalManager = {
  show(id) {
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.classList.add('show');
    document.body.style.overflow = 'hidden';
    const focusables = modal.querySelectorAll('button,[href],input,select,textarea,[tabindex]:not([tabindex="-1"])');
    if (focusables.length) focusables[0].focus();
  },
  hide(id) {
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.classList.remove('show');
    document.body.style.overflow = '';
  },
  hideAll() {
    document.querySelectorAll('.modal').forEach(m => m.classList.remove('show'));
    document.body.style.overflow = '';
  }
};

/** Toasts */
const ToastManager = {
  show(message, type = 'success', duration = 4000) {
    const toast = document.getElementById('messageToast');
    const text = document.getElementById('messageText');
    const icon = toast.querySelector('i');

    // Clear existing progress bar
    const existingProgress = toast.querySelector('.toast-progress');
    if (existingProgress) existingProgress.remove();

    text.textContent = message;
    toast.className = 'toast';

    if (type === 'error') {
      toast.classList.add('error');
      icon.className = 'fas fa-exclamation-triangle';
    } else if (type === 'warning') {
      toast.classList.add('warning');
      icon.className = 'fas fa-exclamation-circle';
    } else {
      toast.classList.add('success');
      icon.className = 'fas fa-check-circle';
    }

    // Add progress bar
    const progressBar = document.createElement('div');
    progressBar.className = 'toast-progress';
    toast.appendChild(progressBar);

    // Show toast with animation
    toast.classList.add('show');

    // Auto hide after duration
    setTimeout(() => this.hide(), duration);

    // Allow manual close on click
    toast.addEventListener('click', () => this.hide());
  },
  hide() {
    const toast = document.getElementById('messageToast');
    if (!toast.classList.contains('show')) return;

    // Add hide animation
    toast.classList.add('hide');

    // Remove from DOM after animation
    setTimeout(() => {
      toast.classList.remove('show', 'hide');
      const progressBar = toast.querySelector('.toast-progress');
      if (progressBar) progressBar.remove();
    }, 400); // Match CSS transition duration
  }
};

/** Loading */
const LoadingManager = {
  show(elementId) {
    const el = document.getElementById(elementId);
    if (!el) return;
    el.classList.add('loading');
    if ('disabled' in el) el.disabled = true;
    
    // Add spinner icon to button if it's a button
    if (el.tagName === 'BUTTON' && !el.querySelector('.loading-spinner-icon')) {
      const originalContent = el.innerHTML;
      el.dataset.originalContent = originalContent;
      el.innerHTML = '<i class="fas fa-spinner fa-spin loading-spinner-icon"></i> جاري التحميل...';
    }
  },
  
  hide(elementId) {
    const el = document.getElementById(elementId);
    if (!el) return;
    el.classList.remove('loading');
    if ('disabled' in el) el.disabled = false;
    
    // Restore original button content
    if (el.tagName === 'BUTTON' && el.dataset.originalContent) {
      el.innerHTML = el.dataset.originalContent;
      delete el.dataset.originalContent;
    }
  },
  
  showFullscreen(message = 'جاري التحميل...') {
    let overlay = document.getElementById('loadingOverlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'loadingOverlay';
      overlay.className = 'loading-overlay';
      overlay.innerHTML = `
        <div class="loading-spinner">
          <i class="fas fa-spinner fa-spin"></i>
          <p>${message}</p>
        </div>
      `;
      document.body.appendChild(overlay);
    }
    overlay.style.display = 'flex';
  },
  
  hideFullscreen() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) overlay.style.display = 'none';
  }
};

/** Validation */
const FormValidator = {
  isValidEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  },
  validatePassword(password) {
    const result = { isValid: true, errors: [] };
    if (password.length < 6) { result.isValid = false; result.errors.push('كلمة المرور يجب أن تكون 6 أحرف على الأقل'); }
    if (!/[A-Za-z]/.test(password)) { result.isValid = false; result.errors.push('كلمة المرور يجب أن تحتوي على حرف واحد على الأقل'); }
    if (!/\d/.test(password)) { result.isValid = false; result.errors.push('كلمة المرور يجب أن تحتوي على رقم واحد على الأقل'); }
    return result;
  },
  showError(fieldId, message) {
    const field = document.getElementById(fieldId);
    if (!field) return;
    field.classList.add('error-border');
    let err = field.parentNode.querySelector('.field-error');
    if (!err) {
      err = document.createElement('div');
      err.className = 'field-error';
      field.parentNode.appendChild(err);
    }
    err.textContent = message;
    err.style.display = 'block';
  },
  clearError(fieldId) {
    const field = document.getElementById(fieldId);
    if (!field) return;
    field.classList.remove('error-border');
    const err = field.parentNode.querySelector('.field-error');
    if (err) err.style.display = 'none';
  },
  resetForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return;
    form.querySelectorAll('input, select').forEach(f => {
      f.classList.remove('error-border');
      const err = f.parentNode.querySelector('.field-error');
      if (err) err.style.display = 'none';
    });
  }
};

/** Navigation & scroll */
const NavigationManager = {
  init() {
    this.updateActiveNavLink();
    this.handleScroll();
    window.addEventListener('scroll', () => this.handleScroll());
  },
  updateActiveNavLink() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    let current = '';
    sections.forEach(s => {
      const top = s.offsetTop;
      const height = s.clientHeight;
      if (window.pageYOffset >= top - height / 3) current = s.id;
    });
    navLinks.forEach(link => {
      link.classList.toggle('active', link.getAttribute('href') === `#${current}`);
    });
  },
  handleScroll() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) navbar.classList.add('scrolled');
    else navbar.classList.remove('scrolled');
    this.updateActiveNavLink();
  },
  scrollToSection(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
};

/** Utils */
const Utils = {
  formatDate(date) {
    if (!date) return '';
    const d = new Date(date);
    // استخدام تنسيق ميلادي صريح لضمان عدم عرض التاريخ الهجري
    const options = {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory' // فرض التقويم الميلادي
    };
    return d.toLocaleDateString('ar', options);
  },
  truncate(text, max) { 
    if (!text) return ''; 
    return text.length <= max ? text : text.slice(0, max) + '…'; 
  }
};

/** Mobile Menu */
function toggleMobileMenu() {
  const menu = document.getElementById('mobileMenu');
  const hamburger = document.getElementById('hamburger');
  if (menu && hamburger) {
    menu.classList.toggle('show');
    hamburger.classList.toggle('active');
  }
}

function closeMobileMenu() {
  const menu = document.getElementById('mobileMenu');
  const hamburger = document.getElementById('hamburger');
  if (menu && hamburger) {
    menu.classList.remove('show');
    hamburger.classList.remove('active');
  }
}

function scrollToFeatures() {
  const el = document.getElementById('features');
  if (el) el.scrollIntoView({ behavior: 'smooth' });
}

// Export functions to window
window.toggleMobileMenu = toggleMobileMenu;
window.closeMobileMenu = closeMobileMenu;
window.scrollToFeatures = scrollToFeatures;

window.UI = { Modal: ModalManager, Toast: ToastManager, Loading: LoadingManager, Validator: FormValidator, Navigation: NavigationManager, Utils: Utils };
