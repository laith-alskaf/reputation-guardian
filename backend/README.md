# 🔧 Reputation Guardian - Backend

<div align="center">

![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)
![Flask](https://img.shields.io/badge/Flask-3.1.2-green.svg)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blue.svg)

**Backend API built with Flask & Clean Architecture**

[العربية](#arabic-docs) | [English](#english)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Services](#services)
- [Database](#database)
- [Testing](#testing)

---

## 🌟 Overview

The backend is built using **Clean Architecture** principles with strict separation of concerns across 4 layers:

1. **Domain** - Business logic & entities (framework-independent)
2. **Application** - Use cases & orchestration
3. **Infrastructure** - External integrations (DB, APIs)
4. **Presentation** - HTTP layer (Flask routes)

---

## 🏗️ Architecture

### Layer Structure

```
app/
├── domain/                      # Layer 1: Pure Business Logic
│   ├── models/                  # Domain entities
│   │   ├── user.py              # User entity
│   │   ├── review.py            # Review entity (nested schema)
│   │   └── qr_code.py
│   ├── services_interfaces/     # Interfaces (DIP)
│   │   ├── i_notification_service.py
│   │   ├── i_telegram_service.py  # NEW
│   │   ├── i_sentiment_service.py
│   │   └── ...
│   └── enums/                   # Domain enums
│       └── shop_type.py
│
├── application/                 # Layer 2: Use Cases
│   ├── services/
│   │   ├── auth_service.py      # Authentication logic
│   │   ├── dashboard_service.py # Dashboard aggregation
│   │   ├── qr_service.py        # QR code generation
│   │   └── webhook_service.py   # Review processing orchestration
│   └── dto/                     # Data Transfer Objects
│       ├── review_processing_dto.py  # ReviewDocument
│       └── sentiment_analysis_result_dto.py
│
├── infrastructure/              # Layer 3: External Integrations
│   ├── database/
│   │   └── models/              # MongoDB models
│   ├── repositories/            # Data access layer
│   │   ├── user_repository.py
│   │   └── review_repository.py
│   └── external/                # Third-party services
│       ├── sentiment_service.py      # Hugging Face AI
│       ├── deepseek_service.py       # LLM for insights
│       ├── text_profanity_service.py # Toxicity detection
│       ├── telegram_service.py       # Rich Telegram messages ⭐
│       └── notification_service.py   # FCM & Telegram API
│
└── presentation/                # Layer 4: HTTP/API Layer
    ├── api/routes/              # REST endpoints
    │   ├── auth.py              # /api/auth/*
    │   ├── dashboard.py         # /api/dashboard
    │   ├── webhooks.py          # /webhook/*
    │   └── qr.py                # /api/qr/*
    ├── config/                  # App configuration
    │   ├── base.py              # BaseConfig class
    │   └── __init__.py          # Config loader
    └── utils/
        ├── middleware.py        # JWT auth, error handlers
        └── response_builder.py  # Standardized responses
```

### Design Principles

✅ **Dependency Inversion** - Layers depend on abstractions (interfaces)  
✅ **Single Responsibility** - Each module has one clear purpose  
✅ **Open/Closed** - Open for extension, closed for modification  
✅ **Interface Segregation** - Small, focused interfaces  
✅ **Testability** - Easy to unit test each layer independently  

---

## ✨ Features

### 🔐 Authentication & Authorization
- JWT-based authentication
- Bcrypt password hashing
- Token-based access control
- Shop-level data isolation

### 📊 Review Processing Pipeline

**1. Ingestion** (Webhook)
- Tally form webhook integration
- Digital signature verification
- Field extraction & validation

**2. Text Processing**
- Concatenation of multi-field text
- Profanity detection (mDeBERTa NLI)
- Quality scoring

**3. AI Analysis**
- Sentiment analysis (Arabic BERT)
- Category classification
- Key themes extraction
- Context matching (detect irrelevant reviews)

**4. Content Generation** (DeepSeek LLM)
- Automated summaries
- Actionable insights
- Suggested customer replies

**5. Storage & Notification**
- MongoDB with schema validation
- Telegram rich notifications
- FCM push (optional)

### 🤖 AI Services

#### SentimentService
- Model: `CAMeL-Lab/bert-base-arabic-camelbert-da-sentiment`
- Arabic sentiment classification
- Confidence scores

#### TextProfanityService
- Model: `MoritzLaurer/mDeBERTa-v3-base-mnli-xnli`
- Toxicity detection
- Profanity flagging

#### DeepSeekService
- LLM-powered content generation
- Context-aware responses
- JSON-structured outputs

#### TelegramService ⭐ NEW
- Rich message formatting with Markdown
- Quality score badges
- Phone & email display
- AI insights for negative reviews
- Warnings (profanity, mismatch, quality)
- Connection messages

---

## 🚀 Installation

### 1. Prerequisites

- Python 3.9 or higher
- pip package manager
- MongoDB Atlas account
- Hugging Face API token

### 2. Clone & Setup

```bash
# Clone repository
git clone <repo-url>
cd reputation-guardian/backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Mac/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Dependencies

```txt
flask==3.1.2              # Web framework
flask-cors==6.0.1         # CORS handling
pymongo==4.15.5           # MongoDB driver
pyjwt==2.10.1             # JWT tokens
qrcode[pil]==8.2          # QR generation
requests==2.32.5          # HTTP client
firebase-admin==7.1.0     # Push notifications
bcrypt==5.0.0             # Password hashing
python-dotenv==1.2.1      # Environment variables
pytz==2024.2              # Timezone handling
pydantic==2.10            # Data validation
```

---

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

**Required Variables**:

```bash
# MongoDB
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/db
DATABASE_NAME=reputation_guardian

# JWT
SECRET_KEY=your-super-secret-key-minimum-32-chars

# Hugging Face
HF_TOKEN=hf_xxxxxxxxxxxxx
HF_SENTIMENT_MODEL_URL=https://router.huggingface.co/models/...
HF_TOXICITY_MODEL_URL=https://router.huggingface.co/models/...

# DeepSeek
API_URL=https://api.deepseek.com/v1/...
MODEL_ID=deepseek-chat

# Tally
TALLY_FORM_URL=https://tally.so/r/xxxxx
SIGNING_SECRET=your-webhook-signing-secret

# Telegram (Optional)
TELEGRAM_TOKEN=123456:ABC-DEF...

# Firebase (Optional)
FIREBASE_JSON={"type":"service_account",...}

# Email (Optional)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=app-password

# Quality Gate
QUALITY_GATE_THRESHOLD=0.5
```

### Configuration Loading

Configuration is loaded hierarchically:

1. `.env` file (development)
2. Environment variables (production)
3. Default values (fallback)

See [`app/presentation/config/`](./app/presentation/config/) for details.

---

## 📡 API Endpoints

### Authentication

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "shop_id": "unique-shop-id",
  "shop_name": "My Shop",
  "shop_type": "product"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "email": "user@example.com",
      "shop_id": "unique-shop-id"
    }
  }
}
```

### Dashboard

#### Get Dashboard Data
```http
GET /api/dashboard
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "shop_info": {...},
    "metrics": {
      "total_reviews": 150,
      "average_rating": 4.2,
      "positive_percentage": 75
    },
    "reviews": {
      "processed": [...],
      "rejected_low_quality": [...],
      "rejected_irrelevant": [...]
    }
  }
}
```

### QR Codes

#### Generate QR Code
```http
POST /api/qr/generate
Authorization: Bearer {token}
Content-Type: application/json

{
  "size": 10
}
```

#### Get Latest QR
```http
GET /api/qr/latest
Authorization: Bearer {token}
```

### Webhooks

#### Tally Webhook (Review Submission)
```http
POST /webhook
Content-Type: application/json
Tally-Signature: sha256-base64-signature

{
  "eventId": "xxx",
  "eventType": "FORM_RESPONSE",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "data": {
    "responseId": "xxx",
    "submissionId": "xxx",
    "respondentId": "xxx",
    "formId": "xxx",
    "formName": "Customer Feedback",
    "createdAt": "2024-01-01T00:00:00.000Z",
    "fields": [...]
  }
}
```

#### Telegram Webhook
```http
POST /webhook/telegram
Content-Type: application/json

{
  "message": {
    "chat": {"id": 12345},
    "text": "/start user_id_encoded"
  }
}
```

---

## 🔧 Services

### WebhookService

**Responsibilities**:
- Process Tally webhooks
- Orchestrate review pipeline
- Quality gate filtering

**Pipeline**:
1. Extract form fields
2. Detect profanity
3. Perform sentiment analysis
4. Generate AI content (DeepSeek)
5. Apply quality gate
6. Store review
7. Send notification

### TelegramService ⭐

**Features**:
- Rich Markdown formatting
- Emoji indicators
- Quality scores & sentiments
- Customer info (email, phone)
- AI insights for negative reviews
- Warnings for problematic content

**Methods**:
- `send_review_notification(chat_id, review_doc)`
- `send_connection_success(chat_id)`
- `send_connection_error(chat_id)`
- `send_welcome_message(chat_id)`

See [TelegramService Walkthrough](../walkthrough.md) for examples.

---

## 💾 Database

### MongoDB Collections

#### `users`
```javascript
{
  _id: ObjectId,
  email: String,
  password_hash: String,  // bcrypt hashed
  shop_id: String (unique),
  shop_name: String,
  shop_type: String,
  telegram_chat_id: String? (optional),
  created_at: DateTime
}
```

#### `reviews` (Nested Schema)
```javascript
{
  _id: ObjectId,
  shop_id: String,
  email: String?,
  status: String  ("processed" | "rejected_low_quality" | "rejected_irrelevant"),
  
  source: {
    rating: Number (1-5),
    fields: Object  // Raw form fields
  },
  
  processing: {
    concatenated_text: String,
    is_profane: Boolean,
    profanity_scores: Object?
  },
  
  analysis: {
    sentiment: String ("إيجابي" | "سلبي" | "محايد"),
    category: String ("شكوى" | "اقتراح" | "مدح" | ...),
    key_themes: Array<String>,
    sentiment_scores: Object,
    quality: {
      quality_score: Number (0-1),
      is_suspicious: Boolean
    },
    context: {
      has_mismatch: Boolean,
      mismatch_reasons: Array<String>
    }
  },
  
  generated_content: {
    summary: String,
    actionable_insights: Array<String>,
    suggested_reply: String
  },
  
  created_at: DateTime,
  timestamp: DateTime
}
```

### Schema Migration

To update MongoDB schema validators:

```bash
python migrate_mongodb_schema.py
```

See [MIGRATION_README.md](./MIGRATION_README.md) for details.

---

## 🧪 Testing

### Manual Testing

1. **Start Server**:
   ```bash
   python run.py
   ```

2. **Test Auth**:
   ```bash
   # Register
   curl -X POST http://localhost:5000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123","shop_id":"shop1"}'
   
   # Login
   curl -X POST http://localhost:5000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123"}'
   ```

3. **Test Dashboard**:
   ```bash
   curl -X GET http://localhost:5000/api/dashboard \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

### Unit Tests (Coming Soon)

```bash
pytest tests/
```

---

## 📚 Documentation

- [Main README](../README.md) - Project overview
- [Frontend README](../frontend/README.md) - Frontend docs
- [MIGRATION_README](./MIGRATION_README.md) - Database migration
- [TelegramService Walkthrough](../walkthrough.md) - Notification system

---

## 🛠️ Development

### Project Structure Best Practices

1. **Never** modify domain entities to depend on infrastructure
2. **Always** use interfaces for external dependencies
3. **Keep** business logic in domain/application layers
4. **Separate** HTTP concerns from business logic
5. **Test** each layer independently

### Adding New Features

1. Define interface in `domain/services_interfaces/`
2. Implement in `infrastructure/external/`
3. Create use case in `application/services/`
4. Add route in `presentation/api/routes/`
5. Update dependency injection in `app/__init__.py`

---

## 🐛 Troubleshooting

### Common Issues

**MongoDB Connection Error**:
- Check `MONGO_URI` in `.env`
- Verify network access in MongoDB Atlas (whitelist IP)

**Hugging Face API Error**:
- Verify `HF_TOKEN` is valid
- Check API rate limits

**Telegram Not Working**:
- Verify `TELEGRAM_TOKEN`
- Set webhook URL: `https://api.telegram.org/bot{TOKEN}/setWebhook?url={YOUR_URL}/webhook/telegram`

---

<a name="arabic-docs"></a>
## 🇸🇦 الدليل العربي

### التثبيت السريع

```bash
# تثبيت المتطلبات
pip install -r requirements.txt

# نسخ ملف البيئة
cp .env.example .env

# تشغيل الترحيل
python migrate_mongodb_schema.py

# تشغيل السيرفر
python run.py
```

### الهيكل المعماري

المشروع مبني على مبدأ **Clean Architecture** مع 4 طبقات:
1. **Domain** - منطق الأعمال
2. **Application** - حالات الاستخدام
3. **Infrastructure** - التكاملات الخارجية
4. **Presentation** - API Routes

---

<div align="center">

**Built with ❤️ using Clean Architecture**

</div>
