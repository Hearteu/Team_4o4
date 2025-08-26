# Quick Start Guide

## 🚀 Start the Server

**Make sure you're in the backend directory first:**

```bash
cd backend
```

**Then start the server:**

```bash
source venv/bin/activate && python manage.py runserver 0.0.0.0:8000
```

**Or use the startup script:**

```bash
./start_server.sh
```

## 🌐 Access the API

- **API Root**: http://localhost:8000/api/
- **Admin Interface**: http://localhost:8000/admin/
- **Categories**: http://localhost:8000/api/categories/
- **Products**: http://localhost:8000/api/products/
- **Suppliers**: http://localhost:8000/api/suppliers/
- **Inventory**: http://localhost:8000/api/inventory/
- **Transactions**: http://localhost:8000/api/transactions/

## 🔑 Admin Login

- **Username**: `admin`
- **Password**: (you'll need to set this)

To set a password for the admin user:

```bash
cd backend
source venv/bin/activate
python manage.py changepassword admin
```

## 🧪 Test the API

**Create a category:**

```bash
curl -X POST http://localhost:8000/api/categories/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Electronics", "description": "Electronic devices"}'
```

**Create a product:**

```bash
curl -X POST http://localhost:8000/api/products/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "sku": "LAP001",
    "description": "High-performance laptop",
    "category": 1,
    "unit_price": "999.99",
    "cost_price": "750.00",
    "reorder_level": 5
  }'
```

**Add stock:**

```bash
curl -X POST http://localhost:8000/api/transactions/ \
  -H "Content-Type: application/json" \
  -d '{
    "product": 1,
    "transaction_type": "IN",
    "quantity": 10,
    "unit_price": "750.00",
    "reference": "PO-001",
    "notes": "Initial stock"
  }'
```

## 📚 Full Documentation

- **README.md**: Complete setup and usage guide
- **API_DOCUMENTATION.md**: Detailed API reference
- **test_api.py**: Verification script

## 🛠️ Troubleshooting

**If you get "source: no such file or directory":**

- Make sure you're in the `backend` directory
- The virtual environment should be in `backend/venv/`

**If the server won't start:**

- Check if port 8000 is already in use
- Try a different port: `python manage.py runserver 0.0.0.0:8001`

**If you get import errors:**

- Make sure you've installed dependencies: `pip install -r requirements.txt`
- Make sure the virtual environment is activated
