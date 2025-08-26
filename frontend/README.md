# Inventory Management System - Flutter Frontend

A beautiful and modern Flutter mobile application for inventory management, designed with a focus on user experience and mobile-first design.

## 🎨 Features

### **Beautiful UI/UX**

- **Modern Design**: Clean, intuitive interface with Material Design 3
- **Responsive Layout**: Optimized for mobile devices with adaptive components
- **Dark/Light Theme**: Consistent theming with custom color palette
- **Smooth Animations**: Fluid transitions and micro-interactions

### **Dashboard**

- **Real-time Statistics**: Live inventory metrics and KPIs
- **Quick Actions**: Fast access to common operations
- **Recent Transactions**: Latest activity overview
- **Low Stock Alerts**: Proactive inventory management
- **Pull-to-Refresh**: Easy data synchronization

### **Core Functionality**

- **Product Management**: Add, edit, and organize products
- **Inventory Tracking**: Real-time stock levels and updates
- **Transaction History**: Complete audit trail of all movements
- **Category Management**: Organize products by categories
- **Supplier Management**: Track supplier information

### **Advanced Features**

- **Search & Filter**: Find products quickly with advanced search
- **Barcode Scanning**: QR code support for product identification
- **Reports & Analytics**: Data visualization and insights
- **Notifications**: Real-time alerts for low stock and updates

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd frontend
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Backend Connection

Make sure the Django backend is running on `http://localhost:8000` before using the app.

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── category.dart
│   ├── supplier.dart
│   ├── product.dart
│   ├── inventory.dart
│   └── transaction.dart
├── screens/                  # UI screens
│   ├── main_screen.dart      # Main navigation
│   ├── dashboard_screen.dart # Dashboard
│   ├── products_screen.dart  # Products management
│   ├── inventory_screen.dart # Inventory overview
│   ├── transactions_screen.dart # Transaction history
│   └── settings_screen.dart  # App settings
├── widgets/                  # Reusable components
│   ├── stat_card.dart
│   ├── quick_action_card.dart
│   └── recent_transactions_widget.dart
├── services/                 # API services
│   └── api_service.dart
├── providers/                # State management
│   └── inventory_provider.dart
└── theme/                    # App theming
    └── app_theme.dart
```

## 🎯 Key Components

### **Dashboard Screen**

- Welcome section with personalized greeting
- Statistics cards showing key metrics
- Quick action buttons for common tasks
- Recent transactions list
- Low stock alerts

### **Navigation**

- Bottom navigation bar with 5 main sections
- Smooth transitions between screens
- Consistent app bar design

### **State Management**

- Provider pattern for state management
- Real-time data synchronization
- Error handling and loading states

## 🎨 Design System

### **Colors**

- **Primary**: Blue (#2563EB) - Main brand color
- **Secondary**: Green (#10B981) - Success states
- **Accent**: Orange (#F59E0B) - Warning states
- **Error**: Red (#EF4444) - Error states
- **Background**: Light gray (#F8FAFC) - App background

### **Typography**

- **Font Family**: Poppins (Google Fonts)
- **Heading 1**: 32px, Bold
- **Heading 2**: 24px, Semi-Bold
- **Body Large**: 16px, Regular
- **Body Medium**: 14px, Regular
- **Caption**: 11px, Regular

### **Spacing**

- **XS**: 4px
- **S**: 8px
- **M**: 16px
- **L**: 24px
- **XL**: 32px
- **XXL**: 48px

## 🔧 Dependencies

### **Core Dependencies**

- `flutter`: Flutter framework
- `provider`: State management
- `http`: HTTP requests
- `intl`: Internationalization

### **UI Dependencies**

- `google_fonts`: Custom typography
- `flutter_svg`: SVG support
- `shimmer`: Loading animations
- `lottie`: Advanced animations

### **Utility Dependencies**

- `shared_preferences`: Local storage
- `uuid`: Unique identifiers
- `qr_flutter`: QR code generation
- `image_picker`: Image selection

## 📊 API Integration

The app connects to the Django REST API with the following endpoints:

- **Categories**: `/api/categories/`
- **Suppliers**: `/api/suppliers/`
- **Products**: `/api/products/`
- **Inventory**: `/api/inventory/`
- **Transactions**: `/api/transactions/`

## 🚀 Development

### **Running in Development Mode**

```bash
flutter run --debug
```

### **Building for Production**

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### **Testing**

```bash
flutter test
```

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)

## 🔮 Future Enhancements

- **Offline Support**: Local data caching
- **Push Notifications**: Real-time alerts
- **Multi-language**: Internationalization
- **Advanced Analytics**: Detailed reporting
- **Barcode Scanner**: Product identification
- **Export Features**: Data export capabilities

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions, please contact the development team or create an issue in the repository.
