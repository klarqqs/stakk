#!/bin/bash

echo "🔍 Verifying Apple Sign-In Configuration..."
echo ""

# Check if entitlements file exists
if [ -f "ios/Runner/Runner.entitlements" ]; then
    echo "✅ Entitlements file exists: ios/Runner/Runner.entitlements"
    
    # Check if it contains Apple Sign-In
    if grep -q "com.apple.developer.applesignin" "ios/Runner/Runner.entitlements"; then
        echo "✅ Entitlements file contains Apple Sign-In capability"
    else
        echo "❌ Entitlements file missing Apple Sign-In capability"
    fi
else
    echo "❌ Entitlements file NOT found: ios/Runner/Runner.entitlements"
fi

echo ""
echo "📋 Next Steps (MUST DO IN XCODE):"
echo ""
echo "1. Open Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Add Entitlements File:"
echo "   - Right-click 'Runner' folder"
echo "   - Select 'Add Files to Runner...'"
echo "   - Select 'ios/Runner/Runner.entitlements'"
echo "   - Ensure 'Copy items if needed' is checked"
echo ""
echo "3. Enable Capability:"
echo "   - Select 'Runner' project → 'Runner' target"
echo "   - Go to 'Signing & Capabilities' tab"
echo "   - Click '+ Capability'"
echo "   - Add 'Sign in with Apple'"
echo ""
echo "4. Verify Code Signing Entitlements:"
echo "   - In 'Build Settings' tab"
echo "   - Search for 'Code Signing Entitlements'"
echo "   - Should show: Runner/Runner.entitlements"
echo ""
echo "5. Clean and Rebuild:"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter run"
echo ""
