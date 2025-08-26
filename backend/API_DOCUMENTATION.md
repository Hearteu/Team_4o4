# Inventory Management System API Documentation

## Base URL

```
http://localhost:8000/api/
```

## Authentication

The API uses Django REST Framework's default authentication. For development, you can access the API without authentication, but for production, consider implementing proper authentication.

## API Endpoints

### 1. Categories

#### List Categories

```http
GET /api/categories/
```

**Response:**

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Electronics",
      "description": "Electronic devices and accessories",
      "created_at": "2025-08-26T06:26:18.349752Z",
      "updated_at": "2025-08-26T06:26:18.349927Z",
      "product_count": 1
    }
  ]
}
```

#### Create Category

```http
POST /api/categories/
Content-Type: application/json

{
    "name": "Electronics",
    "description": "Electronic devices and accessories"
}
```

#### Get Category Details

```http
GET /api/categories/{id}/
```

#### Update Category

```http
PUT /api/categories/{id}/
Content-Type: application/json

{
    "name": "Electronics Updated",
    "description": "Updated description"
}
```

#### Delete Category

```http
DELETE /api/categories/{id}/
```

#### Get Products in Category

```http
GET /api/categories/{id}/products/
```

#### Get Category Statistics

```http
GET /api/categories/stats/
```

**Response:**

```json
{
  "total_categories": 1,
  "categories_with_products": 1,
  "empty_categories": 0
}
```

### 2. Suppliers

#### List Suppliers

```http
GET /api/suppliers/
```

#### Create Supplier

```http
POST /api/suppliers/
Content-Type: application/json

{
    "name": "Tech Supplies Inc",
    "contact_person": "John Doe",
    "email": "john@techsupplies.com",
    "phone": "555-0123",
    "address": "123 Tech Street, City, State",
    "is_active": true
}
```

#### Get Active Suppliers Only

```http
GET /api/suppliers/active/
```

#### Get Products from Supplier

```http
GET /api/suppliers/{id}/products/
```

### 3. Products

#### List Products

```http
GET /api/products/
```

**Response:**

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Laptop",
      "sku": "LAP001",
      "description": "High-performance laptop",
      "category": 1,
      "category_name": "Electronics",
      "supplier": 1,
      "supplier_name": "Tech Supplies Inc",
      "unit_price": "999.99",
      "cost_price": "750.00",
      "reorder_level": 5,
      "is_active": true,
      "created_at": "2025-08-26T06:26:18.352054Z",
      "updated_at": "2025-08-26T06:26:18.352063Z",
      "current_stock": 10,
      "total_value": 9999.9,
      "is_low_stock": false
    }
  ]
}
```

#### Create Product

```http
POST /api/products/
Content-Type: application/json

{
    "name": "Laptop",
    "sku": "LAP001",
    "description": "High-performance laptop",
    "category": 1,
    "supplier": 1,
    "unit_price": "999.99",
    "cost_price": "750.00",
    "reorder_level": 5,
    "is_active": true
}
```

#### Get Products with Low Stock

```http
GET /api/products/low_stock/
```

#### Get Out of Stock Products

```http
GET /api/products/out_of_stock/
```

#### Get Product Statistics

```http
GET /api/products/stats/
```

**Response:**

```json
{
  "total_products": 1,
  "active_products": 1,
  "low_stock_products": 0,
  "out_of_stock_products": 0,
  "total_inventory_value": 9999.9
}
```

#### Adjust Product Stock

```http
POST /api/products/{id}/adjust_stock/
Content-Type: application/json

{
    "quantity": 5,
    "notes": "Stock adjustment due to inventory count"
}
```

### 4. Inventory

#### List Inventory Items

```http
GET /api/inventory/
```

**Response:**

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "product": 1,
      "product_name": "Laptop",
      "product_sku": "LAP001",
      "quantity": 10,
      "unit_price": "999.99",
      "total_value": 9999.9,
      "is_low_stock": false,
      "last_updated": "2025-08-26T06:26:18.354123Z"
    }
  ]
}
```

#### Get Low Stock Items

```http
GET /api/inventory/low_stock/
```

#### Get Inventory Summary

```http
GET /api/inventory/summary/
```

**Response:**

```json
{
  "total_items": 1,
  "low_stock_items": 0,
  "out_of_stock_items": 0,
  "total_value": 9999.9
}
```

### 5. Transactions

#### List Transactions

```http
GET /api/transactions/
```

#### Create Transaction

```http
POST /api/transactions/
Content-Type: application/json

{
    "product": 1,
    "transaction_type": "IN",
    "quantity": 10,
    "unit_price": "750.00",
    "reference": "PO-2024-001",
    "notes": "Initial stock purchase"
}
```

**Transaction Types:**

- `IN`: Stock In (positive quantity)
- `OUT`: Stock Out (negative quantity)
- `ADJUST`: Stock Adjustment (positive or negative quantity)

#### Get Recent Transactions (Last 30 Days)

```http
GET /api/transactions/recent/
```

#### Get Today's Transactions

```http
GET /api/transactions/today/
```

#### Get Transaction Summary

```http
GET /api/transactions/summary/
```

**Response:**

```json
{
  "today": {
    "stock_in": 10,
    "stock_out": 0,
    "transaction_count": 1
  },
  "last_30_days": {
    "stock_in": 10,
    "stock_out": 0,
    "transaction_count": 1
  }
}
```

#### Bulk Stock In

```http
POST /api/transactions/bulk_stock_in/
Content-Type: application/json

{
    "items": [
        {
            "product_id": 1,
            "quantity": 5,
            "unit_price": "750.00"
        },
        {
            "product_id": 2,
            "quantity": 3,
            "unit_price": "500.00"
        }
    ],
    "reference": "PO-2024-002",
    "notes": "Bulk purchase order"
}
```

## Filtering and Searching

### Search

Add `?search=term` to any endpoint to search across relevant fields.

**Example:**

```http
GET /api/products/?search=laptop
```

### Filtering

Use field names to filter results.

**Examples:**

```http
GET /api/products/?category=1
GET /api/products/?is_active=true
GET /api/suppliers/?is_active=true
GET /api/transactions/?transaction_type=IN
```

### Ordering

Use `?ordering=field` or `?ordering=-field` for descending order.

**Examples:**

```http
GET /api/products/?ordering=unit_price
GET /api/products/?ordering=-created_at
GET /api/inventory/?ordering=-quantity
```

### Combining Filters

You can combine multiple filters:

```http
GET /api/products/?category=1&is_active=true&ordering=-unit_price
```

## Pagination

All list endpoints support pagination with a default page size of 20 items.

**Response format:**

```json
{
    "count": 100,
    "next": "http://localhost:8000/api/products/?page=2",
    "previous": null,
    "results": [...]
}
```

## Error Handling

### Validation Errors

```json
{
  "field_name": ["This field is required."]
}
```

### Not Found

```json
{
  "detail": "Not found."
}
```

### Insufficient Stock

```json
{
  "quantity": ["Insufficient stock. Available: 5, Requested: 10"]
}
```

## Testing the API

### Using curl

1. **Create a category:**

```bash
curl -X POST http://localhost:8000/api/categories/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Electronics", "description": "Electronic devices"}'
```

2. **Create a product:**

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

3. **Add stock:**

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

4. **Get low stock products:**

```bash
curl http://localhost:8000/api/products/low_stock/
```

### Using Python requests

```python
import requests

# Base URL
base_url = "http://localhost:8000/api"

# Create category
category_data = {
    "name": "Electronics",
    "description": "Electronic devices"
}
response = requests.post(f"{base_url}/categories/", json=category_data)
category = response.json()

# Create product
product_data = {
    "name": "Laptop",
    "sku": "LAP001",
    "description": "High-performance laptop",
    "category": category["id"],
    "unit_price": "999.99",
    "cost_price": "750.00",
    "reorder_level": 5
}
response = requests.post(f"{base_url}/products/", json=product_data)
product = response.json()

# Add stock
transaction_data = {
    "product": product["id"],
    "transaction_type": "IN",
    "quantity": 10,
    "unit_price": "750.00",
    "reference": "PO-001",
    "notes": "Initial stock"
}
response = requests.post(f"{base_url}/transactions/", json=transaction_data)
```

## Admin Interface

Access the Django admin interface at `http://localhost:8000/admin/` to:

- Manage all data through a user-friendly interface
- View real-time inventory levels
- Track transaction history
- Generate reports

**Default superuser credentials:**

- Username: `admin`
- Password: (set during creation)
