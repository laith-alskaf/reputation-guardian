# 🛡️ Reputation Guardian

<div align="center">

![Reputation Guardian](https://img.shields.io/badge/Version-1.0.0-blue.svg)
![Python](https://img.shields.io/badge/Python-3.9+-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success.svg)

**نظام ذكي متقدم لإدارة وتحليل تقييمات العملاء باستخدام الذكاء الاصطناعي**

[English](#english) | [العربية](#arabic)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**Reputation Guardian** is an intelligent review management system that leverages AI to automatically analyze, categorize, and respond to customer reviews. Built with a clean architecture approach, it provides real-time insights, sentiment analysis, and automated quality control.

### Why Reputation Guardian?

- 🤖 **AI-Powered Analysis**: Advanced sentiment analysis and text processing
- 📊 **Real-time Insights**: Instant quality scoring and categorization  
- 🔔 **Smart Notifications**: Rich Telegram notifications with actionable insights
- 🛡️ **Quality Control**: Automated detection of spam, profanity, and low-quality reviews
- 📱 **Responsive Dashboard**: Beautiful, mobile-first UI for managing reviews
- 🌐 **Multi-language**: Full Arabic language support with RTL design

---

## ✨ Key Features

### 🎯 Core Functionality

- **Automated Review Processing**
  - Webhook integration with Tally forms
  - Real-time review ingestion and validation
  - Automatic sentiment and quality analysis
  
- **AI-Powered Analysis**
  - Sentiment classification (Positive/Negative/Neutral)
  - Category detection (Complaint, Suggestion, Praise, etc.)
  - Key themes extraction
  - Quality scoring (0-100%)
  - Profanity and toxicity detection
  - Context matching (detect irrelevant reviews)

- **Smart Content Generation**
  - AI-generated summaries
  - Actionable insights for improvement
  - Suggested customer replies
  - Personalized recommendations

### 📊 Dashboard Features

- **Metrics Visualization**
  - Total reviews count
  - Average rating
  - Sentiment distribution charts
  - Quality trends

- **Advanced Filtering**
  - by sentiment, category, rating, date range
  - By quality score
  - Context match filtering

- **Review Management**
  - Accept/Reject workflow
  - Quality-based auto-filtering
  - Export to CSV/JSON
  - Print-friendly reports

### 🔔 Notifications

- **Telegram Integration**
  - Rich formatted messages with Markdown
  - Quality score and sentiment indicators
  - Phone and email display
  - AI insights for negative reviews
  - Warnings for problematic reviews
  - Direct dashboard links

- **FCM Push Notifications** (Optional)
  - Mobile app integration ready
  - Real-time alerts

### 🔐 Security & Quality

- Digital signature verification (Tally webhooks)
- JWT-based authentication
- MongoDB schema validation
- Input sanitization and validation
- Rate limiting and error handling
- Comprehensive logging

---

## 🏗️ Architecture

### Backend - Clean Architecture

```
app/
├── domain/              # Business logic & entities
│   ├── models/          # Domain entities
│   ├── services_interfaces/  # Interfaces (DIP)
│   └── enums/           # Domain enums
│
├── application/         # Use cases & orchestration
│   ├── services/        # Application services
│   └── dto/             # Data Transfer Objects
│
├── infrastructure/      # External concerns
│   ├── database/        # MongoDB models
│   ├── repositories/    # Data access
│   └── external/        # Third-party services
│       ├── sentiment_service.py
│       ├── deepseek_service.py
│       ├── telegram_service.py  # NEW
│       └── notification_service.py
│
└── presentation/        # API & routes
    ├── api/routes/      # REST endpoints
    ├── config/          # Configuration
    └── utils/           # Middleware, helpers
```

**Design Principles**:
- ✅ Dependency Inversion Principle (DIP)
- ✅ Single Responsibility Principle (SRP)
- ✅ Clean separation of concerns
- ✅ Testable and maintainable code

### Frontend - Responsive SPA

- Vanilla JavaScript (ES6+)
- Mobile-first responsive design
- Component-based architecture
- Real-time data updates
- Chart.js for visualizations

### Mobile App - Flutter ⭐ NEW

- **Flutter 3.27.1** with Dart 3.6.0
- **Clean Architecture** (Domain/Data/Presentation)
- **BLoC Pattern** for state management
- **Dependency Injection** (get_it + injectable)
- Native Android & iOS support
- RTL support for Arabic
- Offline-first with local caching

---

## 🛠️ Tech Stack

### Backend

| Technology | Purpose |
|------------|---------|
| **Python 3.9+** | Core language |
| **Flask** | Web framework |
| **MongoDB** | Database (Atlas) |
| **PyMongo** | MongoDB driver |
| **Hugging Face** | AI models (sentiment, toxicity) |
| **DeepSeek** | LLM for content generation |
| **Firebase** | Push notifications (optional) |
| **JWT** | Authentication |
| **Bcrypt** | Password hashing |

### Frontend

| Technology | Purpose |
|------------|---------|
| **HTML5/CSS3** | Structure & styling |
| **JavaScript (ES6+)** | Logic & interactivity |
| **Chart.js** | Data visualization |
| **Marked.js** | Markdown parsing |
| **DOMPurify.js** | XSS protection |
| **Font Awesome** | Icons |

### Mobile (Flutter)

| Technology | Purpose |
|------------|---------|
| **Flutter 3.27+** | Cross-platform framework |
| **Dart 3.6+** | Programming language |
| **BLoC Pattern** | State management |
| **Dio** | HTTP client |
| **GetIt** | Dependency injection |
| **FL Chart** | Data visualization |
| **QR Flutter** | QR code generation |
| **Shared Preferences** | Local storage |

### External Services

- **Tally.so** - Form builder & webhook source
- **Telegram Bot API** - Notifications
- **Hugging Face Inference API** - AI models
- **MongoDB Atlas** - Cloud database

---

## 🚀 Getting Started

### Prerequisites

- Python 3.9 or higher
- MongoDB Atlas account (free tier works)
- Hugging Face API token
- Telegram Bot token (optional)
- Node.js (for frontend dependencies, optional)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd reputation-guardian
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Database Migration**
   ```bash
   python migrate_mongodb_schema.py
   ```

5. **Run Backend**
   ```bash
   python run.py
   ```

6. **Frontend Setup**
   ```bash
   cd ../frontend
   # Open index.html or dashboard.html in browser
   # Or use a local server:
   python -m http.server 8000
   ```

7. **Access Application**
   - Backend API: `http://localhost:5000`
   - Frontend: `http://localhost:8000`

7. **Mobile App Setup** (Optional)
   ```bash
   cd app
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run
   ```

8. **Access Application**
   - Backend API: `http://localhost:5000`
   - Web Dashboard: `http://localhost:8000`
   - Mobile App: On connected device/emulator

### Detailed Setup

See [Backend README](./backend/README.md), [Frontend README](./frontend/README.md), and [App README](./app/README.md) for detailed instructions.

---

## 📁 Project Structure

```
reputation-guardian/
├── backend/                 # Python Flask backend
│   ├── app/
│   │   ├── domain/          # Business logic
│   │   ├── application/     # Use cases
│   │   ├── infrastructure/  # Data & external
│   │   └── presentation/    # API routes
│   ├── migrate_mongodb_schema.py
│   ├── run.py
│   ├── requirements.txt
│   └── README.md
│
├── frontend/                # Vanilla JS frontend
│   ├── css/
│   │   ├── style.css
│   │   └── schema-enhancements.css
│   ├── js/
│   │   ├── dashboard.js
│   │   ├── api.js
│   │   └── ui.js
│   ├── index.html
│   ├── dashboard.html
│   └── README.md
│
├── app/                     # Flutter mobile app ⭐ NEW
│   ├── lib/
│   │   ├── core/            # Shared utilities
│   │   ├── features/        # Feature modules
│   │   │   ├── auth/        # Authentication
│   │   │   ├── dashboard/   # Dashboard
│   │   │   ├── reviews/     # Reviews management
│   │   │   ├── qr/          # QR generation
│   │   │   └── settings/    # Settings
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── README.md
│
└── README.md               # This file
```

---

## 📚 Documentation

### API Documentation

- [API Endpoints](./backend/README.md#api-endpoints)
- [Authentication](./backend/README.md#authentication)
- [Webhook Integration](./backend/README.md#webhooks)

### Development Guides

- [Backend Development](./backend/README.md)
- [Frontend Development](./frontend/README.md)
- [Database Schema](./backend/MIGRATION_README.md)
- [TelegramService Guide](./backend/docs/telegram-service.md)

### Recent Updates

- ✅ **v1.0.0** - TelegramService with rich formatting
- ✅ **v0.9.0** - Frontend responsive redesign
- ✅ **v0.8.0** - MongoDB schema migration
- ✅ **v0.7.0** - DeepSeek integration for AI content

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- **Backend**: Follow PEP 8
- **Frontend**: Use ESLint with standard config
- Write clear commit messages
- Add tests for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Lead Developer**: Laith Alskaf


---

## 🙏 Acknowledgments

- [Hugging Face](https://huggingface.co) for AI models
- [DeepSeek](https://deepseek.com) for LLM capabilities
- [MongoDB](https://mongodb.com) for database
- [Tally.so](https://tally.so) for form integration
- Open source community for amazing tools

---

## 📞 Support

- 📧 Email: laithalskaf@gmail.com
- 💬 Telegram: [@YourBot](https://t.me/YourBot)
- 🐛 Issues: [GitHub Issues](issues)

---

<div align="center">

**Built with ❤️ using AI & Clean Architecture**

⭐ Star this repo if you find it useful!

</div>

---

<a name="arabic"></a>
##  نسخة عربية

للمزيد من التفاصيل باللغة العربية، راجع:
- [دليل الباك إند](./backend/README.md)
- [دليل الفرونت إند](./frontend/README.md)
