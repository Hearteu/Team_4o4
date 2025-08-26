import pytest
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient

pytestmark = pytest.mark.django_db

def test_end_to_end_flow():
    c = APIClient()

    # If you switch back to IsAuthenticatedOrReadOnly, uncomment these:
    # User = get_user_model()
    # u = User.objects.create_user('tester', password='pass123')
    # c.force_authenticate(user=u)

    cat_resp = c.post('/api/categories/', {"name": "Antibiotics"}, format='json')
    assert cat_resp.status_code in (200, 201), cat_resp.json()
    cat = cat_resp.json()

    sup_resp = c.post('/api/suppliers/', {"name": "Acme", "is_active": True}, format='json')
    assert sup_resp.status_code in (200, 201), sup_resp.json()
    sup = sup_resp.json()

    prod_payload = {
        "name": "Amoxicillin 500mg Cap",
        "sku": "AMOX500",
        "category": cat["id"],
        "supplier": sup["id"],
        "unit_price": "12.50",
        "cost_price": "10.00",
        "reorder_level": 20,
        "is_active": True
    }
    prod_resp = c.post('/api/products/', prod_payload, format='json')
    assert prod_resp.status_code in (200, 201), prod_resp.json()   # <-- this will show exact field errors
    prod = prod_resp.json()

    # stock in 100
    r = c.post('/api/transactions/bulk_stock_in/', {
        "reference": "GRN-0001",
        "items": [{"product_id": prod["id"], "quantity": 100, "unit_price": "12.50"}]
    }, format='json')
    assert r.status_code in (200, 201), r.json()
