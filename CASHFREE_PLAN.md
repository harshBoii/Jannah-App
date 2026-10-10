# Cashfree migration plan (Jannah): FINAL

Status: **Implemented 2026-09-25** (backend + app). Not yet tested end-to-end — blocked on sandbox keys (see §0).

## 0. Implementation notes (what differs from the plan below)
- API **and webhook version: `2025-01-01`** (not 2026-01-01): Cashfree's published webhook samples are in that version, and the parser is written against them. Set the dashboard webhook to 2025-01-01.
- Env var names: `CASHFREE_APP_ID`, `CASHFREE_APP_SECRET`, `CASHFREE_ENV`.
- Firestore collection is now `mandates` (doc id = Cashfree `subscription_id`); the old `razorpayMandates` is left untouched for the cleanup script.
- Backend files: `lib/billing-plan.ts`, `lib/cashfree.ts`, `lib/mandate-entitlement.ts`, `app/api/cashfree/{subscription,webhook,status,cancel}`, `scripts/revoke-razorpay-mandates.mjs`. Razorpay lib and routes deleted.
- Charges raised at due−26h, pulled back to 20:00 IST if that would fall at 21:00–23:59 (Cashfree's T+1 cut-off); `payment_schedule_date` = due date or the earliest allowed.
- The Cashfree native Android SDK also declares the UPI `<queries>`; ours stays regardless.
- Customer email sent to Cashfree: `u-{uid}@allah-police.vercel.app` (undeliverable, uid-scoped).

Pricing is unchanged:
- ₹1 authorisation = 2-day trial
- then ₹249 a day for 7 days
- then ₹249 a week

The mandate ceiling is ₹249.

---

## 1. Decisions
| # | Decision |
|---|---|
| D1 | **Cashfree only. Razorpay is removed entirely**: backend lib, routes, entitlement helpers, env vars, `razorpay_flutter`, and every mention in copy and legal pages. |
| D2 | **ON_DEMAND UPI AutoPay subscription.** The server raises every charge (the equivalent of Razorpay's charge-at-will). |
| D3 | **Android only.** |
| D4 | **One-tap payment:** installed UPI apps show as a row on the paywall, with the last-used app selected (fallback GPay, then the first in the list). Pay goes straight into that app through the SDK's subscription UPI intent. No Cashfree-hosted screen. |
| D5 | **Indian numbers only:** the profile phone number is used as-is, and the phone re-prompt sheet is removed. |
| D6 | **No UPI app installed:** show a message and disable Pay. |
| D7 | **Only the webhook grants access.** SDK callbacks and what the UPI app returns never do. Webhook signatures are always checked. |
| D8 | **No new dependencies** beyond `flutter_cashfree_pg_sdk`. Small, targeted edits: no restructuring of the paywall or billing module. |

## 2. Research findings (the basis for the decisions)
- **Direct-to-app mandate approval is in the SDK** (added in 2.3.2+49; current version 2.4.0+52, from 2026-05).
  - `CFUPIUtils().getUPIApps()` is a native package-manager query. It returns `[{id: package, displayName, icon: base64}]`.
  - `CFSubsUPIBuilder().setChannel(INTENT).setUPIID(package)` → `CFSubsUPIPaymentBuilder` → `CFPaymentGatewayService().doPayment()`.
  - INTENT is the only channel, and it always targets one specific package, so we build the chooser ourselves.
  - Verified in the SDK source, main @ 553a9fe.
- **Daily UPI charges are possible on ON_DEMAND:**
  - UPI AutoPay supports Daily frequency.
  - A charge raised between 00:00 and 20:59 IST on day T can be scheduled for T+1. Same-day is not allowed.
  - There must be 25 hours between the pre-debit notification and the debit, and the amount is fixed once the notification goes out.
  - NPCI rules: debits run off-peak only, with 1 attempt + 3 retries.
  - The mandate is created as `recur=ASPRESENTED`, the same kind as today.
- **₹1 trial:** `authorization_amount: 1` with `authorization_amount_refund: false`. A ₹0 authorisation isn't allowed on UPI anyway.
- **ON_DEMAND limits:** no PAUSE or CHANGE_PLAN. We use neither.
- **Webhooks:**
  - Configured under the Subscriptions tab, version `2025-01-01`.
  - Signed as `base64(HMAC-SHA256(x-webhook-timestamp + rawBody, clientSecret))`.
  - **Cashfree can't resend them**, so we have to reconcile ourselves.
- **Account:** Subscriptions are enabled (confirmed by the user). The first sandbox call confirms that UPI is an enabled subscription payment method.
- **Fallbacks:** only if sandbox tests fail. Each one needs your approval.
  - (a) Daily debits rejected → Cashfree's merchant-controlled notify/execute APIs.
  - (b) The SDK intent fails → raw `POST /pg/subscriptions/pay` AUTH with `upi.channel: "link"`, which returns `upiIntentData.androidAuthAppLinks` per app. Launching those needs a little native code.

## 3. Keys & setup needed from you
**Backend env (`allah-police-web`, Vercel and local `.env`):**
| Var | Value |
|---|---|
| `CASHFREE_CLIENT_ID` | Sandbox App ID (production App ID at launch) |
| `CASHFREE_CLIENT_SECRET` | Sandbox Secret Key (production at launch). It also verifies webhooks, so no separate secret is needed |
| `CASHFREE_ENV` | `sandbox` or `production`. Chooses the API base URL, **and the backend tells the app which environment to use**, so the two can never mismatch |

Existing Firebase Admin and QStash env vars are reused unchanged.

**The Flutter app needs no Cashfree keys.** It only receives `subscription_id` + `subscription_session_id` + `environment` from the backend.

**Cashfree dashboard (after the webhook route is deployed):**
- Developers → Webhooks → **Subscriptions** tab → add `https://<backend>/api/cashfree/webhook`, version `2025-01-01`, all subscription events. Do this for sandbox and again for production.

**One-off:** keep the current `RAZORPAY_*` keys until the cleanup in step B7 has run. They're deleted after that.

**Question:** is this Cashfree account shared with the Mandir App or FLAMES, like the Razorpay one was? If yes, the webhook keeps dropping other apps' events (`ap_` prefix + `app: jannah` tag) as it does today. I'm keeping that filter either way, since it costs nothing.

## 4. Backend (`allah-police-web`)
B1. **`lib/billing-plan.ts`:**
- Moves `PLANS`, `PlanKey`, `isPlanKey`, `chargeDayOffset` and `chargeAmountPaise` out of `lib/razorpay.ts` unchanged.
- The amounts stay in paise internally, with a single `toRupees()` at the Cashfree call boundary.

B2. **`lib/cashfree.ts`:** base `https://sandbox.cashfree.com/pg` or `https://api.cashfree.com/pg`, with headers `x-api-version: 2025-01-01`, `x-client-id` and `x-client-secret`. It uses a typed `CashfreeApiError` (with the same `isPermanent` logic as today) and contains:
- `createSubscription({mandateId, phone, email, name})` → `POST /subscriptions`
  - `subscription_id = mandateId` (`ap_{uid}_{ts36}`)
  - `plan_details {plan_type: ON_DEMAND, plan_max_amount: 249, plan_name}`
  - `authorization_details {authorization_amount: 1, authorization_amount_refund: false, payment_methods: ["upi"]}`
  - `customer_details {customer_phone, customer_email: {uid}@no-reply.invalid, customer_name}`
  - `subscription_expiry_time` +10 years
  - `subscription_tags {app: "jannah"}`
  - `subscription_meta.session_id_expiry` +15 min
  - → `{subscriptionSessionId, cfSubscriptionId}`
- `raiseCharge({mandateId, chargeIndex, dueDate})` → `POST /subscriptions/pay`
  - `payment_type: CHARGE`, `payment_id = {mandateId}_c{n}` (the same value is sent as `x-idempotency-key`)
  - `payment_amount` in rupees, `payment_schedule_date = dueDate` (IST)
- `fetchSubscription(id)`, `fetchPayment(id, paymentId)`
- `cancelSubscription(id)` → `POST /subscriptions/{id}/manage {action: CANCEL}`
- `verifyWebhookSignature({rawBody, timestamp, signature})`: constant-time compare. Fails closed if the secret is missing.
- `parseWebhook(body)` → the existing `MandateEvent` shape. It covers `SUBSCRIPTION_AUTH_STATUS`, `SUBSCRIPTION_STATUS_CHANGED`, `SUBSCRIPTION_PAYMENT_SUCCESS`, `SUBSCRIPTION_PAYMENT_FAILED` and `SUBSCRIPTION_PAYMENT_CANCELLED`. Everything else is acknowledged and ignored.

B3. **`lib/billing-entitlement.ts`:** a port of `lib/razorpay-entitlement.ts`.
- The same Firestore docs, event ledger (duplicate delivery is safe) and entitlement writes.
- Mandate docs store `subscriptionId` where they held `customerId`/`tokenId`/`orderId`.
- Status mapping:
  - auth success or `ACTIVE` → entitled
  - `CUSTOMER_CANCELLED` / `CANCELLED` / `EXPIRED` / `COMPLETED` → cancelled
  - `ON_HOLD` → payment failing
  - failed auth → discarded

B4. **Routes**, under `app/api/cashfree/`:
- `subscription`: authenticated uid → **duplicate guard** → `createSubscription` → record intent → return `{mandateId, subscriptionId, subscriptionSessionId, environment}`.
  - Duplicate guard: if the user's latest mandate is ACTIVE or BANK_APPROVAL_PENDING, return `already_pending` and don't create another.
- `webhook`: raw body → signature check (401 on failure) → parse → drop foreign events → apply → book the next charge through the existing QStash `publishDebitTask`. Same 200/500 rules as today.
- `status`: authenticated uid → fetch the latest pending mandate from Cashfree → apply it through **the same function the webhook uses**. This makes up for lost webhooks.
- `cancel`: authenticated uid → stop the schedule → `cancelSubscription`. The resulting webhook updates entitlement.
- Debit task and hourly reconciliation: port the existing QStash debit handler and the reconciliation sweep so they call `raiseCharge`.
  - **Timing:** raise charge n on the morning (IST) of the day before it's due, with `payment_schedule_date` = the due date. One pending charge at a time.
  - The sweep also fetches charges still PENDING after 48 hours.

B5. **If a second mandate activates anyway**, e.g. from two quick retries: the webhook keeps the older one active and cancels the newer one.

B6. **Delete** `lib/razorpay.ts`, `lib/razorpay-entitlement.ts`, `app/api/razorpay/**` and the `RAZORPAY_*` env reads. Update `/terms`, `/privacy` and any web copy that names Razorpay.

B7. **Cleanup (before B6):** a script queries Firestore for Jannah mandates with a Razorpay token that are not cancelled. If any exist, it revokes them through Razorpay once and records the result. It's expected to find none, since the paywall has been switched off by default.

## 5. App (Flutter, Android)
A1. `pubspec.yaml`: remove `razorpay_flutter`, add `flutter_cashfree_pg_sdk: ^2.4.0+52`.

A2. **`AndroidManifest.xml`:**
- Add `<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="upi"/></intent></queries>`. Without it, Android 11+ reports no UPI apps.
- Add `cashfree_subscription_flow_enable` meta-data per the SDK docs.
- Remove any Razorpay entries (manifest and ProGuard).

A3. **`services/billing/billing_service.dart`:**
- `upiApps()` wraps `CFUPIUtils().getUPIApps()`: known apps first (GPay `com.google.android.apps.nbu.paisa.user`, PhonePe `com.phonepe.app`, Paytm `net.one97.paytm`), then the rest. Only apps the device reports are included.
- `subscribe(phone:, upiPackage:)` calls `/api/cashfree/subscription`, then `CFSubscriptionSession` (environment from the response) → `CFSubsUPI(INTENT, upiPackage)` → `CFSubsUPIPayment` → `doPayment`.
- The SDK callbacks resolve only the UI future. `already_pending` maps to the waiting overlay.
- `checkStatus()` calls `/api/cashfree/status`.
- `cancel()` points at `/api/cashfree/cancel`.

A4. **Last-used app:** one new `AppSettings` field, `lastUpiPackage`, saved when a purchase starts.

A5. **`screens/paywall_screen.dart`:**
- A horizontal row of selectable app chips (icon + name) in the footer, above the Start button.
- Default selection: `lastUpiPackage` if still installed → otherwise GPay → otherwise the first app.
- No apps: the row is replaced by the message, and Start is disabled.
- The app list is refreshed on `AppLifecycleState.resumed`, which also calls `checkStatus()` while waiting.
- `_upiPhone()` and `_UpiPhoneSheet` are removed.
- The billing disclosure (Know more), waiting overlay and promo flow are unchanged.

A6. **Text:** new l10n strings for the no-UPI-app message and the "Pay with" label. Remove Razorpay from the doc comments and strings.

## 6. How access is decided
- The webhook or the `/status` route writes `users/{uid}.entitlement` → `AppState`'s Firestore stream → the startup gate swaps the paywall out.
- The client never grants access. `firestore.rules` already rejects client writes.

## 7. Failure paths
| Case | Handling |
|---|---|
| No UPI app | Message, Start disabled. The list refreshes on resume |
| App uninstalled after listing | SDK error → message, list refreshes |
| User backs out of the UPI app | Resume → `/status` → still pending → overlay "Try again". The duplicate guard blocks a second mandate |
| Our app killed while in the UPI app | Relaunch → the entitlement stream picks up the webhook. `/status` covers a lost webhook |
| Session expired before approval | Next tap creates a new subscription. The old one is never authorised |
| Charge fails | `SUBSCRIPTION_PAYMENT_FAILED` → up to 3 retries per cycle, then entitlement is lapsed |
| User cancels in the UPI app | `STATUS_CHANGED` → CUSTOMER_CANCELLED → schedule stops, entitlement ends at the end of the paid period |
| Bad webhook signature | 401, nothing written |

## 8. Build order & checkpoints
1. **B1–B3 + `subscription` route.** Checkpoint: a sandbox call creates an ON_DEMAND UPI subscription. This also proves UPI AutoPay is enabled on the account.
2. **Webhook + status routes.** Checkpoint: a forged signature → 401; a real sandbox event → Firestore updated once, even if delivered twice.
3. **App A1–A6.** Checkpoint, on a real Android device: the row lists only installed apps, the default is right, and Pay goes straight into the chosen app with no Cashfree screen. The ₹1 sandbox authorisation grants access through the webhook.
4. **Debit scheduler + reconciliation.** Checkpoint (sandbox): charge 1 = ₹1, then charges 2–8 on consecutive days, then weekly. **This is the proof that 7 daily charges in a row work.**
5. **B7 cleanup → B6 removal.** Checkpoint: nothing mentions Razorpay anywhere in the code, and `flutter analyze` + `next build` are clean.
6. **Production:** production keys and webhook, one real ₹1 authorisation + one daily debit, then the paywall is turned on.

## 9. Test matrix
- Authorisation through GPay, PhonePe and Paytm
- Back out of the UPI app
- Kill our app while in the UPI app
- No UPI app installed
- Duplicate taps
- Failed charge and its retries
- Cancel from the UPI app and cancel from our API
- Forged and duplicate webhooks
- A lost webhook, recovered through `/status`

## Sources
- https://www.cashfree.com/docs/payments/subscription/subscription_checkout_flutter_sdk
- https://github.com/cashfree/flutter-cashfree-pg-sdk
- https://pub.dev/packages/flutter_cashfree_pg_sdk/changelog
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/raise-a-charge-or-create-an-auth
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/payment/raise
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/mandate/create
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/plans/create
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/mandate/manage
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/webhooks
- https://www.cashfree.com/docs/payments/subscription/faq
- https://www.cashfree.com/docs/payments/webhooks
- https://github.com/cashfree/react-native-cashfree-pg-sdk/issues/100
