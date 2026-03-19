# Security Setup Guide

## ⚠️ Important: API Keys and Secrets

This project uses sensitive API keys that should NEVER be committed to version control.

## Setup Instructions

### 1. API Configuration File

The file `lib/config/api_config.dart` contains your actual API keys and is **already added to `.gitignore`**.

**Current Status:**
- ✅ `lib/config/api_config.dart` - Contains your actual keys (gitignored)
- ✅ `lib/config/api_config.example.dart` - Template file (committed to repo)

### 2. For New Team Members

If you're setting up this project for the first time:

1. Copy the example file:
   ```bash
   cp lib/config/api_config.example.dart lib/config/api_config.dart
   ```

2. Edit `lib/config/api_config.dart` and add your actual API keys:
   ```dart
   class ApiConfig {
     static const String shopifyAdminAccessToken = 'shpat_YOUR_ACTUAL_TOKEN_HERE';
   }
   ```

3. Never commit `lib/config/api_config.dart` to Git!

### 3. Current API Keys Location

All API keys are now centralized in `lib/config/api_config.dart`:
- Shopify Admin Access Token
- (Future: Delhivery API Token)
- (Future: Payment Gateway Keys)

### 4. Files Using API Config

- `lib/services/api_service.dart` - Uses `ApiConfig.shopifyAdminAccessToken`
- `lib/screens/product_details_screen.dart` - Uses `ApiConfig.shopifyAdminAccessToken`

## GitHub Push Protection

GitHub will block pushes that contain secrets. If you see this error:

```
remote: - Push cannot contain secrets
remote: - Shopify Access Token
```

**Solution:**
1. Remove the hardcoded token from your code
2. Use `ApiConfig` class instead
3. Ensure `lib/config/api_config.dart` is in `.gitignore`
4. Commit and push again

## Best Practices

✅ **DO:**
- Use `ApiConfig` class for all API keys
- Keep `api_config.dart` in `.gitignore`
- Share keys securely (encrypted messages, password managers)
- Rotate keys if accidentally exposed

❌ **DON'T:**
- Hardcode API keys in source files
- Commit `api_config.dart` to Git
- Share keys in plain text (Slack, email, etc.)
- Use production keys in development

## Verifying Setup

Check that your config is properly ignored:

```bash
# This should show api_config.dart is ignored
git status

# This should NOT list api_config.dart
git ls-files lib/config/
```

## Emergency: Key Exposed

If you accidentally committed an API key:

1. **Immediately revoke the key** in Shopify admin
2. Generate a new key
3. Update `lib/config/api_config.dart` with new key
4. Remove the key from Git history:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch lib/config/api_config.dart" \
     --prune-empty --tag-name-filter cat -- --all
   ```
5. Force push (⚠️ coordinate with team first)

## Questions?

Contact the team lead for:
- Access to API keys
- Questions about security setup
- Issues with configuration
