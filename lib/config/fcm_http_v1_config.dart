// WARNING:
// This mode stores service-account credentials inside the client app.
// It is intentionally unsupported for secure production deployments.

/// Path of the service-account JSON bundled as a Flutter asset.
const String kFcmServiceAccountAssetPath =
    'lib/config/flutter-delhi-dating-1b59ff5d7c37.json';

/// Explicit kill-switch for client-side FCM HTTP v1 sending.
const bool kEnableUnsafeClientSideFcm = true;
