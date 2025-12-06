#!/usr/bin/env python3
"""
HARS AL-SAMA Database Migration Script - النسخة المصححة
"""

import os
import sys
import io
import logging
from datetime import datetime
from pymongo import MongoClient, ASCENDING, DESCENDING, TEXT
from pymongo.errors import OperationFailure, ServerSelectionTimeoutError
from bson import ObjectId
from dotenv import load_dotenv

# 🔧 إصلاح مشكلة ترميز Unicode في Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# تكوين التسجيل
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('migration.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class DatabaseMigration:
    """
    فئة هجرة قاعدة البيانات المحترفة لـ HARS AL-SAMA
    """

    def __init__(self):
        self.client = None
        self.db = None
        self.connect_to_database()

    def connect_to_database(self):
        """إنشاء اتصال قاعدة البيانات"""
        try:
            mongo_uri = os.environ.get('MONGO_URI')
            if not mongo_uri:
                raise ValueError("MONGO_URI environment variable not set")

            self.client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
            # اختبار الاتصال
            self.client.admin.command('ping')
            logger.info("Successfully connected to MongoDB")

            db_name = os.environ.get('DATABASE_NAME', 'haris_samaa')
            self.db = self.client[db_name]
            logger.info(f"Using database: {db_name}")

        except ServerSelectionTimeoutError:
            logger.error("Cannot connect to MongoDB server")
            sys.exit(1)
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            sys.exit(1)

    def create_collections(self):
        """إنشاء المجموعات مع قواعد التحقق"""
        logger.info("Creating collections...")

        # مجموعة المستخدمين
        self.create_users_collection()

        # مجموعة التقييمات
        self.create_reviews_collection()

        # مجموعة رموز QR
        self.create_qr_codes_collection()

        logger.info("All collections created successfully")

    def create_users_collection(self):
        """إنشاء مجموعة المستخدمين مع التحقق"""
        collection_name = 'users'

        # حذف المجموعة الموجودة إذا طُلب إعادة التعيين
        if '--reset' in sys.argv:
            self.db[collection_name].drop()
            logger.info(f"Dropped existing {collection_name} collection")

        # إنشاء المجموعة
        try:
            self.db.create_collection(collection_name)
            logger.info(f"Created {collection_name} collection")
        except Exception as e:
            if 'already exists' not in str(e):
                logger.warning(f"Collection {collection_name} might already exist: {e}")

        # قواعد التحقق للمستخدمين
        validation_rules = {
            '$jsonSchema': {
                'bsonType': 'object',
                'required': ['email', 'password', 'shop_name'],
                'properties': {
                    'email': {
                        'bsonType': 'string',
                        'pattern': '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$',
                        'description': 'Must be a valid email address'
                    },
                    'password': {
                        'bsonType': ['string', 'binData'],
                        'description': 'Password hash (string or binary data)'
                    },
                    'shop_name': {
                        'bsonType': 'string',
                        'minLength': 2,
                        'maxLength': 100,
                        'description': 'Shop name must be 2-100 characters'
                    },
                    'shop_type': {
                        'enum': [
                            "مطعم", "مقهى", "محل ملابس", "صيدلية", "سوبر ماركت",
                            "متجر إلكترونيات", "مكتبة", "محل تجميل", "صالة رياضية",
                            "مدرسة/روضة", "مستشفى/عيادة", "محطة وقود", "متجر أجهزة",
                            "محل ألعاب", "مكتب سياحي", "محل هدايا", "مغسلة ملابس",
                            "متجر هواتف", "محل أثاث", "آخر"
                        ],
                        'description': 'Must be a valid shop type'
                    },
                    'qr_code': {
                        'bsonType': 'string',
                        'description': 'Base64 encoded QR code'
                    },
                    'device_token': {
                        'bsonType': 'string',
                        'description': 'Firebase device token for notifications'
                    },
                    'created_at': {
                        'bsonType': 'date',
                        'description': 'Account creation timestamp'
                    },
                    'qr_updated_at': {
                        'bsonType': 'date',
                        'description': 'Last QR code update timestamp'
                    }
                }
            }
        }

        # تطبيق قواعد التحقق
        try:
            self.db.command({
                'collMod': collection_name,
                'validator': validation_rules,
                'validationLevel': 'moderate'
            })
            logger.info(f"Applied validation rules to {collection_name}")
        except Exception as e:
            logger.warning(f"Could not apply validation to {collection_name}: {e}")

        # إنشاء الفهارس
        self.create_users_indexes(collection_name)

    def create_users_indexes(self, collection_name):
        """إنشاء فهارس لمجموعة المستخدمين"""
        collection = self.db[collection_name]

        indexes = [
            # فهرس البريد الإلكتروني الفريد
            ('email', ASCENDING, {'unique': True, 'name': 'email_unique'}),
            # فهرس نوع المتجر للتصفية
            ('shop_type', ASCENDING, {'name': 'shop_type_index'}),
            # فهرس تاريخ الإنشاء
            ('created_at', DESCENDING, {'name': 'created_at_index'}),
            # فهرس نصي للبحث
            ('shop_name', TEXT, {'name': 'shop_name_text'})
        ]

        for field, direction, options in indexes:
            try:
                if isinstance(field, str):
                    collection.create_index([(field, direction)], **options)
                else:
                    collection.create_index(field, **options)
                logger.info(f"Created index: {options.get('name', field)}")
            except Exception as e:
                logger.warning(f"Could not create index {options.get('name', field)}: {e}")

    def create_reviews_collection(self):
        """إنشاء مجموعة التقييمات مع التحقق"""
        collection_name = 'reviews'

        # حذف المجموعة الموجودة إذا طُلب إعادة التعيين
        if '--reset' in sys.argv:
            self.db[collection_name].drop()
            logger.info(f"Dropped existing {collection_name} collection")

        # إنشاء المجموعة
        try:
            self.db.create_collection(collection_name)
            logger.info(f"Created {collection_name} collection")
        except Exception as e:
            if 'already exists' not in str(e):
                logger.warning(f"Collection {collection_name} might already exist: {e}")

        # قواعد التحقق للتقييمات
        validation_rules = {
            '$jsonSchema': {
                'bsonType': 'object',
                'required': ['id', 'email', 'shop_id', 'stars', 'overall_sentiment'],
                'properties': {
                    'id': {
                        'bsonType': 'string',
                        'description': 'Unique review identifier'
                    },
                    'email': {
                        'bsonType': 'string',
                        'pattern': '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$',
                        'description': 'Customer email'
                    },
                    'shop_id': {
                        'bsonType': 'string',
                        'description': 'Shop identifier'
                    },
                    'stars': {
                        'bsonType': 'int',
                        'minimum': 1,
                        'maximum': 5,
                        'description': 'Rating stars (1-5)'
                    },
                    'overall_sentiment': {
                        'enum': ['إيجابي', 'سلبي', 'محايد'],
                        'description': 'Overall sentiment analysis'
                    },
                    'organized_feedback': {
                        'bsonType': 'string',
                        'description': 'AI-organized customer feedback'
                    },
                    'solutions': {
                        'bsonType': 'string',
                        'description': 'AI-generated solutions for negative reviews'
                    },
                    'timestamp': {
                        'bsonType': 'date',
                        'description': 'Review submission timestamp'
                    }
                }
            }
        }

        # تطبيق قواعد التحقق
        try:
            self.db.command({
                'collMod': collection_name,
                'validator': validation_rules,
                'validationLevel': 'moderate'
            })
            logger.info(f"Applied validation rules to {collection_name}")
        except Exception as e:
            logger.warning(f"Could not apply validation to {collection_name}: {e}")

        # إنشاء الفهارس
        self.create_reviews_indexes(collection_name)

    def create_reviews_indexes(self, collection_name):
        """إنشاء فهارس لمجموعة التقييمات"""
        collection = self.db[collection_name]

        indexes = [
            # الفهرس المركب للمتجر والبريد الإلكتروني (يمنع التكرارات)
            ([('shop_id', ASCENDING), ('email', ASCENDING)], 
             {'unique': True, 'name': 'shop_email_unique'}),
            
            # فهرس معرف المتجر للتصفية
            ([('shop_id', ASCENDING)], {'name': 'shop_id_index'}),
            
            # فهرس البريد الإلكتروني
            ([('email', ASCENDING)], {'name': 'email_index'}),
            
            # فهرس المشاعر
            ([('overall_sentiment', ASCENDING)], {'name': 'sentiment_index'}),
            
            # فهرس النجوم
            ([('stars', ASCENDING)], {'name': 'stars_index'}),
            
            # فهرس الطابع الزمني للترتيب
            ([('timestamp', DESCENDING)], {'name': 'timestamp_desc'}),
            
            # فهرس نصي للبحث في الملاحظات
            ([('organized_feedback', TEXT)], {'name': 'feedback_text'})
        ]

        for index_def, options in indexes:
            try:
                collection.create_index(index_def, **options)
                logger.info(f"Created index: {options.get('name', str(index_def))}")
            except Exception as e:
                logger.warning(f"Could not create index {options.get('name', str(index_def))}: {e}")

    def create_qr_codes_collection(self):
        """إنشاء مجموعة رموز QR"""
        collection_name = 'qr_codes'

        # حذف المجموعة الموجودة إذا طُلب إعادة التعيين
        if '--reset' in sys.argv:
            self.db[collection_name].drop()
            logger.info(f"Dropped existing {collection_name} collection")

        # إنشاء المجموعة
        try:
            self.db.create_collection(collection_name)
            logger.info(f"Created {collection_name} collection")
        except Exception as e:
            if 'already exists' not in str(e):
                logger.warning(f"Collection {collection_name} might already exist: {e}")

        # قواعد التحقق
        validation_rules = {
            '$jsonSchema': {
                'bsonType': 'object',
                'required': ['shop_id', 'qr_code', 'created_at'],
                'properties': {
                    'shop_id': {
                        'bsonType': 'string',
                        'description': 'Shop identifier'
                    },
                    'qr_code': {
                        'bsonType': 'string',
                        'description': 'Base64 encoded QR code'
                    },
                    'shop_type': {
                        'bsonType': 'string',
                        'description': 'Shop type'
                    },
                    'is_active': {
                        'bsonType': 'bool',
                        'description': 'QR code active status'
                    },
                    'created_at': {
                        'bsonType': 'date',
                        'description': 'QR creation timestamp'
                    },
                    'expires_at': {
                        'bsonType': 'date',
                        'description': 'QR expiration date'
                    }
                }
            }
        }

        # تطبيق قواعد التحقق
        try:
            self.db.command({
                'collMod': collection_name,
                'validator': validation_rules,
                'validationLevel': 'moderate'
            })
            logger.info(f"Applied validation rules to {collection_name}")
        except Exception as e:
            logger.warning(f"Could not apply validation to {collection_name}: {e}")

        # إنشاء الفهارس
        collection = self.db[collection_name]
        try:
            collection.create_index([('shop_id', ASCENDING)], unique=True, name='shop_id_unique')
            collection.create_index([('is_active', ASCENDING)], name='active_index')
            collection.create_index([('created_at', DESCENDING)], name='created_desc')
            logger.info("Created QR codes indexes")
        except Exception as e:
            logger.warning(f"Could not create QR codes indexes: {e}")

    def insert_sample_data(self):
        """إدراج بيانات نموذجية للاختبار"""
        logger.info("Inserting sample data...")

        try:
            # مستخدم نموذجي
            sample_user = {
                "_id": ObjectId(),
                "email": "sample@haris-sama.com",
                "password": "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeHRrJzXe/9YHnUy",  # "password123"
                "shop_name": "مطعم الحارس",
                "shop_type": "مطعم",
                "device_token": "sample_device_token",
                "created_at": datetime.utcnow()
            }

            result = self.db.users.insert_one(sample_user)
            logger.info(f"Inserted sample user with ID: {result.inserted_id}")

            # تقييمات نموذجية
            sample_reviews = [
                {
                    "id": str(ObjectId()),
                    "email": "customer1@example.com",
                    "shop_id": str(result.inserted_id),
                    "stars": 5,
                    "overall_sentiment": "إيجابي",
                    "organized_feedback": "الأطباق لذيذة والخدمة ممتازة",
                    "solutions": "",
                    "original_fields": {
                        "text": "طعام رائع وخدمة سريعة",
                        "enjoy_most": "الجودة العالية",
                        "improve_product": "",
                        "additional_feedback": "أنصح الجميع بزيارة المطعم"
                    },
                    "timestamp": datetime.utcnow()
                },
                {
                    "id": str(ObjectId()),
                    "email": "customer2@example.com",
                    "shop_id": str(result.inserted_id),
                    "stars": 2,
                    "overall_sentiment": "سلبي",
                    "organized_feedback": "الانتظار طويل والأسعار مرتفعة",
                    "solutions": "تحسين سرعة الخدمة ومراجعة الأسعار",
                    "original_fields": {
                        "text": "انتظرت ساعة للطعام",
                        "enjoy_most": "",
                        "improve_product": "تقليل وقت الانتظار",
                        "additional_feedback": "الأسعار غالية جداً"
                    },
                    "timestamp": datetime.utcnow()
                }
            ]

            result = self.db.reviews.insert_many(sample_reviews)
            logger.info(f"Inserted {len(result.inserted_ids)} sample reviews")

        except Exception as e:
            logger.error(f"Failed to insert sample data: {e}")

    def run_migration(self):
        """تشغيل الهجرة الكاملة"""
        logger.info("Starting HARS AL-SAMA database migration...")

        try:
            # إنشاء المجموعات
            self.create_collections()

            # إدراج بيانات نموذجية إذا طُلب ذلك
            if '--sample' in sys.argv:
                self.insert_sample_data()
            self.insert_sample_data()
            logger.info("Migration completed successfully!")

        except Exception as e:
            logger.error(f"Migration failed: {e}")
            sys.exit(1)
        finally:
            if self.client:
                self.client.close()

def main():
    """دالة الهجرة الرئيسية"""
    # تحميل متغيرات البيئة من المجلد الأب
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    load_dotenv(env_path)
    logger.info(f"Loaded environment from: {env_path}")

    if len(sys.argv) < 2:
        print("""
HARS AL-SAMA Database Migration Tool

Usage:
    python migration.py run                    # Run migration
    python migration.py run --sample          # Run with sample data
    python migration.py run --reset           # Force reset collections
    python migration.py run --sample --reset  # Reset and add sample data

Environment Variables Required:
    MONGO_URI       - MongoDB connection string
    DATABASE_NAME   - Database name (default: haris_samaa)

Make sure to set your environment variables in .env file
        """)
        sys.exit(1)

    if sys.argv[1] == 'run':
        migration = DatabaseMigration()
        migration.run_migration()
    else:
        print("Invalid command. Use 'run' to execute migration.")
        sys.exit(1)

if __name__ == '__main__':
    main()
