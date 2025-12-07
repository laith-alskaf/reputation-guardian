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
      this.initPage();
      await window.Auth.checkAuthStatus();
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

    // Close toast on click
    document.addEventListener('click', (e) => { if (e.target.closest('.toast')) window.UI.Toast.hide(); });
  },

  initDashboardPage() {
    // Everything is handled in DashboardManager
    // Here we can add any page-specific hooks later
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

document.addEventListener('DOMContentLoaded', () => App.init());
window.App = App;