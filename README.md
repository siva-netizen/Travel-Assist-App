# Travel Assist App

A Flutter-based travel assistance application with weather forecasting, nearby attractions, and emergency call features.

## Features

- 🔐 Firebase Authentication (Email/Password)
- 🌤️ Weather Forecasting
- 📍 Nearby Attractions & Restaurants
- 📞 Twilio Voice Alerts
- 🗺️ HERE Maps Integration
- 🔥 Firebase Realtime Database

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.7.2)
- Firebase account
- API keys for external services

### 1. Clone the Repository

```bash
git clone https://github.com/siva-netizen/Travel-Assist-App.git
cd Travel-Assist-App
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Keys

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Create `lib/config/app_config.dart` with your API keys (see `.env.example` for required keys)

### 4. Get API Keys

| Service | Purpose | Signup Link |
|---------|---------|-------------|
| Weather API | Current weather data | https://www.weatherapi.com/signup.aspx |
| Weatherbit | Weather forecasts | https://www.weatherbit.io/account/create |
| HERE Maps | Location services | https://platform.here.com/ |
| Distance Matrix AI | Route calculations | https://distancematrix.ai/ |
| Twilio | Voice calls & SMS | https://www.twilio.com/try-twilio |
| Firebase | Authentication & Database | https://console.firebase.google.com/ |

### 5. Firebase Setup

1. Create a Firebase project
2. Add your app (Android/Web/iOS)
3. Download `google-services.json` → place in `android/app/`
4. Enable Authentication → Email/Password
5. Enable Realtime Database

### 6. Run the App

```bash
# For web
flutter run -d chrome

# For Android
flutter run
```

## Security Notes

⚠️ **NEVER commit:**
- `lib/config/app_config.dart` - Your API keys
- `android/app/google-services.json` - Firebase config
- `.env` - Environment variables

## License

MIT License

## Contact

Project Link: [https://github.com/siva-netizen/Travel-Assist-App](https://github.com/siva-netizen/Travel-Assist-App)
