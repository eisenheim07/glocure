# API Configuration Setup

## Initial Setup

1. Copy the template file:
   ```bash
   cp lib/config/api_config.dart.template lib/config/api_config.dart
   ```

2. Edit `lib/config/api_config.dart` and replace the placeholder values with your actual API keys:
   - `YOUR_SHOPIFY_ADMIN_ACCESS_TOKEN_HERE` - Get from Shopify Admin Panel
   - `YOUR_SHOPIFY_STOREFRONT_ACCESS_TOKEN_HERE` - Get from Shopify Admin Panel
   - `YOUR_DELHIVERY_API_TOKEN_HERE` - Get from Delhivery Dashboard
   - `YOUR_PAYU_MERCHANT_KEY_HERE` - Get from PayU Dashboard
   - `YOUR_PAYU_MERCHANT_SALT_HERE` - Get from PayU Dashboard

## Quick Setup (For Development)

If you have access to `api_config_local.dart`, you can copy the values from there:

1. Copy values from `lib/config/api_config_local.dart` to `lib/config/api_config.dart`
2. Replace the placeholder values with the actual tokens

## Security Notes

- **NEVER** commit `api_config.dart` or `api_config_local.dart` to version control
- Both files are in `.gitignore` to prevent accidental commits
- Only commit the `.template` file for other developers to use
- Keep your API keys secure and don't share them publicly

## Git Security Issue Fix

If you're getting a Git security error about exposed tokens:

1. Remove the files from Git tracking:
   ```bash
   git rm --cached lib/config/api_config.dart
   git rm --cached lib/config/api_config_local.dart
   ```

2. Commit the removal:
   ```bash
   git commit -m "Remove API config files from tracking (security)"
   ```

3. The files will remain locally but won't be tracked by Git anymore.

## File Structure

- `api_config.dart.template` - Template with placeholders (safe to commit)
- `api_config.dart` - Your actual config (DO NOT COMMIT)
- `api_config_local.dart` - Local development config (DO NOT COMMIT)
- `README.md` - This setup guide (safe to commit)