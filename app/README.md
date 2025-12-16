# 📱 Reputation Guardian - Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.27.1-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.6.0-0175C2?logo=dart)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blue.svg)
![BLoC](https://img.shields.io/badge/State-BLoC%20Pattern-orange)

**Modern Flutter App built with Clean Architecture & BLoC Pattern**

[العربية](#arabic-docs) | [English](#english)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Dependencies](#dependencies)
- [Development](#development)

---

## 🌟 Overview

The **Reputation Guardian Mobile App** is a cross-platform Flutter application providing shop owners with powerful tools to manage customer reviews, monitor sentiment, and access AI-powered insights on the go. Built with **Clean Architecture** and **BLoC pattern** for maintainability and scalability.

### Why This App?

- 📱 **Native Performance** - Smooth 60fps animations
- 🎨 **Beautiful UI** - Modern Material Design 3 with responsive layout
- 🔄 **Real-time Updates** - Live dashboard metrics
- 🌐 **RTL Support** - Full Arabic language support with proper text direction
- 📊 **Rich Analytics** - Interactive charts and insights
- 🔐 **Secure** - JWT authentication with token refresh
- 📴 **Offline-First** - Local caching with smart cache→API→generate flow
- ⚠️ **Quality Indicators** - Advanced review quality warnings and flags

---

## ✨ Features

### 🏠 Dashboard

#### Metrics Overview
- **Real-time Statistics**
  - Total reviews count with trend
  - Average rating display (5-star system)
  - Positive/negative reviews count
  - Sentiment distribution visualization
  - **Responsive Grid Layout** - 2 columns on mobile, 3 on tablet, 4 on desktop

#### Quick Actions
- **QR Code Management**
  - Smart QR flow: Cache → API → Generate
  - Dedicated QR Dialog with clean UI
  - **Download to Gallery** - Direct save using `gal` package
  - **Share QR Code** - Share via WhatsApp, Email, etc.
  - Offline QR code viewing from cache
  - Date-formatted QR code with Arabic locale support

### 📊 Analytics Page

- **Period Filtering**
  - Last 7 days / 30 days / 90 days
  - Custom date range selection

- **Interactive Charts**
  - Rating distribution bar chart
  - Sentiment pie chart with legend
  - Trend analysis visualizations

- **Data Insights**
  - Category breakdown
  - Quality metrics
  - Temporal patterns

### 📝 Reviews Management

- **Tabbed Interface**
  - Processed reviews (accepted)
  - Rejected - Low Quality
  - Rejected - Irrelevant

- **Enhanced Review Cards**
  - **Sentiment Display** - Color-coded sentiment badges (Positive/Negative/Neutral)
  - **Star Ratings** - Visual 5-star display
  - **Review Text Preview** - 3-line preview with ellipsis
  - **Date/Time** - Formatted with Arabic locale (e.g., "15 ديسمبر 2024، 10:30 م")
  - **Quality Score Badge** - Color-coded quality indicator (green ≥70%, orange <70%)
  - **Warning Ribbons**:
    - 🚫 **Profane Content** - Red ribbon for inappropriate content
    - 🚩 **Quality Flags** - Orange ribbon for flagged reviews (toxicity, spam, low quality, irrelevant)

- **Search & Filter**
  - Real-time search
  - Filter by sentiment, rating, category
  - Sort options

- **Review Details Dialog**
  - **Customer Information**
    - Email (copyable with one click)
    - Phone number (copyable, LTR formatted: +963...)
    - Review date and rating
    - Sentiment and category
  - **AI-Generated Content**
    - Summary
    - Actionable insights
    - Suggested reply (copy to clipboard)
    - Key themes tags
  - **Quality Analysis**
    - Quality score display
  - **⚠️ Quality Warnings Section** (if applicable):
    - 🚫 Profane content warning
    - ⚠️ Suspicious review indicator
    - 🚩 Quality flags with Arabic descriptions:
      - `high_toxicity` → "سمية عالية: يحتوي على لغة سامة أو عنيفة"
      - `spam` → "بريد عشوائي: قد يكون محتوى ترويجي غير مرغوب"
      - `low_quality` → "جودة منخفضة: محتوى ضعيف أو غير مفيد"
      - `irrelevant` → "غير ذي صلة: المحتوى غير متعلق بالمنتج أو الخدمة"

### ⚙️ Settings & Profile

- **Profile Management**
  - Edit personal information
  - Shop details configuration

- **Telegram Integration**
  - Connect bot for notifications
  - Rich Telegram messages
  - Real-time alerts

- **About & Support**
  - App information
  - Contact support
  - Terms and privacy

---

## 🏗️ Architecture

### Clean Architecture Layers

```
lib/
├── core/                       # Layer 0: Shared Core
│   ├── theme/                  # App theme (Material 3)
│   ├── utils/                  # Utilities & helpers
│   ├── error/                  # Error handling
│   ├── network/                # HTTP client (Dio)
│   ├── di/                     # Dependency injection (GetIt)
│   └── widgets/                # Shared UI components
│
├── features/                   # Layer 1-4: Feature Modules
│   ├── auth/                   # Authentication feature
│   │   ├── domain/             # Business logic
│   │   │   ├── entities/       # Auth entities
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Use cases
│   │   ├── data/               # Data layer
│   │   │   ├── models/         # API models
│   │   │   ├── datasources/    # Remote/local sources
│   │   │   └── repositories/   # Repository implementations
│   │   └── presentation/       # UI layer
│   │       ├── bloc/           # BLoC state management
│   │       ├── pages/          # Screen widgets
│   │       └── widgets/        # Feature-specific widgets
│   │
│   ├── dashboard/              # Dashboard feature
│   ├── analytics/              # Analytics feature
│   ├── reviews/                # Reviews management (enhanced)
│   ├── profile/                # Profile & settings
│   ├── qr/                     # QR code generation (improved flow)
│   └── settings/               # App settings
│
└── main.dart                   # App entry point
```

### Design Principles

✅ **Dependency Inversion** - Layers depend on abstractions  
✅ **Single Responsibility** - Each class has one purpose  
✅ **Feature-First Organization** - Modular and scalable  
✅ **Clean Separation** - Domain independent of frameworks  
✅ **Testability** - Easy to unit test each layer  

---

## 🚀 Installation

### Prerequisites

- **Flutter SDK** 3.27.1 or higher
- **Dart** 3.6.0 or higher
- **Android Studio** / **Xcode** (for platform development)
- **Git**

### Quick Start

1. **Clone Repository**
   ```bash
   cd app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code** (BLoC, Dependency Injection)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run on Device/Emulator**
   ```bash
   # Android
   flutter run
   
   # iOS
   flutter run -d ios
   
   # Specific device
   flutter devices  # List devices
   flutter run -d <device-id>
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 📁 Project Structure

### Feature Module Example (Dashboard)

```
features/dashboard/
├── domain/
│   ├── entities/
│   │   ├── dashboard_data.dart      # Business entity
│   │   ├── metrics.dart
│   │   └── shop_info.dart
│   ├── repositories/
│   │   └── dashboard_repository.dart  # Abstract interface
│   └── usecases/
│       └── get_dashboard_data.dart    # Use case
│
├── data/
│   ├── models/
│   │   └── dashboard_model.dart       # JSON serializable
│   ├── datasources/
│   │   ├── dashboard_remote_datasource.dart
│   │   └── dashboard_local_datasource.dart
│   └── repositories/
│       └── dashboard_repository_impl.dart
│
└── presentation/
    ├── bloc/
    │   ├── dashboard_bloc.dart        # Business logic component
    │   ├── dashboard_event.dart       # Events
    │   └── dashboard_state.dart       # States
    ├── pages/
    │   ├── dashboard_page.dart        # Main screen
    │   └── analytics_page.dart
    └── widgets/
        ├── dashboard/
        │   ├── welcome_card.dart
        │   ├── metrics_grid.dart      # Responsive 2/3/4 columns
        │   └── sentiment_section.dart
        └── analytics/
            ├── period_filter_widget.dart
            ├── rating_distribution_chart.dart
            └── sentiment_pie_chart_widget.dart
```

---

## 🔄 State Management

### BLoC Pattern

**Why BLoC?**
- ✅ Predictable state transitions
- ✅ Easy to test and debug
- ✅ Separation of business logic from UI
- ✅ Built-in event handling
- ✅ Stream-based reactive programming

### BLoC Architecture

```dart
// Event
abstract class DashboardEvent extends Equatable {}

class LoadDashboard extends DashboardEvent {
  @override
  List<Object> get props => [];
}

// State
abstract class DashboardState extends Equatable {}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardData data;
  DashboardLoaded(this.data);
  @override
  List<Object> get props => [data];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardData getDashboardData;
  
  DashboardBloc(this.getDashboardData) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
  }
  
  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await getDashboardData();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (data) => emit(DashboardLoaded(data)),
    );
  }
}
```

### Usage in Widget

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const CircularProgressIndicator();
        }
        
        if (state is DashboardLoaded) {
          return DashboardContent(data: state.data);
        }
        
        return const ErrorView();
      },
    );
  }
}
```

---

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
    
  # State Management
  flutter_bloc: ^8.1.6          # BLoC pattern
  equatable: ^2.0.7             # Value equality
  
  # Dependency Injection
  get_it: ^8.0.3                # Service locator
  injectable: ^2.5.0            # DI code generation
  
  # Networking
  dio: ^5.7.0                   # HTTP client
  dartz: ^0.10.1                # Functional programming
  
  # UI Components
  flutter_svg: ^2.0.16          # SVG rendering
  cached_network_image: ^3.4.1  # Image caching
  fl_chart: ^0.70.2             # Charts library
  qr_flutter: ^4.1.0            # QR generation
  
  # Storage & Sharing
  shared_preferences: ^2.3.3    # Local storage
  share_plus: ^10.1.3           # Share functionality
  path_provider: ^2.1.5         # File paths
  gal: ^2.3.0                   # Save to gallery
  
  # Utilities
  intl: ^0.20.1                 # Internationalization & date formatting
  url_launcher: ^6.3.1          # URL handling
  permission_handler: ^11.3.1   # Permissions
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
    
  # Code Generation
  build_runner: ^2.4.14         # Build system
  injectable_generator: ^2.6.2  # DI generator
  
  # Linting
  flutter_lints: ^5.0.0         # Linting rules
```

---

## 🎨 UI Components

### Reusable Widgets

#### Core Widgets
- **ResponsiveScaffold** - Responsive app bar and scaffold
- **SectionCard** - Consistent card UI
- **ChartLegend** - Chart legend component
- **MetricCard** - Stat display card

#### Dashboard Widgets  
- **WelcomeCard** - Personalized greeting
- **MetricsGrid** - Responsive metrics layout (2/3/4 columns)
- **SentimentSection** - Sentiment analysis display

#### Analytics Widgets
- **PeriodFilterWidget** - Time period selector
- **RatingDistributionChart** - Bar chart for ratings
- **SentimentPieChartWidget** - Pie chart with legend

#### Reviews Widgets
- **ReviewCard** - Enhanced review card with:
  - Sentiment badges
  - Star ratings
  - Quality score
  - Warning ribbons (profane/flags)
  - Formatted date/time
- **ReviewDetailsDialog** - Full review details with:
  - Copyable email/phone
  - AI-generated insights
  - Quality warnings section
- **ReviewSearchBar** - Search functionality
- **SentimentHelpers** - Sentiment utilities

#### QR Widgets
- **QRDialog** - Standalone QR dialog
- **QRDisplayWidget** - QR code viewer
- **QRActionButtons** - Download/share buttons

---

## 🔧 Development

### Code Generation

**When to Run:**
- After modifying `@injectable` annotated classes
- After changing BLoC events/states
- When adding new dependencies

```bash
# Watch mode (auto-rebuild)
flutter pub run build_runner watch

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adding a New Feature

1. **Create Feature Directory**
   ```
   lib/features/new_feature/
   ├── domain/
   ├── data/
   └── presentation/
   ```

2. **Define Domain Layer**
   - Create entities
   - Define repository interface
   - Implement use cases

3. **Implement Data Layer**
   - Create models (with JSON serialization)
   - Implement data sources
   - Implement repository

4. **Build Presentation Layer**
   - Create BLoC (events, states, bloc)
   - Design pages and widgets

5. **Register Dependencies**
   ```dart
   @module
   abstract class NewFeatureModule {
     @lazySingleton
     NewFeatureRepository provideRepository(
       NewFeatureRemoteDataSource remoteDataSource,
     ) {
       return NewFeatureRepositoryImpl(remoteDataSource);
     }
   }
   ```

6. **Run Code Generation**

### Best Practices

✅ **Keep widgets small** - Single responsibility  
✅ **Extract reusable components** - DRY principle  
✅ **Use const constructors** - Performance optimization  
✅ **Handle all states** - Loading, success, error  
✅ **Add error boundaries** - Graceful degradation  
✅ **Write meaningful names** - Self-documenting code  
✅ **Comment complex logic** - Future maintainability  
✅ **Responsive design** - Test on multiple screen sizes

---

## 📱 Platform Specific

### Android

**Minimum SDK**: 21 (Android 5.0 Lollipop)  
**Target SDK**: 35 (Android 15)  

**Permissions** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS

**Minimum Version**: iOS 13.0  

**Info.plist** configuration:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save QR codes to your photo library</string>
```

---

## 🌐 API Integration

### Base URL Configuration

```dart
// lib/core/network/network_module.dart
@module
abstract class NetworkModule {
  @lazySingleton
  Dio provideDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://your-api-url.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return dio;
  }
}
```

### Authentication Flow

1. **Login** → Store JWT token
2. **Token Refresh** → Auto-refresh on 401
3. **Logout** → Clear stored credentials

---

## 🎯 Performance Optimization

### Techniques Used

1. **Widget Rebuilds** - Using `const` constructors
2. **List Performance** - ListView.builder for large lists
3. **Image Caching** - CachedNetworkImage
4. **Lazy Loading** - Pagination for reviews
5. **State Optimization** - Equatable for efficient comparisons
6. **Code Splitting** - Feature-based modules
7. **Smart Caching** - Cache → API → Generate flow for QR codes

### App Size

- **Android APK**: ~25-30 MB (release)
- **iOS App**: ~30-35 MB (release)

---

## 🐛 Troubleshooting

### Common Issues

**Build Errors After Pulling**:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependency Conflicts**:
```bash
flutter pub upgrade
```

**iOS Pod Issues**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

---

## 📚 Documentation

- [Main README](../README.md) - Project overview
- [Backend README](../backend/README.md) - API documentation  
- [Frontend README](../frontend/README.md) - Web dashboard

---

<a name="arabic-docs"></a>
## 🇸🇦 الدليل العربي

### التثبيت السريع

```bash
# تثبيت المكتبات
flutter pub get

# توليد الكود
flutter pub run build_runner build --delete-conflicting-outputs

# تشغيل التطبيق
flutter run
```

### الهيكل المعماري

التطبيق مبني على مبدأ **Clean Architecture** مع **BLoC Pattern**:

1. **Domain** - منطق الأعمال النقي
2. **Data** - طبقة البيانات و APIs
3. **Presentation** - واجهة المستخدم و BLoC

### المميزات الرئيسية

- 📊 **لوحة تحكم شاملة** - إحصائيات فورية مع شبكة متجاوبة (2/3/4 أعمدة)
- 📈 **تحليلات متقدمة** - رسوم بيانية تفاعلية
- 📝 **إدارة كاملة للتقييمات** - مع تحذيرات الجودة والمحتوى غير اللائق
- 📱 **QR Code محسّن**:
  - تدفق ذكي: Cache → API → توليد
  - حفظ مباشر في المعرض
  - مشاركة عبر التطبيقات
- ⚠️ **تحذيرات الجودة**:
  - محتوى غير لائق (شريط أحمر)
  - علامات الجودة (شريط برتقالي)
  - تحذيرات تفصيلية في صفحة التفاصيل
- 🔔 **تكامل Telegram** - للإشعارات
- 📱 **تصميم متجاوب** - يدعم RTL للعربية
- ⚡ **أداء عالي** - 60fps

### بناء التطبيق للإنتاج

```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release
```

---

<div align="center">

**Built with ❤️ using Flutter & Clean Architecture**

⭐ Star this repo if you find it useful!

</div>
