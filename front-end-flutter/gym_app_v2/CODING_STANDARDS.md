# GymForge Flutter Coding Standards

These standards codify the zero‑lint / zero‑warning baseline you requested. All new or modified code MUST adhere unless an explicit exception is documented in the PR / commit message.

---
## 1. Analyzer & Lint Baseline
- Target: **0 analyzer issues** (warnings & errors) on `flutter analyze`.
- No re‑introducing previously fixed patterns (e.g. `use_build_context_synchronously`, deprecated API usage, `avoid_print`).
- Add `// ignore_for_file:` only with justification and never for broad suppression (avoid wildcard ignores).

### Quick Pre‑Commit Checklist
1. `flutter analyze` → 0 issues.
2. No accidental `print(`.
3. No direct `withOpacity(...)` calls (must use extension – see §2).
4. After each `await` in a `State` method, guard context usage with `if (!mounted) return;`.
5. No duplicate widget/model classes.
6. Add `const` where possible (widget trees, constructors with immutable fields).

---
## 2. Color & Opacity Handling
We replaced deprecated opacity patterns and to centralize alpha math.

Use the provided extension methods (in `core/extensions/color_extensions.dart`):
- `color.withOpacityRatio(0.3)` instead of `color.withOpacity(0.3)`
- `color.mulAlpha(0.8)` to multiply existing alpha.

DO NOT import or recreate shim/legacy `theme/color_extensions.dart`.

---
## 3. Logging Policy
All diagnostic output MUST go through `AppLogger` (in `core/logging/app_logger.dart`).

Allowed levels: `debug`, `info`, `warn`, `error`.

Example:
```dart
AppLogger.debug('Loaded ${items.length} items', tag: 'ExerciseRepo');
AppLogger.error('Failed to fetch plan', tag: 'PlanRepo', error: e, stackTrace: st);
```

Prohibited:
- `print()` / `debugPrint()` directly in app code (except inside `AppLogger`).
- Ad-hoc logging wrappers without prior discussion.

Tagging: Always set a short `tag` (feature/module) unless trivially obvious.

---
## 4. Async Context Safety
Common source of `use_build_context_synchronously` warnings.

Rules:
- Cache `navigator = Navigator.of(context);` and `messenger = ScaffoldMessenger.of(context);` BEFORE `await` if reused after.
- After any `await` inside a `State` object, before calling `setState`, Navigator, or Messenger: `if (!mounted) return;`.
- For dialogs / sheets returning values: check `if (!mounted) return;` before applying result.
- Prefer `PopScope` over legacy `WillPopScope` in new code.

---
## 5. Widget & State Naming
- Public widgets should not expose private `State` types inconsistently.
- Keep filenames snake_case matching class base name (`exercise_detail_screen.dart` → `ExerciseDetailScreen`).
- Avoid “Temp”, “Test”, “Copy” suffixes; ensure removed artifacts are fully deleted (no dead code).

---
## 6. Avoid Duplication
- Reuse existing buttons (`AppButton`), menus (`AppActionsMenu`, `PlanActionsMenu`, etc.), and cards where feasible.
- Before adding a new variant, confirm existing ones can't be parameterized.
- Delete unused placeholder / re-export files once migration complete.

---
## 7. Null Safety & Defensive Code
- Avoid unnecessary `!` (null assertion). Use early returns, pattern matching, or `if (x == null) return;`.
- Use `??=` and `??` idiomatically (e.g., `parsed ??= ...`).
- For generics in popup menus, ensure explicit `<T>` and safe casts (`value: item.value as T`).

---
## 8. Styling & Readability
- Prefer expression-bodied functions only when single, short, & clear.
- Keep line length humane (~100–110 chars). Wrap long parameter lists vertically.
- Order imports: SDK, packages, local (grouped, separated by blank lines). Run `dart format` before commit.
- Use trailing commas for multi-line widget constructors to enable formatter-friendly diffs.

---
## 9. UI Consistency
- Shadows, gradients, semi-transparent surfaces: follow existing token patterns (see `DesignTokens`). Extract a new token only if used ≥3 times.
- Do not introduce arbitrary color literals when a token exists.
- Maintain accessible contrast; semi-transparent overlays must not reduce text legibility below AA (subjective check for now).

---
## 10. Error Handling
- Catch at repository/service boundaries; surface clean domain results upward.
- Log with `AppLogger.error` including `error` & `stackTrace`.
- Show user feedback with `AppSnackBar.showError` (no raw `SnackBar` unless specialized UI needed).

---
## 11. Performance Guidelines
- Avoid heavy computation in `build()`; pre-compute in `initState()` or memoize.
- Use `const` constructors & widgets where immutable to reduce rebuild cost.
- Large lists: prepare for `ListView.builder` / pagination – no giant `Column` with > ~50 children.
- Debounce rapid search/filter actions (future enhancement: add a shared debounce util).

---
## 12. State & Lifecycle
- Dispose controllers / animation controllers in `dispose()`.
- When creating AnimationControllers: always provide a `vsync` (TickerProvider mixins already in place) and dispose.
- Do not trigger async side-effects in `build()`; use `initState`, `didChangeDependencies`, or explicit user actions.

---
## 13. API & Services
- Keep HTTP logic in services/repositories (no direct `http` calls in widgets).
- Always wrap network calls with try/catch and log failures.
- Return typed models or well-defined maps; avoid ambiguous `dynamic`.

---
## 14. Tests (Roadmap — enforce once added)
Pending introduction of test suite:
- Add unit tests for calculation-heavy services (`ExerciseLogsService`).
- Snapshot / golden tests for key widgets later (optional).
- Once tests exist, pre-commit hook will run `flutter test --coverage` (future task).

---
## 15. Git & Commit Hygiene
- Each commit should keep analyzer green (no “fix analyzer” follow-up commits unless unavoidable).
- Use descriptive English commit messages; prefix optional: `feat:`, `fix:`, `refactor:`, `cleanup:`.
- Delete feature branches after merge to avoid drift.

---
## 16. Adding New Dependencies
- Justify in PR/commit body: why not stdlib? why not existing package in repo?
- Prefer lightweight, maintained packages with null-safety.
- Avoid adding for trivial utilities (e.g., simple debouncer can be in-house).

---
## 17. Accessibility / UX (Lightweight Baseline)
- Interactive hit targets ≥ 40x40 logical pixels where practical.
- Provide semantic labels for icon-only important actions (future improvement: semantics pass).

---
## 18. Dark Theme Fidelity
- All new surfaces must align to existing elevation hierarchy (surface / surfaceAlt / overlays) and avoid pure black unless intentionally contrasting.

---
## 19. Deletion Policy
When deprecating a file:
1. Migrate imports.
2. Run search to confirm zero references.
3. Delete file same commit; do not leave stale shims unless temporary (and document with TODO + removal date).

---
## 20. TODO & Comment Discipline
- Use `// TODO(username - date): description` if adding.
- Remove resolved TODOs promptly.
- Avoid narrative comments describing obvious code; focus on intent or non-trivial reasoning.

---
## 21. Future Enhancements (Not Yet Enforced)
- Introduce DI container for services (simplify testability).
- Introduce result/either type for service returns instead of nullable maps.
- Central debounce/ throttle helper.
- Add offline queue & retry strategy wrapper.

---
## 22. Violations
Any exception must be justified in the PR/commit description with a short rationale. Repeated unjustified violations should trigger a cleanup task.

---
## 23. Adoption Steps (Suggested)
1. (Optional) Add a pre-commit hook running: `flutter analyze`.
2. (Optional) Add GitHub Action for CI: format check, analyze, (later tests).
3. Keep this document updated when patterns evolve.

---
_Last updated: 2025-09-21_
