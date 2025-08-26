# Flutter Frontend Quick Start Guide

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.0+)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Start the Backend

Make sure your Django backend is running:

```bash
cd ../backend
source venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

### 3. Run the Flutter App

```bash
# For iOS Simulator
flutter run -d ios

# For Android Emulator
flutter run -d android

# For Chrome (Web)
flutter run -d chrome
```

## 📱 App Features

### **Dashboard**

- Real-time statistics and KPIs
- Quick action buttons
- Recent transactions
- Low stock alerts

### **Navigation**

- Bottom navigation with 5 sections
- Smooth transitions
- Consistent design

### **Current Screens**

- ✅ Dashboard (Fully implemented)
- 🔄 Products (Placeholder)
- 🔄 Inventory (Placeholder)
- 🔄 Transactions (Placeholder)
- 🔄 Settings (Placeholder)

## 🎨 Design Highlights

- **Modern UI**: Material Design 3 with custom theming
- **Responsive**: Optimized for mobile devices
- **Beautiful Colors**: Professional color palette
- **Typography**: Poppins font family
- **Animations**: Smooth transitions and micro-interactions

## 🔧 Development

### **Hot Reload**

```bash
flutter run
# Press 'r' for hot reload
# Press 'R' for hot restart
```

### **Debug Mode**

```bash
flutter run --debug
```

### **Release Build**

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📊 API Connection

The app connects to the Django backend at:

- **Base URL**: `http://localhost:8000/api/`
- **Endpoints**: Categories, Products, Inventory, Transactions

## 🐛 Troubleshooting

### **Common Issues**

1. **Backend Connection Error**

   - Ensure Django server is running on port 8000
   - Check network connectivity

2. **Dependencies Issues**

   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build Errors**
   ```bash
   flutter doctor
   flutter analyze
   ```

### **Platform-Specific**

**iOS:**

- Ensure Xcode is installed
- Run `flutter doctor` to check setup

**Android:**

- Ensure Android Studio is installed
- Set up Android emulator or connect device

## 📱 Testing the App

1. **Start the backend server**
2. **Run the Flutter app**
3. **Navigate through the dashboard**
4. **Test pull-to-refresh functionality**
5. **Check bottom navigation**

## 🎯 Next Steps

- Implement remaining screens (Products, Inventory, Transactions, Settings)
- Add CRUD operations for all entities
- Implement search and filtering
- Add offline support
- Implement push notifications

## 📞 Support

For issues or questions:

1. Check the troubleshooting section
2. Review the main README.md
3. Create an issue in the repository
