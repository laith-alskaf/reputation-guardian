# 📱 Reputation Guardian - Flutter App

## 🎯 نظرة عامة
تطبيق موبايل لإدارة تقييمات العملاء بالذكاء الاصطناعي، مبني باستخدام **Clean Architecture** و **BLoC Pattern**.

## ✅ ما تم إنجازه (115+ ملف)

### 🏗️ Core Layer
- Constants، Theme (Light/Dark)
- Error Handling (Failures & Exceptions)
- Network Layer مع Dio & Interceptors
- **Responsive Utilities** - Extensions للتجاوب التلقائي
- Validators، Date Formatter، Helpers
- Dependency Injection (get_it + injectable)

### 🎨 Custom Widgets (11 ويدجت)
- **CustomButton** - زر مع loading state
- **CustomTextField** - حقل نص مع RTL
- **MetricCard** - بطاقة مقاييس
- **SentimentBadge** - رمز المشاعر
- **CategoryBadge** - رمز الفئة مع أيقونة
- **ReviewCard** - بطاقة تقييم متجاوبة
- **ResponsiveScaffold** - Scaffold متكيف
- **LoadingWidget، ErrorWidget، EmptyStateWidget**

### 🔐 Auth Feature (مكتمل 100%)
**Domain:**
- User Entity  
- AuthRepository Interface
- Use Cases: Login، Register، Logout

**Data:**
- UserModel + JSON Serialization
- Remote/Local DataSources
- Repository Implementation

**Presentation:**
- AuthBloc (Events، States، Bloc)
- **SplashScreen** - شاشة بداية متحركة
- **LoginPage** - تسجيل دخول
- **RegisterPage** - إنشاء حساب

### 📊 Dashboard Feature (مكتمل 80%)
**Domain:**
- Review، DashboardData، ShopInfo، Metrics Entities
- DashboardRepository Interface
- GetDashboardUseCase

**Presentation:**
- **DashboardPage** - لوحة تحكم متجاوبة
- **ReviewsPage** - مع Tabs و Filters
- **SettingsPage** - إعدادات كاملة
- **MainNavigation** - BottomNavigationBar

## 🎨 التصميم المتجاوب

### Breakpoints
- 📱 **Mobile**: width < 600px
- 📋 **Tablet**: 600px ≤ width < 900px
- 💻 **Desktop**: width ≥ 900px

### Adaptive Features
✅ **Responsive Spacing** - مسافات تتكيف تلقائياً  
✅ **Responsive Fonts** - أحجام خطوط متجاوبة  
✅ **GridView** - عدد الأعمدة يتغير حسب الشاشة  
✅ **Row ↔ Column** - تبديل تلقائي للتخطيط  
✅ **RTL Support** - دعم كامل للعربية

```dart
// مثال على الاستخدام
context.isMobile // true/false
context.responsive(mobile: 2, tablet: 3, desktop: 5)
ResponsiveSpacing.medium(context)
```

## 📱 الشاشات (7 شاشات)

1. **SplashScreen** - شاشة بداية مع Fade/Scale Animation
2. **LoginPage** - تسجيل الدخول
3. **RegisterPage** - إنشاء حساب (20 نوع متجر)
4. **DashboardPage** - لوحة التحكم
   - Welcome Card
   - Metrics Grid (يتكيف: 2/3/5 أعمدة)
   - Quick Actions
   - Recent Reviews
5. **ReviewsPage** - التقييمات
   - 3 Tabs (مقبولة، منخفضة الجودة، غير ذات صلة)
   - Filters (الكل، إيجابي، سلبي، محايد)
6. **SettingsPage** - الإعدادات
   - Account، Notifications، App Settings
7. **MainNavigation** - التنقل الرئيسي

## 🎯 مبادئ UI/UX المطبقة

✅ **Visual Hierarchy** - تسلسل بصري واضح  
✅ **Consistent Spacing** - مسافات متناسقة  
✅ **Color-coded Feedback** - ألوان ذات معنى  
✅ **Smooth Animations** - انتقالات سلسة  
✅ **Touch-friendly** - أزرار كبيرة (48x48 min)  
✅ **Loading States** - حالات تحميل واضحة  
✅ **Error Handling** - معالجة أخطاء صديقة  
✅ **Empty States** - حالات فارغة جميلة

## 🚀 التشغيل

```bash
# 1. الانتقال للمجلد
cd app

# 2. تثبيت الباكجات
flutter pub get

# 3. (اختياري) Code Generation
flutter pub run build_runner build --delete-conflicting-outputs

# 4. تشغيل التطبيق
flutter run
```

## 📊 الإحصائيات

- 📁 **الملفات**: 115+
- 🎨 **Custom Widgets**: 11
- 📱 **Screens**: 7
- ⚙️ **Features**: 2 (Auth + Dashboard)
- 🎯 **Use Cases**: 4
- 📦 **Models**: 3+

## 🔜 القادم (اختياري)

- [ ] Dashboard BLoC Integration
- [ ] Reviews BLoC Integration
- [ ] QR Code Feature
- [ ] Analytics Charts
- [ ] Profile Management
- [ ] Data Export

## 💡 نقاط القوة

✨ **Clean Architecture** - معمارية نظيفة قابلة للتوسع  
✨ **BLoC Pattern** - إدارة حالة احترافية  
✨ **Responsive Design** - يعمل على جميع الأحجام  
✨ **RTL Support** - دعم كامل للعربية  
✨ **Type Safety** - كود آمن مع Dart  
✨ **DI** - Dependency Injection محترف  
✨ **Error Handling** - معالجة شاملة للأخطاء

---

**المطور**: مع التركيز على الجودة والأداء 🚀  
**الترخيص**: © 2025 Reputation Guardian
