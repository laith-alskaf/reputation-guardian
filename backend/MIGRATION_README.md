# MongoDB Schema Migration

This script updates your MongoDB collection schemas to match the application code and fix validation errors.

## Issues Fixed

1. **Users Collection**: Schema expects `password` but code uses `password_hash`
2. **Reviews Collection**: Schema expects `id` but MongoDB uses `_id`, and needs to support nested structure

## Usage

### Apply Schema Migration

```bash
python migrate_mongodb_schema.py
```

This will update both `users` and `reviews` collections with the correct schema.

### Remove Validation (For Testing)

If you want to temporarily disable schema validation for testing:

```bash
python migrate_mongodb_schema.py --remove-validation
```

⚠️ **Warning**: Removing validation removes all data integrity checks. Only use this for development/testing.

## What Gets Changed

### Users Collection Schema

- ✅ Uses `password_hash` instead of `password`
- ✅ Validates email format
- ✅ Enforces required fields: email, password_hash, shop_name, shop_type
- ✅ Optional fields: device_token, telegram_chat_id

### Reviews Collection Schema

- ✅ Uses `_id` (MongoDB standard) instead of custom `id`
- ✅ Supports nested structure:
  - `source` - Raw form data and rating
  - `processing` - Processed text and profanity flag
  - `analysis` - Sentiment and quality results
  - `generated_content` - AI-generated insights
- ✅ Maintains backward compatibility with legacy flat fields
- ✅ Required fields: shop_id, status

## After Migration

Once the migration is complete, restart your Flask application and test:

1. **Registration**: Should work without password field errors
2. **Webhook**: Should accept reviews without id field errors
3. **Dashboard**: Should display reviews correctly with nested data

## Rollback

If you need to rollback, use:

```bash
python migrate_mongodb_schema.py --remove-validation
```

Then manually restore your previous schema using MongoDB Compass or mongosh.
