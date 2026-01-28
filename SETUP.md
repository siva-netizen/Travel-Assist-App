# Setup Guide for New Developers

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/siva-netizen/Travel-Assist-App.git
   cd Travel-Assist-App
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Create your config file**
   ```bash
   # Copy the example config
   cp lib/config/app_config.dart.example lib/config/app_config.dart
   ```

4. **Add your API keys** to `lib/config/app_config.dart`

5. **Setup Firebase**
   - Create project at https://console.firebase.google.com/
   - Download `google-services.json` to `android/app/`
   - Enable Authentication (Email/Password)

6. **Run the app**
   ```bash
   flutter run -d chrome  # For web
   flutter run            # For mobile
   ```

## Where to Get API Keys

### Free Tier Options:

1. **Weather API** (Free: 1M calls/month)
   - Sign up: https://www.weatherapi.com/signup.aspx
   - Get API key from dashboard
   - Add to `AppConfig.weatherApiKey`

2. **Weatherbit** (Free: 500 calls/day)
   - Sign up: https://www.weatherbit.io/account/create
   - Get API key from account
   - Add to `AppConfig.weatherbitApiKey`

3. **HERE Maps** (Free: 250k transactions/month)
   - Sign up: https://platform.here.com/
   - Create project → Generate API key
   - Add to `AppConfig.hereApiKey`

4. **Twilio** (Free trial: $15 credit)
   - Sign up: https://www.twilio.com/try-twilio
   - Get Account SID, Auth Token, Phone Number
   - Add to respective AppConfig fields

5. **Firebase** (Free Spark plan)
   - Create project: https://console.firebase.google.com/
   - Add credentials to AppConfig

## Important Files (DO NOT COMMIT)

❌ Never push these files to GitHub:
- `lib/config/app_config.dart` (your actual keys)
- `android/app/google-services.json` (Firebase config)
- `.env` (if you create one)

✅ Safe to commit:
- `lib/config/app_config.dart.example` (template)
- `.env.example` (template)
- All other source files

## Before Your First Commit

Remove sensitive data from git:
```bash
git rm --cached android/app/google-services.json
git rm --cached lib/config/app_config.dart
```

## Need Help?

- Check existing issues: https://github.com/siva-netizen/Travel-Assist-App/issues
- Create new issue with detailed description
- Include error logs and steps to reproduce
