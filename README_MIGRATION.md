# HARS AL-SAMA Database Migration Guide

## نظرة عامة
هذا الدليل يوضح كيفية إعداد قاعدة البيانات MongoDB لمشروع "حارس السمعة" باستخدام migration script احترافي.

## المتطلبات الأساسية

### 1. MongoDB Atlas Account
- إنشاء حساب مجاني على [MongoDB Atlas](https://www.mongodb.com/atlas)
- إنشاء cluster جديد (M0 tier مجاني)
- الحصول على connection string

### 2. Environment Variables
تأكد من وجود ملف `.env` في مجلد `backend` مع المتغيرات التالية:

```env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/haris_samaa
DATABASE_NAME=haris_samaa
```

## تشغيل المigration

### الأوامر المتاحة:

```bash
# تشغيل migration أساسي
python migration.py run

# تشغيل مع بيانات تجريبية
python migration.py run --sample

# إعادة إنشاء الجداول (حذف وإنشاء جديد)
python migration.py run --reset

# إعادة إنشاء مع بيانات تجريبية
python migration.py run --sample --reset
```

### مثال على التشغيل:

```bash
cd backend
python migration.py run --sample
```

## ما يقوم به المigration

### 1. إنشاء Collections:

#### `users` Collection:
- **الحقول المطلوبة**: `email`, `password`, `shop_name`, `shop_type`
- **Validation**: البريد الإلكتروني صحيح، كلمة المرور ≥6 أحرف
- **Indexes**:
  - `email` (unique)
  - `shop_type`
  - `created_at`
  - `shop_name` (text search)

#### `reviews` Collection:
- **الحقول المطلوبة**: `id`, `email`, `shop_id`, `stars`, `overall_sentiment`
- **Validation**: stars (1-5), sentiment من القائمة المحددة
- **Indexes**:
  - `shop_id + email` (unique compound)
  - `shop_id`, `email`, `overall_sentiment`, `stars`
  - `timestamp` (descending)
  - `organized_feedback` (text search)

#### `qr_codes` Collection:
- **الحقول المطلوبة**: `shop_id`, `qr_code`, `shop_type`, `created_at`
- **Indexes**:
  - `shop_id` (unique)
  - `is_active`
  - `created_at`

### 2. البيانات التجريبية (`--sample`):

```json
// Sample User
{
  "email": "sample@haris-sama.com",
  "shop_name": "مطعم الحارس",
  "shop_type": "مطعم",
  "password": "hashed_password"
}

// Sample Reviews
[
  {
    "stars": 5,
    "overall_sentiment": "إيجابي",
    "organized_feedback": "الأطباق لذيذة والخدمة ممتازة"
  },
  {
    "stars": 2,
    "overall_sentiment": "سلبي",
    "organized_feedback": "الانتظار طويل والأسعار مرتفعة",
    "solutions": "تحسين سرعة الخدمة ومراجعة الأسعار"
  }
]
```

## التحقق من نجاح المigration

### 1. فحص الـ Logs:
```
2025-12-05 21:10:27 - INFO - Successfully connected to MongoDB
2025-12-05 21:10:27 - INFO - Using database: haris_samaa
2025-12-05 21:10:27 - INFO - Created users collection
2025-12-05 21:10:27 - INFO - Applied validation rules to users
2025-12-05 21:10:27 - INFO - Created index: email_unique
2025-12-05 21:10:27 - INFO - ✅ Migration completed successfully!
```

### 2. فحص قاعدة البيانات في MongoDB Atlas:
- انتقل إلى Collections في لوحة التحكم
- تأكد من وجود الـ 3 collections
- فحص البيانات التجريبية إذا استخدمت `--sample`

### 3. اختبار التطبيق:
```bash
# تشغيل الخادم
python app.py

# في Postman أو المتصفح
POST http://localhost:5000/register
{
  "email": "test@example.com",
  "password": "password123",
  "shop_name": "متجر تجريبي",
  "shop_type": "مطعم"
}
```

## استكشاف الأخطاء

### خطأ Connection:
```
ServerSelectionTimeoutError: SSL handshake failed
```
**الحل**: تحقق من `MONGO_URI` في ملف `.env`

### خطأ Validation:
```
Document failed validation
```
**الحل**: البيانات لا تطابق قواعد التحقق، راجع الـ schema

### خطأ Index:
```
Index already exists
```
**الحل**: استخدم `--reset` لإعادة إنشاء الجداول

## الأمان والأداء

### Validation Rules:
- منع البيانات غير الصحيحة من الدخول
- ضمان سلامة البيانات
- حماية من SQL injection (غير مطلوب في MongoDB لكن جيد)

### Indexes:
- تسريع الاستعلامات
- منع التكرارات
- تحسين الأداء

### Best Practices:
- لا تشارك `MONGO_URI` علناً
- استخدم متغيرات البيئة
- احتفظ بنسخة احتياطية من البيانات

## إدارة قاعدة البيانات

### عرض البيانات:
```javascript
// في MongoDB Compass أو Shell
use haris_samaa
db.users.find()
db.reviews.find()
db.qr_codes.find()
```

### حذف البيانات (للتطوير):
```bash
python migration.py run --reset
```

### إضافة Migration جديد:
```python
# في migration.py
def new_migration_feature(self):
    # أضف الكود هنا
    pass
```

## الدعم والمساعدة

إذا واجهت مشاكل:
1. تحقق من الـ logs في `migration.log`
2. تأكد من صحة متغيرات البيئة
3. تحقق من اتصال الإنترنت
4. راجع إعدادات MongoDB Atlas

---

**تم إنشاء هذا المigration بواسطة HARS AL-SAMA Team** 🛡️
