# Auth Token Flow (Frontend)

This document describes the current (centralized) access/refresh token handling logic in the Flutter client.

## Overview
- Access token: stored in `SharedPreferences` under key `access_token`.
- Refresh token: stored securely in `FlutterSecureStorage` under key `refresh_token`.
- Central authority: `TokenManager` in `lib/core/auth/token_manager.dart`.
- Removed legacy direct refresh method `ApiService.refreshToken` (was duplicated logic, now deleted).

## Why Centralize?
Previously there were two refresh paths:
1. `ApiService.refreshToken()` (raw HTTP call returning a loosely typed Map)
2. `TokenManager.forceRefresh()` (structured outcome + single-flight partial logic)

This duplication risked:
- Parallel /auth/refresh calls
- Divergent error handling (race → inconsistent logout behavior)
- Harder reasoning about when tokens rotate

Now only `TokenManager.forceRefresh()` performs token renewal.

## Key Behaviors (Simplified Model)
| Concern | Implementation |
|---------|----------------|
| Single-flight refresh | Internal `_inFlight` future is reused so concurrent callers await the same network request. |
| Fixed interval refresh | `RefreshScheduler` runs on a fixed interval (default 10m) and can be overridden by `.env` via `REFRESH_INTERVAL_SECONDS`. |
| Adaptive near-expiry check | `getValidAccessToken()` may still proactively refresh if token is near expiry (<60s). |
| Storage update | On success both tokens are persisted (`SharedPreferences` + `SecureStorage`). |
| Decoding | `exp` claim (if decodable) influences near-expiry logic; decode failure treated as soft. |
| Fatal refresh failures | `invalidToken`, `noRefreshToken`, `decodeError` → scheduler stops; callers may logout. |
| Soft failures | `networkError`, `serverError`, `unknownError` → scheduler continues; next interval retries. |
| Logging | One compact line per refresh attempt (see below). |

### Environment Variables
Configured in `.env` (loaded early in `main.dart`):
```
API_BASE_URL=...
REFRESH_INTERVAL_SECONDS=600
```
- If `REFRESH_INTERVAL_SECONDS` is present and a positive integer it overrides the scheduler interval.
- Missing or invalid values → fallback to the hardcoded default in `RefreshScheduler`.

### Refresh Logging Format
Each refresh attempt (manual, auto, or 401-triggered) emits one line:
```
[refresh] ts=2025-09-24T12:00:05.123Z explicit=false status=success code=200 dur=134ms
```
Fields:
- `explicit` true when a caller invoked `forceRefresh()` directly; false for scheduled/401 auto.
- `status` one of: success, noRefreshToken, networkError, invalidToken, serverError, decodeError, unknownError.
- `code` HTTP status if available.
- `dur` elapsed time of the refresh request.

## Public Methods (TokenManager)
- `getValidAccessToken()` → Returns a (possibly refreshed) access token or null if not obtainable.
- `forceRefresh({refreshToken})` → Explicit refresh with detailed `RefreshOutcome`.
- `getAccessTokenClaims()` / `getCurrentUserId()` → Optional helpers for claims-based logic.

## Removed / Deprecated
- `ApiService.refreshToken` (DELETED). All refresh operations must go through `TokenManager`.
- `TokenManager.authorizedGet` (REMOVED) → Use `ApiClient` for authorized requests.

## Suggested Usage
```dart
final token = await TokenManager.instance.getValidAccessToken();
if (token == null) {
  // trigger logout flow
}
final res = await ApiClient.instance.get('/some/protected');
```

## Future Enhancements (Optional)
- Backoff strategy after N consecutive soft failures.
- Session lifecycle stream (e.g., broadcast logout, token refresh success events).
- Metrics (expose `_lastSuccessRefresh`).
- Auto re-fetch user profile after refresh if claims materially change.
- Centralized request replay/backoff for network errors.

## Logout Behavior (Updated)
- Centralized via `LogoutService.logout(context, {reason})`.
- Guard `_isLoggingOut` prevents duplicate concurrent executions.
- Only removes authentication keys (`access_token` + secure `refresh_token`) instead of clearing all `SharedPreferences` to preserve flags like onboarding.
## 401 Handling (ApiClient + SessionGuard)
Two layers now cooperate:
1. Api layer: `ApiClient._authorizedRequest` on a 401 explicitly calls `TokenManager.forceRefresh()` (single-flight) and automatically REPLAYS the original request once if refresh succeeds.
2. Guard layer: If a caller still encounters a persistent 401 (e.g. business logic detects unauthorized after replay) it may invoke `SessionGuard.handlePersistent401()` to classify & decide logout.

Decision logic:
- Automatic replay hides transient 401s due to near-expiry tokens.
- `SessionGuard` outcomes:
  - Fatal (`invalidToken`, `noRefreshToken`, `decodeError`) → logout.
  - Soft (`networkError`, `serverError`, `unknownError`) → `softFail` (UI may show retry, no logout).
  - Success after manual refresh yet still unauthorized → `none` (caller decides next action; usually surface domain error or escalate if repeated).

Benefits:
- Avoids duplicated refresh attempts in each repository/service.
- Reduces user-visible unauthorized flicker.
- Maintains explicit logout only for true invalid session conditions.

Current integration:
- Repositories/services rely on `ApiClient` for the first replay.
- `UserService`, `LogScreen` use `SessionGuard` when encountering unresolved unauthorized states.
  - Soft failure (network/server/unknown) -> returns `softFail`, UI may show retry without logging out.
## Repository Normalization
Refactor objective: ensure all authenticated data access funnels through `ApiClient`.

Changes in this pass:
- `ExerciseLogRepository`: removed raw `http.Client` + manual token parameter; now uses `ApiClient.requestJson` and no longer requires a token argument.
- UI widgets (`LogWorkoutTimeCard`, `LogScreen`) updated to adapt to new signatures.
- `WorkoutDayExercisesRepository`: already used `ApiClient` but still uses verb helpers directly; may be migrated to `requestJson` later for richer error typing.

Advantages:
- Single place for headers, retry, refresh, JSON decoding.
- Eliminates risk of stale access token passing.
- Consistent unauthorized semantics.

---
_Last updated: Added `.env` driven `REFRESH_INTERVAL_SECONDS` + single-line refresh logging (2025-09-24)._ 
  - Success -> returns `none`; caller may choose to retry original request (future enhancement) or surface an error if repeated 401 persists.

Current integration:
- `UserService.updateProfile` & `fetchProfile` use `SessionGuard` instead of immediate logout.
- `LogScreen` replaces legacy string-match 401 heuristic with `SessionGuard`.
- Future improvement: automatic replay of the original failed request when `SessionGuard` returns `none` after a successful refresh.

## Backend Contract Assumptions
- `/auth/refresh` returns `{ access_token, refresh_token }` with 200 on success.
- `401/403` means refresh token invalid/expired → treat as fatal.
- `5xx` is transient → soft failure.

---
_Previous milestone: centralization commit removing `ApiService.refreshToken`._
