import unittest
from unittest.mock import MagicMock, patch
from app import create_app

class WebhookTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()
        # Mock database connection to avoid actual writes
        self.patcher = patch('app.utils.db.connect_to_mongodb')
        self.mock_db = self.patcher.start()

    def tearDown(self):
        self.patcher.stop()

    @patch('app.services.deepseek_service.query_deepseek')
    def test_webhook_deepseek_integration(self, mock_query):
        # Setup mock return values
        mock_query.side_effect = ["Organized feedback", "Suggested reply", "Actionable insights"]

        # Mock user model finding shop
        with patch('app.models.user.UserModel.find_by_id') as mock_find_user:
            mock_find_user.return_value = {"_id": "123", "shop_type": "مطعم", "device_token": "token"}

            # Mock review model creating review
            with patch('app.models.review.ReviewModel.create_review') as mock_create_review:
                mock_create_review.return_value = "review_id_123"

                # Mock finding existing review (None)
                with patch('app.models.review.ReviewModel.find_existing_review') as mock_find_review:
                    mock_find_review.return_value = None

                    payload = {
                        "fields": {
                            "email": "test@example.com",
                            "text": "The food was cold",
                            "shop_id": "123",
                            "stars": "1",
                            "improve_product": "Serve hot food"
                        }
                    }

                    response = self.client.post('/webhook', json=payload)

                    self.assertEqual(response.status_code, 200)
                    self.assertIn("review_id", response.json)

                    # Verify deepseek was called
                    self.assertTrue(mock_query.called)

if __name__ == '__main__':
    unittest.main()
