# 🤖 Pharmacy AI Agent Documentation

## Overview

The Pharmacy AI Agent is an intelligent system that provides data-driven insights, forecasting, and recommendations for pharmacy inventory management. It uses statistical analysis and machine learning techniques to help pharmacy owners make informed decisions.

## 🚀 Features

### 1. System Health Analysis

- **Real-time health scoring** (0-100)
- **Stock health monitoring**
- **Availability tracking**
- **Activity level analysis**
- **Status categorization** (Excellent, Good, Fair, Needs Attention)

### 2. Demand Forecasting

- **30-day demand predictions**
- **Product-specific forecasting**
- **Confidence intervals**
- **Stockout risk assessment**
- **Reorder quantity recommendations**

### 3. Inventory Optimization

- **Optimal stock level calculations**
- **Holding cost analysis**
- **Reorder recommendations**
- **Cost optimization suggestions**
- **Safety stock calculations**

### 4. Sales Trend Analysis

- **Sales pattern recognition**
- **Growth rate calculation**
- **Seasonality detection**
- **Day-of-week patterns**
- **Future sales predictions**

### 5. Comprehensive Insights

- **Executive summary**
- **Critical alerts**
- **Actionable recommendations**
- **Opportunity identification**

## 📊 API Endpoints

### 1. System Health Analysis

```http
GET /api/ai/system-health/
```

**Response:**

```json
{
  "success": true,
  "data": {
    "overall_score": 85.5,
    "stock_health": 90.0,
    "availability_health": 95.0,
    "activity_health": 75.0,
    "total_products": 10,
    "low_stock_count": 2,
    "out_of_stock_count": 0,
    "recent_activity": 15,
    "status": "Good"
  },
  "message": "System health analysis completed successfully"
}
```

### 2. Demand Forecasting

```http
GET /api/ai/demand-forecast/?product_id=1&days=30
GET /api/ai/demand-forecast/?days=30
```

**Response:**

```json
{
  "success": true,
  "data": {
    "product_id": 1,
    "forecast_period_days": 30,
    "forecasted_demand": 45.5,
    "confidence_interval": 12.3,
    "avg_daily_demand": 1.52,
    "demand_volatility": 2.1,
    "current_stock": 75,
    "stockout_risk": 0.15,
    "recommended_reorder_quantity": 0,
    "confidence_level": "95%"
  }
}
```

### 3. Inventory Optimization

```http
GET /api/ai/inventory-optimization/
```

**Response:**

```json
{
  "success": true,
  "data": {
    "total_products_analyzed": 10,
    "optimization_data": [
      {
        "product_id": 1,
        "product_name": "Acetaminophen 500mg",
        "sku": "ACET-500-001",
        "current_stock": 75,
        "optimal_stock": 85.2,
        "reorder_level": 50,
        "holding_cost": 3.25,
        "stockout_risk": 0.15,
        "recommendation": "Stock level is optimal"
      }
    ],
    "summary": {
      "urgent_reorders_needed": 2,
      "high_holding_cost_products": 3,
      "total_daily_holding_cost": 45.8,
      "potential_savings": 9.16
    }
  }
}
```

### 4. Sales Trends

```http
GET /api/ai/sales-trends/?days=30
```

**Response:**

```json
{
  "success": true,
  "data": {
    "analysis_period_days": 30,
    "trend_direction": "increasing",
    "trend_strength": 15.2,
    "growth_rate_percent": 12.5,
    "average_daily_sales": 1250.75,
    "sales_volatility": 180.3,
    "predicted_sales_next_period": 37522.5,
    "day_of_week_pattern": {
      "Monday": 1100.25,
      "Tuesday": 1200.5,
      "Wednesday": 1300.75,
      "Thursday": 1250.0,
      "Friday": 1400.25,
      "Saturday": 1500.5,
      "Sunday": 1000.25
    },
    "recommendations": [
      "Sales are trending upward - consider increasing inventory",
      "Peak sales day is Saturday - ensure adequate staffing"
    ]
  }
}
```

### 5. Comprehensive Insights

```http
GET /api/ai/comprehensive-insights/
```

**Response:**

```json
{
  "success": true,
  "data": {
    "system_health": {
      /* system health data */
    },
    "demand_forecast": {
      /* demand forecast data */
    },
    "inventory_optimization": {
      /* optimization data */
    },
    "sales_trends": {
      /* sales trends data */
    },
    "executive_summary": {
      "key_metrics": {
        "system_health_score": 85.5,
        "total_products": 10,
        "low_stock_items": 2,
        "urgent_reorders": 2
      },
      "critical_alerts": ["2 products need urgent reordering"],
      "recommendations": ["Place urgent reorders for critical products"],
      "opportunities": ["Sales are growing - consider expanding inventory"]
    },
    "generated_at": "2024-01-15T10:30:00Z",
    "ai_version": "1.0.0"
  }
}
```

### 6. Product-Specific Recommendations

```http
GET /api/ai/product-recommendations/1/
```

**Response:**

```json
{
  "success": true,
  "data": {
    "product_id": 1,
    "forecast": {
      /* forecast data */
    },
    "recommendations": [
      {
        "type": "low_stock",
        "message": "Less than 1 week of stock remaining",
        "action": "Monitor closely and reorder soon",
        "priority": "medium"
      }
    ],
    "summary": {
      "total_recommendations": 1,
      "high_priority_count": 0,
      "risk_level": "medium"
    }
  }
}
```

### 7. Alert Summary

```http
GET /api/ai/alert-summary/
```

**Response:**

```json
{
  "success": true,
  "data": {
    "total_alerts": 3,
    "critical_alerts": 1,
    "high_alerts": 2,
    "alerts": [
      {
        "type": "out_of_stock",
        "severity": "critical",
        "message": "1 products are out of stock",
        "action": "Urgently reorder out of stock items"
      },
      {
        "type": "low_stock",
        "severity": "high",
        "message": "2 products are low on stock",
        "action": "Review and reorder low stock items"
      }
    ],
    "last_updated": "2024-01-15T10:30:00Z"
  }
}
```

## 🧠 AI Algorithms Used

### 1. Demand Forecasting

- **Moving Average Analysis**
- **Linear Regression**
- **Confidence Interval Calculation**
- **Stockout Risk Assessment**

### 2. Inventory Optimization

- **Safety Stock Formula**: `Safety Stock = Z × σ × √(Lead Time)`
- **Economic Order Quantity (EOQ)**
- **Holding Cost Analysis**
- **Service Level Optimization**

### 3. Sales Trend Analysis

- **Linear Trend Analysis**
- **Seasonality Detection**
- **Growth Rate Calculation**
- **Pattern Recognition**

### 4. Health Scoring

- **Weighted Scoring System**
- **Multi-factor Analysis**
- **Threshold-based Categorization**

## 📈 Business Intelligence Features

### 1. Predictive Analytics

- **Demand prediction** for next 30 days
- **Sales forecasting** with confidence intervals
- **Stockout risk assessment**
- **Optimal reorder timing**

### 2. Cost Optimization

- **Holding cost analysis**
- **Reorder cost optimization**
- **Safety stock optimization**
- **Inventory turnover analysis**

### 3. Risk Management

- **Stockout risk monitoring**
- **Supply chain risk assessment**
- **Demand volatility analysis**
- **Critical item identification**

### 4. Performance Monitoring

- **System health tracking**
- **Sales performance analysis**
- **Inventory efficiency metrics**
- **Operational insights**

## 🔧 Configuration

### Environment Variables

```bash
# AI Agent Configuration
AI_FORECAST_HORIZON=30
AI_CONFIDENCE_LEVEL=0.95
AI_LEAD_TIME_DAYS=7
AI_HOLDING_COST_RATE=0.20
```

### Dependencies

```txt
numpy==1.24.3
pandas==2.0.3
scipy==1.11.1
```

## 🚀 Usage Examples

### 1. Daily Health Check

```python
import requests

# Get system health
response = requests.get('http://localhost:8000/api/ai/system-health/')
health_data = response.json()

if health_data['data']['overall_score'] < 70:
    print("⚠️ System needs attention!")
    print(f"Health Score: {health_data['data']['overall_score']}")
```

### 2. Demand Forecasting for Specific Product

```python
# Get demand forecast for product ID 1
response = requests.get('http://localhost:8000/api/ai/demand-forecast/?product_id=1&days=30')
forecast = response.json()

print(f"Forecasted demand: {forecast['data']['forecasted_demand']}")
print(f"Stockout risk: {forecast['data']['stockout_risk']}")
```

### 3. Inventory Optimization

```python
# Get optimization recommendations
response = requests.get('http://localhost:8000/api/ai/inventory-optimization/')
optimization = response.json()

for product in optimization['data']['optimization_data']:
    if 'URGENT' in product['recommendation']:
        print(f"🚨 {product['product_name']}: {product['recommendation']}")
```

### 4. Sales Trend Analysis

```python
# Get sales trends
response = requests.get('http://localhost:8000/api/ai/sales-trends/?days=30')
trends = response.json()

print(f"Trend: {trends['data']['trend_direction']}")
print(f"Growth Rate: {trends['data']['growth_rate_percent']}%")
```

## 📊 Dashboard Integration

### Frontend Integration

```javascript
// Fetch AI insights
const fetchAIInsights = async () => {
  try {
    const response = await fetch("/api/ai/comprehensive-insights/");
    const data = await response.json();

    if (data.success) {
      updateDashboard(data.data);
    }
  } catch (error) {
    console.error("Error fetching AI insights:", error);
  }
};

// Update dashboard with AI data
const updateDashboard = (insights) => {
  // Update health score
  document.getElementById("health-score").textContent =
    insights.system_health.overall_score;

  // Update alerts
  const alertsContainer = document.getElementById("alerts");
  insights.executive_summary.critical_alerts.forEach((alert) => {
    alertsContainer.innerHTML += `<div class="alert alert-danger">${alert}</div>`;
  });
};
```

## 🔮 Future Enhancements

### Planned Features

1. **Machine Learning Models**

   - Advanced demand forecasting
   - Anomaly detection
   - Customer behavior analysis

2. **Real-time Monitoring**

   - Live alerts and notifications
   - Automated reorder suggestions
   - Performance tracking

3. **Advanced Analytics**

   - Customer segmentation
   - Product performance analysis
   - Market trend integration

4. **Integration Capabilities**
   - Supplier API integration
   - External data sources
   - Third-party analytics tools

## 📞 Support

For technical support or feature requests, please contact the development team or create an issue in the project repository.

---

**AI Agent Version**: 1.0.0  
**Last Updated**: January 2024  
**Compatibility**: Django 5.2.4+, Python 3.8+
