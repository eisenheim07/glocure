# Internet Connectivity System

The Glocure app now includes comprehensive internet connectivity checking to ensure a smooth user experience when network issues occur.

## Features

- **Automatic Detection**: Monitors internet connectivity in real-time
- **Non-Cancelable Bottom Sheet**: Shows when no internet connection is detected
- **Try Again Functionality**: Allows users to retry connection checking
- **API Integration**: All API calls check connectivity before making requests
- **Visual Feedback**: Clear UI indicating connection status

## How It Works

### 1. Connectivity Service (`lib/services/connectivity_service.dart`)
- Monitors network connectivity using `connectivity_plus` package
- Verifies actual internet access by pinging `google.com`
- Shows/hides bottom sheet based on connection status
- Provides manual connectivity checking for API calls

### 2. Connectivity Cubit (`lib/cubits/connectivity/connectivity_cubit.dart`)
- Manages connectivity state across the app using BLoC pattern
- Provides reactive updates to UI components
- Allows manual connectivity verification

### 3. API Integration (`lib/services/api_service.dart`)
- All GraphQL requests check connectivity before execution
- Throws descriptive error messages when no connection
- Prevents unnecessary API calls when offline

### 4. Main App Integration (`lib/main.dart`)
- Initializes connectivity service with navigator key
- Provides ConnectivityCubit to all screens
- Enables global connectivity monitoring

## User Experience

### When Internet is Available
- App functions normally
- All API calls work as expected
- No connectivity UI shown

### When Internet is Lost
1. **Automatic Detection**: Service detects connection loss
2. **Bottom Sheet Display**: Non-cancelable bottom sheet appears
3. **Clear Message**: "No Internet Connection" with description
4. **Try Again Button**: User can retry connection check
5. **Auto-Hide**: Bottom sheet disappears when connection restored

### Bottom Sheet Features
- **Non-Cancelable**: Cannot be dismissed by tapping outside or back button
- **Try Again Button**: Rechecks connectivity when pressed
- **Visual Design**: Clean UI with wifi-off icon and clear messaging
- **Responsive**: Adapts to different screen sizes

## API Error Handling

When API calls are made without internet:
```dart
// Error message thrown by API service
"No internet connection. Please check your network and try again."
```

## Manual Connectivity Checking

For custom implementations:
```dart
// Check connectivity status
bool isConnected = ConnectivityService().isConnected;

// Manual connectivity verification
bool hasConnection = await ConnectivityService().checkConnectivity();

// Using Cubit for reactive updates
context.read<ConnectivityCubit>().verifyConnection();
```

## Implementation Details

### Dependencies Added
- `connectivity_plus: ^6.0.5` - Network connectivity monitoring

### Files Created/Modified
- `lib/services/connectivity_service.dart` - Core connectivity logic
- `lib/cubits/connectivity/connectivity_cubit.dart` - State management
- `lib/services/api_service.dart` - Added connectivity checks
- `lib/main.dart` - Service initialization and cubit provider
- `pubspec.yaml` - Added connectivity_plus dependency

### Key Methods

**ConnectivityService:**
- `initialize()` - Start monitoring connectivity
- `checkConnectivity()` - Manual connectivity check
- `isConnected` - Current connection status

**ConnectivityCubit:**
- `checkConnectivity()` - Update state with current status
- `verifyConnection()` - Async connectivity verification

## Testing Scenarios

### Test No Internet Connection
1. Turn off WiFi and mobile data on device
2. Open the app or navigate between screens
3. Bottom sheet should appear automatically
4. Tap "Try Again" - should remain if still no connection
5. Turn on internet - bottom sheet should disappear

### Test API Calls Without Internet
1. Disable internet connection
2. Try to load products, categories, or other API-dependent content
3. Should see appropriate error messages
4. Enable internet and retry - should work normally

## Benefits

- **Better UX**: Users know when connectivity issues occur
- **Prevents Errors**: Stops API calls when no internet available
- **Clear Feedback**: Visual indication of connection problems
- **Easy Recovery**: Simple retry mechanism for users
- **App Stability**: Prevents crashes from network timeouts

The connectivity system ensures users always know their connection status and provides a smooth experience even when network issues occur.