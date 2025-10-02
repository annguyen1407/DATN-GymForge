# Improvements Backlog
Generated: 2025-10-02

## Legend
- Priority: (H)igh / (M)edium / (L)ow
- Effort: (S)mall <1d, (M)edium 1–2d, (L)arge >2d

## Items
| ID | Title | Description | Priority | Effort | Status |
|----|-------|-------------|----------|--------|--------|
| 1 | OTP Hashing | Store hashed OTP + attempts counter & invalidate on use | H | S | TODO |
| 2 | Monetary Decimal Migration | Change Float -> Decimal for payment/commission/subscription amounts | H | M | TODO |
| 3 | Rate Limiting Auth | Apply throttling to login / forgot / verify / reset endpoints | H | S | TODO |
| 4 | Soft Delete Middleware | Prisma middleware to auto-filter `isDeleted=false` on User reads | M | S | TODO |
| 5 | SetsLog Timestamp | Add `createdAt` (and maybe `updatedAt`) to SetsLog model | M | S | TODO |
| 6 | Swagger / OpenAPI | Generate API docs with @nestjs/swagger | M | S | TODO |
| 7 | Audit Logging Layer | Interceptor/service for structured event logs | M | M | TODO |
| 8 | Normalize Endpoints | Adjust clone-template & performance routes to resource-oriented patterns | L | M | TODO |
| 9 | Unique googleId | Add unique index + fallback flow | M | S | TODO |
|10 | Partial Index Active Users | Postgres partial index on users(isDeleted=false) | M | S | TODO |
|11 | Pagination Standard | Define query params: page, limit, sort, filter semantic | M | S | TODO |
|12 | Ownership Guard | Additional guard ensuring resource belongs to requester | M | M | TODO |
|13 | Config Versioning | Track AdminConfig revisions (history table) | L | M | TODO |
|14 | Progress Derivation Strategy | Optionally remove stored progressPercent and derive on read | L | M | DISCUSS |
|15 | Salary Generation Lock | Distributed lock to avoid double payouts | M | S | TODO |
|16 | Notification Templates | Standardize notification messages with templating | L | M | TODO |
|17 | Decimal Formatting | Central helper to format monetary decimals for API responses | M | S | TODO |
|18 | Error Response Contract | Unified { error: { code, message } } shape | M | S | TODO |
|19 | Soft Delete Cascade Policy | Define how deleting user affects coach/gymer/profile references | M | M | TODO |
|20 | Security Headers | Apply Helmet & CSP baseline | H | S | TODO |

## Sequencing Proposal (First Sprint)
1 -> 3 -> 20 -> 2 -> 4 -> 6

## Notes
- Decimal migration requires Prisma schema change + migration + code audit (amount arithmetic).
- OTP hashing reuses same expiry fields; ensure clearing fields after success.
- OwnershipGuard can piggyback on existing services (load entity & compare userId).

---
Related docs: `SCHEMA_OVERVIEW.md`, `SECURITY_REVIEW.md`, `API_SURFACE.md`.
