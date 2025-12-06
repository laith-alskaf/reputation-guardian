# Reputation Guardian (حارس السمعة)

A comprehensive reputation management system designed for shop owners to collect, analyze, and act on customer feedback effectively.

## 🎯 Goal
The goal of this project is to empower shop owners to:
1.  **Collect Feedback**: Easily via QR codes.
2.  **Analyze Sentiment**: Understand customer sentiment (Positive, Negative, Neutral) using AI.
3.  **Detect Issues**: Identify specific issues using Toxicity analysis and DeepSeek AI insights.
4.  **Act Quickly**: Receive real-time notifications and suggested professional replies.

## 🏗️ Architecture
This project follows a clean **MVC (Model-View-Controller)** architecture built with Flask:

-   **app/controllers/**: Handles HTTP requests (Blueprints).
    -   `auth_controller.py`: User authentication (Register/Login).
    -   `webhook_controller.py`: Receives feedback from Tally.so.
    -   `dashboard_controller.py`: Serves analytics data.
    -   `qr_controller.py`: Generates QR codes.
-   **app/models/**: Database abstraction (MongoDB).
    -   `user.py`: User management.
    -   `review.py`: Review storage and retrieval.
-   **app/services/**: Business logic and integrations.
    -   `deepseek_service.py`: AI analysis for insights and replies.
    -   `sentiment_service.py`: Text cleaning and basic sentiment analysis.
    -   `notification_service.py`: Firebase (FCM) and Telegram notifications.
    -   `qr_service.py`: QR code generation logic.
-   **app/utils/**: Helper functions.
    -   `db.py`: Database connection.
    -   `middleware.py`: JWT authentication and input validation.

## 🚀 Setup & Installation

### Prerequisites
-   Python 3.9+
-   MongoDB
-   Firebase Account (for notifications)
-   Hugging Face Token (for AI models)

### Installation

1.  Clone the repository:
    ```bash
    git clone <repository-url>
    cd reputation-guardian
    ```

2.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

3.  Configure Environment Variables:
    Create a `.env` file in the root directory:
    ```env
    MONGO_URI=mongodb://localhost:27017/
    SECRET_KEY=your_jwt_secret_key
    HF_TOKEN=your_hugging_face_token
    TELEGRAM_TOKEN=your_telegram_bot_token
    FIREBASE_JSON={"type": "service_account", ...} # Or path to file
    ```

4.  Run the application:
    ```bash
    python3 run.py
    ```

## 🧪 Testing
Run the unit tests to ensure everything is working correctly:
```bash
python3 -m unittest discover app/tests
```

## 🔗 API Endpoints

-   `POST /register`: Create a new shop account.
-   `POST /login`: Authenticate and get a token.
-   `POST /webhook`: Webhook endpoint for Tally.so (receives reviews).
-   `GET /dashboard`: Get shop analytics and reviews.
-   `POST /generate-qr`: Generate a unique QR code for the shop.

## 🛠️ Tech Stack
-   **Backend**: Flask
-   **Database**: MongoDB (PyMongo)
-   **AI/ML**: Hugging Face (DeepSeek, CAMeL-BERT), qrcode
-   **Notifications**: Firebase Admin SDK, Python Telegram Bot
