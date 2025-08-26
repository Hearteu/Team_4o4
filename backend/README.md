# Inventory Management System API

A comprehensive Django REST API for inventory management with full CRUD operations, built with Django REST Framework and SQLite.

## Features

- **Complete CRUD Operations**: Create, Read, Update, Delete for all entities
- **Inventory Tracking**: Real-time stock levels with automatic updates
- **Transaction Management**: Track stock in/out with detailed history
- **Category Management**: Organize products by categories
- **Supplier Management**: Track supplier information and relationships
- **Advanced Filtering**: Search, filter, and sort capabilities
- **Statistics & Reports**: Get insights on inventory levels and transactions
- **Admin Interface**: Full Django admin integration

## Models

### Category

- Organize products into categories
- Track product count per category

### Supplier

- Store supplier contact information
- Track active/inactive suppliers
- Link products to suppliers

### Product

- Product details with SKU, pricing, and descriptions
- Link to categories and suppliers
- Track reorder levels and active status
- Real-time stock level calculations

### Inventory

- Current stock levels for each product
- Automatic total value calculations
- Low stock indicators

### Transaction

- Track all stock movements (in/out/adjustments)
- Reference numbers and notes
- Automatic inventory updates

## API Endpoints

### Categories

- `GET /api/categories/` - List all categories
- `POST /api/categories/` - Create new category
- `GET /api/categories/{id}/` - Get category details
- `PUT /api/categories/{id}/` - Update category
- `DELETE /api/categories/{id}/` - Delete category
- `GET /api/categories/{id}/products/` - Get products in category
- `GET /api/categories/stats/` - Get category statistics

### Suppliers

- `GET /api/suppliers/` - List all suppliers
- `POST /api/suppliers/` - Create new supplier
- `GET /api/suppliers/{id}/` - Get supplier details
- `PUT /api/suppliers/{id}/` - Update supplier
- `DELETE /api/suppliers/{id}/` - Delete supplier
- `GET /api/suppliers/{id}/products/` - Get products from supplier
- `GET /api/suppliers/active/` - Get active suppliers only

### Products

- `GET /api/products/` - List all products
- `POST /api/products/` - Create new product
- `GET /api/products/{id}/` - Get product details
- `PUT /api/products/{id}/` - Update product
- `DELETE /api/products/{id}/` - Delete product
- `GET /api/products/low_stock/` - Get products with low stock
- `GET /api/products/out_of_stock/` - Get out-of-stock products
- `GET /api/products/stats/` - Get product statistics
- `POST /api/products/{id}/adjust_stock/` - Adjust product stock

### Inventory

- `GET /api/inventory/` - List all inventory items
- `GET /api/inventory/{id}/` - Get inventory details
- `GET /api/inventory/low_stock/` - Get low stock items
- `GET /api/inventory/summary/` - Get inventory summary

### Transactions

- `GET /api/transactions/` - List all transactions
- `POST /api/transactions/` - Create new transaction
- `GET /api/transactions/{id}/` - Get transaction details
- `PUT /api/transactions/{id}/` - Update transaction
- `DELETE /api/transactions/{id}/` - Delete transaction
- `GET /api/transactions/recent/` - Get recent transactions (30 days)
- `GET /api/transactions/today/` - Get today's transactions
- `GET /api/transactions/summary/` - Get transaction summary
- `POST /api/transactions/bulk_stock_in/` - Bulk stock in operation

## Setup Instructions

1. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

2. **Run Migrations**

   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

3. **Create Superuser** (Optional)

   ```bash
   python manage.py createsuperuser
   ```

4. **Run Development Server**

   ```bash
   python manage.py runserver
   ```

5. **Access the API**
   - API Root: http://localhost:8000/api/
   - Admin Interface: http://localhost:8000/admin/

## Usage Examples

### Creating a Category

```bash
curl -X POST http://localhost:8000/api/categories/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Electronics", "description": "Electronic devices and accessories"}'
```

### Creating a Product

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

### Stock In Transaction

```bash
curl -X POST http://localhost:8000/api/transactions/ \
  -H "Content-Type: application/json" \
  -d '{
    "product": 1,
    "transaction_type": "IN",
    "quantity": 10,
    "unit_price": "750.00",
    "reference": "PO-2024-001",
    "notes": "Initial stock purchase"
  }'
```

### Stock Out Transaction

```bash
curl -X POST http://localhost:8000/api/transactions/ \
  -H "Content-Type: application/json" \
  -d '{
    "product": 1,
    "transaction_type": "OUT",
    "quantity": -2,
    "reference": "SALE-2024-001",
    "notes": "Customer sale"
  }'
```

### Getting Low Stock Products

```bash
curl http://localhost:8000/api/products/low_stock/
```

### Getting Inventory Summary

```bash
curl http://localhost:8000/api/inventory/summary/
```

## Filtering and Searching

### Search Products

```bash
curl "http://localhost:8000/api/products/?search=laptop"
```

### Filter by Category

```bash
curl "http://localhost:8000/api/products/?category=1"
```

### Order by Price

```bash
curl "http://localhost:8000/api/products/?ordering=unit_price"
```

### Multiple Filters

```bash
curl "http://localhost:8000/api/products/?category=1&is_active=true&ordering=-unit_price"
```

## Admin Interface

Access the Django admin interface at `http://localhost:8000/admin/` to:

- Manage all data through a user-friendly interface
- View real-time inventory levels
- Track transaction history
- Generate reports

## Database

The system uses SQLite by default for development. For production, consider using PostgreSQL or MySQL by updating the database configuration in `settings.py`.

## Security

- Basic authentication is enabled
- Session authentication for admin interface
- CSRF protection enabled
- Input validation on all endpoints

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
