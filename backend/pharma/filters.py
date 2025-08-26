import django_filters as df
from django.db.models import F

from .models import Inventory


class InventoryFilter(df.FilterSet):
    is_low_stock = df.BooleanFilter(method='filter_is_low_stock')

    def filter_is_low_stock(self, qs, name, value: bool):
        low = qs.filter(quantity__lte=F('product__reorder_level'))
        return low if value else qs.exclude(pk__in=low.values('pk'))

    class Meta:
        model = Inventory
        fields = []  # don't list is_low_stock here
