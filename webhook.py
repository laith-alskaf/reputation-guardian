# from flask import Flask, request, jsonify
# from mongo_connection import connect_to_mongodb
# from sentiment_analysis import clean_text, analyze_sentiment, analyze_toxicity, classify_review, detect_review_quality
# from deepseek_integration import organize_customer_feedback, determine_overall_sentiment
# from notifications import initialize_firebase, send_fcm_notification, send_telegram_notification
# import datetime
# from datetime import timezone
# from config import SECRET_KEY
# import logging
# from bson import ObjectId

# app = Flask(__name__)

# db = connect_to_mongodb()
# # if not db:
# #     logging.error("Failed to connect to MongoDB")
# #     exit(1)

# users = db['users']
# reviews = db['reviews']

# initialize_firebase()

# @app.route('/')
# def health():
#     return jsonify({"status": "حارس السمعة يعمل بكفاءة 🛡️", "version": "2.0"}), 200

# @app.route('/webhook', methods=['POST'])
# def webhook():
#     try:
#         data = request.json
#         if not data or not data.get('fields'):
#             logging.warning("Invalid webhook data received")
#             return jsonify({"error": "Invalid data"}), 400

#         fields = data['fields']
#         email = fields.get('email', '').strip().lower()
#         text = fields.get('text', '').strip()
#         shop_id = fields.get('shop_id', '').strip()
#         stars = int(fields.get('stars', 0)) if fields.get('stars') else 0

#         # الحقول الجديدة
#         enjoy_most = fields.get('enjoy_most', '').strip()
#         improve_product = fields.get('improve_product', '').strip()
#         additional_feedback = fields.get('additional_feedback', '').strip()

#         if not email or not text or not shop_id:
#             logging.warning(f"Missing required fields: email={bool(email)}, text={bool(text)}, shop_id={bool(shop_id)}")
#             return jsonify({"error": "Missing required fields: email, text, shop_id"}), 400

#         # التحقق من عدم وجود تقييم سابق بنفس البريد الإلكتروني لنفس المتجر
#         existing_review = reviews.find_one({"email": email, "shop_id": shop_id})
#         if existing_review:
#             logging.warning(f"Duplicate review attempt from {email} for shop {shop_id}")
#             return jsonify({"error": "لقد قمت بإرسال تقييم لهذا المتجر مسبقاً"}), 400

#         # التحقق من نوع المتجر من قاعدة البيانات
#         owner = users.find_one({"_id": ObjectId(shop_id)})
#         shop_type = owner.get('shop_type', 'عام') if owner else 'عام'

#         # تحليل المشاعر للتقييم العام
#         cleaned_text = clean_text(text)
#         sentiment = analyze_sentiment(cleaned_text)
#         toxicity = analyze_toxicity(cleaned_text)
#         review_type = classify_review(sentiment, toxicity)

#         # تحديد المشاعر العامة
#         overall_sentiment = determine_overall_sentiment(stars, text, improve_product, additional_feedback)

#         # فحص جودة التقييم وتسجيلها في log
#         quality_check = detect_review_quality(text, enjoy_most, improve_product, additional_feedback)
#         if quality_check['is_suspicious']:
#             logging.warning(f"Suspicious review detected from {email}: quality_score={quality_check['quality_score']}, flags={quality_check['flags']}")

#         # تنظيم إجابات العميل باستخدام DeepSeek
#         organized_feedback = organize_customer_feedback(enjoy_most, improve_product, additional_feedback)

#         # توليد حلول إذا كان سلبي
#         solutions = ""
#         if overall_sentiment == "سلبي" or review_type in ['شكوى', 'نقد']:
#             # يمكن إضافة منطق لتوليد حلول هنا إذا لزم الأمر
#             solutions = f"بناءً على التقييم السلبي والاقتراحات المقدمة، يُنصح بمراجعة النقاط المذكورة في اقتراحات التحسين."

#         review_data = {
#             "id": str(ObjectId()),
#             "email": email,
#             "shop_id": shop_id,
#             "stars": stars,
#             "overall_sentiment": overall_sentiment,
#             "organized_feedback": organized_feedback,
#             "solutions": solutions,
#             "original_fields": {
#                 "text": text,
#                 "enjoy_most": enjoy_most,
#                 "improve_product": improve_product,
#                 "additional_feedback": additional_feedback
#             },
#             "technical_analysis": {
#                 "cleaned_text": cleaned_text,
#                 "sentiment": sentiment,
#                 "toxicity": toxicity,
#                 "review_type": review_type,
#                 "shop_type": shop_type
#             },
#             "timestamp": datetime.datetime.now(timezone.utc)
#         }
#         result = reviews.insert_one(review_data)
#         logging.info(f"Review saved: {result.inserted_id}")

#         # إرسال إشعار
#         try:
#             owner = users.find_one({"_id": ObjectId(shop_id)})
#             if owner:
#                 message = f"تقييم جديد: {'⭐' * stars}\n\"{text}\"\nالنوع: {review_type}"
#                 if solution:
#                     message += f"\n\n💡 الحل المقترح:\n{solution}"

#                 if owner.get('device_token'):
#                     send_fcm_notification(owner['device_token'], message)
#                 # أو Telegram إذا لم يكن هناك FCM
#                 elif owner.get('telegram_chat_id'):
#                     send_telegram_notification(owner['telegram_chat_id'], message)
#         except Exception as e:
#             logging.error(f"Notification failed: {e}")

#         return jsonify({"status": "success", "review_id": str(result.inserted_id)}), 200

#     except Exception as e:
#         logging.error(f"Webhook error: {e}", exc_info=True)
#         return jsonify({"error": "Internal server error"}), 500

# @app.route('/qr/<shop_id>', methods=['GET'])
# def get_qr(shop_id):
#     try:
#         # Get shop type from database for better QR
#         owner = users.find_one({"_id": ObjectId(shop_id)})
#         shop_type = owner.get('shop_type', 'عام') if owner else 'عام'
#         shop_name = owner.get('shop_name', 'حارس السمعة') if owner else 'حارس السمعة'

#         from qr_generator import generate_qr_with_type
#         qr_base64 = generate_qr_with_type(shop_id, shop_type)
#         url = f"{TALLY_FORM_URL}?shop_id={shop_id}&shop_type={shop_type}&shop_name={shop_name}"

#         return jsonify({"qr": qr_base64, "url": url, "shop_type": shop_type})
#     except Exception as e:
#         logging.error(f"QR generation failed: {e}")
#         return jsonify({"error": "Failed to generate QR"}), 500

# if __name__ == "__main__":
#     app.run(host='0.0.0.0', port=5001, debug=False)
