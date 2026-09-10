# Screen type: paywall, and the subscription plumbing

## Paywall (sheet)
Reached from the home banner, from locked activity rows, and from Settings → subscription.
Navy gradient ground (`120deg #16305B → #264A85`), `#FFD100` for the product name and the CTA.

Content, in order: product name "BeeMoo Everything" · the value line ("All 4 umbrellas, 30+
activities, unlimited children") · plan options · CTA · restore purchases · links to terms and
privacy. Restore and the legal links are App Review requirements, not optional polish.

Do not gate: home, the activity lists, Tips for Parents, or the first activity. Do gate: activities
beyond the free one, additional children, and (later) SLP data export.

## StoreKit 2
Client:
- `Product.products(for:)` for the plan list; render prices from StoreKit, never hard-code them
- `product.purchase()` → on `.success(.verified(let transaction))`, send the JWS to the server,
  then `await transaction.finish()` only after the server acknowledges
- `Transaction.updates` listener started at app launch, before any UI
- `Transaction.currentEntitlements` for the launch-time entitlement read, then reconcile with the server

Server (Django + DRF):
- `POST /v1/subscriptions/verify` — takes the signed transaction, validates against the App Store
  Server API, writes the entitlement
- App Store Server Notifications V2 webhook for renewals, cancellations, refunds, billing retry
- Entitlement state is **server-owned**. The client's StoreKit read is an optimisation, not the truth

## Auth
Sign in with Apple + email. Apple's rule: offering Apple sign-in is required once you offer any
third-party login, and there is no reason to add another. Email exists so a parent who switches
platforms keeps their data.

Store the Apple `userIdentifier`, not the email — Apple's private relay addresses change.
Handle the "credential revoked" notification by signing the user out cleanly.
