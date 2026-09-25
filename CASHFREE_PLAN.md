# Razorpay → Cashfree migration plan (Jannah)

Status: PLAN ONLY. No code written. Researched 2026-09-25.
Pricing unchanged: ₹1 authorisation = 2-day trial → ₹249 daily ×7 → ₹249 weekly. Mandate ceiling ₹249.

## Decisions (user, 2026-09-25)
- **Android only.** No iOS work.
- **One-tap payment:** the installed UPI apps show as a row on the paywall. Pre-select the last-used app if it's still installed, otherwise GPay, otherwise the first app in the list. Pay goes straight into that app. No Cashfree-hosted screen.
- **Indian numbers only:** use the profile phone number as-is. The `_UpiPhoneSheet` re-prompt is removed.
- **No UPI app installed:** show a message and disable Pay.
- **Razorpay is removed entirely** (backend lib, routes, entitlement helpers, env vars, `razorpay_flutter`, docs/terms mentions). No dual-provider period.
- **Flow:** ON_DEMAND UPI AutoPay subscription. The server raises every charge. Access is granted only by the webhook.

---

## 0. Findings

### Direct-to-app mandate approval: supported by the SDK
- Installed apps: `CFUPIUtils().getUPIApps()`.
  - On Android this is a native package-manager query (`CFUPIUtil.getInstalledUPIApps`).
  - Returns `[{id: <package>, displayName, icon: <base64>}]`.
- Mandate approval, from SDK 2.3.2+49 (current version 2.4.0+52):
  `CFSubsUPIBuilder().setChannel(CFSubsUPIChannel.INTENT).setUPIID(<package>)`
  → `CFSubsUPIPaymentBuilder().setSession(CFSubscriptionSession).setUPI(...)`
  → `CFPaymentGatewayService().doPayment(...)`
  On Android this becomes native `CFSubsUpiPayment` → `doSubscriptionPayment`.
- INTENT is the only channel, and the SDK always needs one specific package. There is no generic chooser (RN SDK issue #100). We build the chooser ourselves.
- **Not verified:** whether the SDK shows a brief loader of its own before handing off to the app. Check in sandbox.
- SDK source checked: github.com/cashfree/flutter-cashfree-pg-sdk main @ 553a9fe (2026-05-22).

### Raw API fallback (only if the SDK route fails in testing)
- `POST /pg/subscriptions/pay` with `payment_type: AUTH`, `subscription_session_id` and `payment_method.upi.channel: "link"`.
- The response has separate links per app, in `data.payload.upiIntentData.androidAuthAppLinks` (`GPAY`, `PAYTM`, `BHIM`, `AMAZONPAY`, `DEFAULT`).
  - The links are `intent://mandate?…&recur=ASPRESENTED&amrule=MAX…#Intent;scheme=upi;package=…;end`.
  - PhonePe is missing from Cashfree's sample, so it would get `DEFAULT` pointed at its package.
- Opening these needs a small native channel (`Intent.parseUri`). That is a new dependency or native code, so it needs your approval first.
- UPI AutoPay Collect (the user types a UPI ID) is being retired under NPCI rules, so we don't use it.

### Schedule works on ON_DEMAND UPI
- The FAQ lists UPI AutoPay frequencies as "Daily, weekly, monthly, ad-hoc".
- A charge raised between 00:00 and 20:59 IST on day T can be scheduled for T+1. Same-day is not allowed.
- There must be 25 hours between the pre-debit notification and the charge. The amount is fixed once the notification goes out.
- NPCI rules: debits run only off-peak (before 10:00, 13:00–17:00, after 21:30), with 1 attempt + 3 retries.
- The ₹1 trial: `authorization_amount: 1` with `authorization_amount_refund: false`.
- **Fallback:** if daily charges get rejected in sandbox, use the merchant-controlled flow (controlled notification + controlled execution APIs).

### Account enablement
- **UPI AutoPay is NOT self-serve.** The docs say Cashfree activates it on request, through your account manager or the Support Form, separately for **sandbox and production**. This is a hard prerequisite.
- **7 daily charges in a row:** nothing in the docs forbids it, and every documented rule allows it: Daily frequency, T+1 scheduling, 25-hour notice. No page states it outright, so the first sandbox run is the proof. Mention it in the activation request.
- **Direct-to-app flow:** it's in the public SDK and no enablement is documented. The docs do say some API features (e.g. merchant-controlled) need account-manager coordination, so ask in the same request. The first sandbox run proves it.
- **Production approval of the app package:** not documented for subscriptions. Ask in the same request.

---

## 1. Backend (`allah-police-web`)
1. Move `PLANS`, `chargeDayOffset` and `chargeAmountPaise` from `lib/razorpay.ts` into `lib/billing-plan.ts`, then **delete** `lib/razorpay.ts`, `lib/razorpay-entitlement.ts` (after porting its Firestore helpers to `lib/cashfree-entitlement.ts`) and `app/api/razorpay/**`.
2. New `lib/cashfree.ts`, using `x-api-version: 2026-01-01` and the `x-client-id` / `x-client-secret` headers:
   - `createSubscription()`: `POST /pg/subscriptions` with:
     - `subscription_id = ap_{uid}_{ts}`
     - `plan_details {plan_type: ON_DEMAND, plan_max_amount: 249}`
     - `authorization_details {authorization_amount: 1, authorization_amount_refund: false, payment_methods: ["upi"]}`
     - `customer_details` (phone, `{uid}@no-reply.invalid`)
     - 10-year `subscription_expiry_time`
     - `subscription_tags {app: "jannah"}`
     - a short `session_id_expiry`
     - Returns `subscription_session_id`.
   - `raiseCharge()`: `POST /pg/subscriptions/pay` with `payment_type: CHARGE`, `payment_id = {mandateId}_c{n}` (also sent as `x-idempotency-key`), `payment_amount` in **rupees**, and `payment_schedule_date` = due date.
   - `fetchSubscription()` and `fetchPayment()`, for reconciliation.
   - `cancelSubscription()`: `POST /pg/subscriptions/{id}/manage {action: CANCEL}`.
   - `verifyWebhookSignature()`: `base64(HMAC-SHA256(x-webhook-timestamp + rawBody, clientSecret))`, compared in constant time. **Always enforced.**
   - `parseWebhook()`: maps `SUBSCRIPTION_AUTH_STATUS`, `SUBSCRIPTION_STATUS_CHANGED`, `SUBSCRIPTION_PAYMENT_SUCCESS`, `_FAILED` and `_CANCELLED` onto the existing `MandateEvent` shape.
3. New routes: `/api/cashfree/subscription`, `/api/cashfree/cancel`, `/api/cashfree/webhook` and `/api/cashfree/status`.
   - `/status` fetches the subscription and settles entitlement through the same code the webhook uses. It covers lost webhooks, which Cashfree can't resend.
4. Firestore mandate docs store `subscriptionId` in place of Razorpay's `customerId`/`tokenId`. No `provider` field is needed.
5. Scheduler:
   - Each charge n is raised on the morning (IST) of the day before it's due, one pending at a time.
   - A cron job reconciles charges still PENDING after 48 hours.
6. **Duplicate-mandate guard:**
   - Before creating a subscription, check the user's latest one. If it's ACTIVE or BANK_APPROVAL_PENDING, return `already_pending`.
   - If a second mandate still activates, the webhook cancels the newer one.
7. Remove the `RAZORPAY_*` env vars. Before deleting the code, check Firestore for any live `ap_` Razorpay mandates. If any exist, cancel them once through the Razorpay API, so no user is left holding a mandate nobody will ever charge. The paywall has been env-gated off, so there may be none.
8. Update `/terms` and `/privacy` to name Cashfree instead of Razorpay.

## 2. Client: one-tap UPI (Flutter, Android)
1. `pubspec.yaml`: remove `razorpay_flutter`, add `flutter_cashfree_pg_sdk: ^2.4.0+52`. No other new packages. Remove any Razorpay ProGuard or manifest entries, and update the paywall doc comments and l10n strings that mention Razorpay.
2. **AndroidManifest `<queries>`:** without this, detecting installed apps returns an empty list on Android 11+. The SDK doesn't add it.
   ```xml
   <queries>
     <intent>
       <action android:name="android.intent.action.VIEW" />
       <data android:scheme="upi" />
     </intent>
   </queries>
   ```
   Also add the SDK's `cashfree_subscription_flow_enable` meta-data if sandbox shows the element flow needs it.
3. App list from `getUPIApps()`: never hardcoded.
   - Loaded when the paywall opens, and refreshed when the app returns to the foreground.
   - Known apps sort first: GPay `com.google.android.apps.nbu.paisa.user`, PhonePe `com.phonepe.app`, Paytm `net.one97.paytm`. The package names are used only for ordering and the default choice.
4. Default selection: the last-used package (saved locally) if it's still installed → otherwise GPay if installed → otherwise the first app in the list.
5. `paywall_screen.dart`: small, targeted edits.
   - A horizontal row of app chips (icon + name) above the Start button.
   - `_startPurchase` uses the profile phone number and the selected package.
   - `_upiPhone()` and its sheet are removed.
   - The last-used package is saved when the purchase starts.
   - The existing waiting overlay and entitlement stream are kept.
6. `billing_service.dart`: `subscribe(phone:, upiPackage:)` calls `/api/cashfree/subscription`, then builds `CFSubscriptionSession` → `CFSubsUPI(INTENT, upiPackage)`, then `doPayment`.
   - SDK callbacks only change the UI and never grant access.

## 3. Knowing whether the mandate was approved
- **The webhook decides.** `SUBSCRIPTION_AUTH_STATUS` success, or `STATUS_CHANGED` → ACTIVE, writes `users/{uid}.entitlement`. The `AppState` stream then swaps the paywall out.
- When the app resumes with a mandate pending, it calls `/api/cashfree/status`.
- What the UPI app returns when it closes, and the SDK callbacks, are never trusted.

## 4. Failure paths
| Case | Handling |
|---|---|
| No UPI app installed | The app row is replaced by "No UPI app found. Install GPay, PhonePe or Paytm to continue." Pay is disabled until one is installed (the list refreshes on resume) |
| App uninstalled between listing and tap | SDK returns an error → message, list refreshes |
| User backs out in the UPI app | Resume → `/status` → still pending → overlay offers "Try again". The duplicate guard prevents a second mandate |
| Our app killed while in the UPI app | On relaunch, the entitlement stream grants access when the webhook lands. `/status` covers a lost webhook |
| Session expired before tap | Server creates a new subscription. The unused one is never authorised |
| Bad webhook signature | 401, nothing written |

## 5. Testing
Run on sandbox and on a real Android device:
- ₹1 authorisation through each installed app
- 7 daily charges, then weekly
- a failed charge and its retries
- cancelling from the UPI app and from our API
- backing out, killing the app, and a forged webhook

Then one real ₹1 run in production before switching the flag on.

## Sources
- https://www.cashfree.com/docs/payments/subscription/subscription_checkout_flutter_sdk
- https://github.com/cashfree/flutter-cashfree-pg-sdk
- https://pub.dev/packages/flutter_cashfree_pg_sdk/changelog
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/raise-a-charge-or-create-an-auth
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/payment/raise
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/mandate/create
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/mandate/manage
- https://www.cashfree.com/docs/api-reference/payments/latest/subscription/webhooks
- https://www.cashfree.com/docs/payments/subscription/faq
- https://github.com/cashfree/react-native-cashfree-pg-sdk/issues/100
