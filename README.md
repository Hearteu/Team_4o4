## Disclaimer
This project was developed during Byte Forward 24-hour hackathon. All intellectual property rights belong to the hackathon organizers.
This repository is for demonstration purposes only.

## Team_4o4 – Pharmacy Inventory & AI Assistant
A full‑stack app for managing pharmacy inventory with analytics and an AI chat assistant. Backend is Django REST Framework; frontend is Flutter. The AI assistant integrates with Rev21 Labs and enriches replies with live database context from the backend.

### Project structure
- `backend/` – Django project (`/backend/backend`) and app (`/backend/pharma`)
- `frontend/` – Flutter app targeting Android, iOS, web and desktop

### Requirements
- Python 3.11+
- Node optional (not required)
- Flutter 3.22+ with Android/iOS tooling as needed
- Git

### Quick start (Windows)
1) Backend (Django)
```cmd
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```
The API will be at `http://localhost:8000/api/`.

2) Frontend (Flutter)
```cmd
cd frontend
flutter pub get
flutter run -d chrome   
```
Or run on Android/iOS devices as configured in your environment.

### AI integration (Rev21 Labs)
- Frontend uses the Rev21 Labs API in `frontend/lib/services/ai_service.dart`.
- The backend provides database context at `GET /api/ai/database-context/` (`backend/pharma/ai_views.py`).
- To change the Rev21 Labs API key and base URL, edit `frontend/lib/services/ai_service.dart` (look for `_rev21BaseUrl` and `_apiKey`). Consider moving secrets to safer storage before production.

### Useful backend endpoints
- Inventory resources: `categories/`, `suppliers/`, `products/`, `inventory/`, `transactions/`, `stock-batches/`
- AI: `ai/system-health/`, `ai/demand-forecast/`, `ai/inventory-optimization/`, `ai/sales-trends/`, `ai/comprehensive-insights/`, `ai/alert-summary/`
- AI chat: `ai/chat/`, `ai/chat/history/`, `ai/chat/clear/`
- Database context for AI: `ai/database-context/`

All endpoints are rooted at `/api/` (see `backend/pharma/urls.py`).

### Testing
Backend sample tests:
```cmd
cd backend
.venv\Scripts\activate
python -m pytest -q
```

Flutter widget test:
```cmd
cd frontend
flutter test
```

### Troubleshooting
- If the AI chat fails, ensure the backend is running on `http://localhost:8000` and the Rev21 Labs API key is valid.
- For Android builds, verify the Android SDK and emulator/device are configured.
- For iOS builds, open `frontend/ios/Runner.xcworkspace` in Xcode and resolve signing.

### Scripts/docs
- Backend quick start: `backend/QUICK_START.md`
- API docs (high‑level): `backend/API_DOCUMENTATION.md`
- AI agent notes: `backend/AI_AGENT_DOCUMENTATION.md`

### License
Internal demo/hackathon project.


