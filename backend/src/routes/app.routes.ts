import { Router } from 'express';

const router = Router();

/**
 * App version check endpoint for force updates.
 * 
 * Returns:
 * - minimumVersion: Minimum required app version (e.g., "1.0.0")
 * - forceUpdate: Whether update is mandatory
 * - latestVersion: Latest available version
 * - updateUrl: Optional custom update URL
 */
router.get('/version-check', (req, res) => {
  // Get minimum version from environment or use default
  const minimumVersion = process.env.MINIMUM_APP_VERSION || '1.0.0';
  const latestVersion = process.env.LATEST_APP_VERSION || '1.0.0';
  const forceUpdate = process.env.FORCE_APP_UPDATE === 'true';

  // Get store URLs (empty if not set - will be updated after apps are published)
  const iosUrl = process.env.IOS_APP_STORE_URL?.trim() || '';
  const androidUrl = process.env.ANDROID_PLAY_STORE_URL?.trim() || '';

  res.json({
    minimumVersion,
    latestVersion,
    forceUpdate,
    updateUrl: {
      ios: iosUrl || null, // null if not configured yet
      android: androidUrl || null, // null if not configured yet
    },
  });
});

export default router;
