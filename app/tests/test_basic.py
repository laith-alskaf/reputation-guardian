import unittest
import json
from app import create_app
from app.utils.db import connect_to_mongodb
from app.config import DATABASE_NAME

class ReputationGuardianTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()
        self.db = connect_to_mongodb()
        # Ensure we are using a test database or collection, but for now we'll just check health

    def test_health(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['version'], '2.0')

    def test_register_missing_fields(self):
        response = self.client.post('/register', json={})
        self.assertEqual(response.status_code, 400)

    def test_login_missing_fields(self):
        response = self.client.post('/login', json={})
        self.assertEqual(response.status_code, 400)

if __name__ == '__main__':
    unittest.main()
