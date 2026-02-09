# FCM Setup for Railway (Production)

This guide shows you how to set up Firebase Cloud Messaging on Railway.

## Option 1: Using JSON String (Recommended for Railway)

Railway works best with environment variables as strings. Here's how to set it up:

### Step 1: Get Your Service Account JSON

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file

### Step 2: Convert JSON to Single Line

You need to minify the JSON and put it all on one line. You can:

**Option A: Use an online tool**
- Go to https://jsonformatter.org/json-minify
- Paste your JSON file content
- Copy the minified result

**Option B: Use command line**
```bash
# On Mac/Linux
cat /Users/mac/Downloads/stakk-e16ba-firebase-adminsdk-fbsvc-db79fe7cbc.json | jq -c .

# Or using Python
python3 -c "import json; print(json.dumps(json.load(open('/Users/mac/Downloads/stakk-e16ba-firebase-adminsdk-fbsvc-db79fe7cbc.json'))))"
```

### Step 3: Add to Railway Environment Variables

1. Go to your Railway project dashboard
2. Select your backend service
3. Go to "Variables" tab
4. Add new variable:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the minified JSON string (all on one line)

**Important**: Make sure there are no line breaks in the JSON string.

### Step 4: Redeploy

Railway will automatically redeploy when you add environment variables, or you can manually trigger a redeploy.

## Option 2: Using File Path (For Local Development)

If you want to use a file path locally:

1. Copy your service account JSON to the backend folder:
   ```bash
   cp /Users/mac/Downloads/stakk-e16ba-firebase-adminsdk-fbsvc-db79fe7cbc.json backend/config/firebase-service-account.json
   ```

2. Add to your local `.env`:
   ```env
   FIREBASE_SERVICE_ACCOUNT=@./config/firebase-service-account.json
   ```

3. **Important**: Add to `.gitignore`:
   ```
   config/firebase-service-account.json
   ```

## Verification

After setting up, check your Railway logs. You should see:
```
FCM: Loaded service account from environment variable
FCM: Firebase Admin initialized successfully
```

If you see errors, check:
- JSON is valid and minified (no line breaks)
- All required fields are present in the service account JSON
- Railway has redeployed after adding the variable

## Security Notes

- **Never commit** the service account JSON file to git
- Railway environment variables are encrypted at rest
- The service account has admin access to your Firebase project - keep it secure
- You can restrict the service account permissions in Firebase Console if needed

## Testing

Once set up, test by creating a notification in your backend. It should automatically send a push notification to registered devices.
