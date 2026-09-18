# App privacy — Limu Mobile 1.0

Two things have to agree, or the submission gets held: the **App Privacy** questionnaire in App
Store Connect, and the **privacy manifest** shipped in the bundle
(`Limu Mobile/PrivacyInfo.xcprivacy`). This file is the source of truth for both, and every entry
below is traced to the code that causes it.

## Summary

- The app **does not track** users. No IDFA, no `AppTrackingTransparency`, no analytics SDK, no
  advertising SDK, no third-party SDK of any kind — the project has zero package dependencies.
- Everything collected goes to Limu Trade's own backend (`portal.limu.co.mw`) over HTTPS and is
  **linked to the user's identity**, because the whole app is an authenticated client portal.
- No data is collected from users who are not signed in, other than what they type into the
  registration form.

## App Store Connect — App Privacy answers

Answer **"Yes, we collect data from this app"**, then declare exactly these types.
For every one: **Linked to the user = Yes**, **Used for tracking = No**.

| Data type | Category | Purpose | Where it comes from |
| --- | --- | --- | --- |
| Name | Contact Info | App Functionality | `firstName` / `lastName` in registration, KYC and profile edit (`AppState.register`, `ProfileView.swift:323`, `ProfileView.swift:654`) |
| Email Address | Contact Info | App Functionality, Customer Support | Registration, sign-in identifier, OTP verification, password reset |
| Phone Number | Contact Info | App Functionality, Customer Support | Registration and profile; defaults to +265 |
| Physical Address | Contact Info | App Functionality | `location` — the self-selected Malawi district. Typed by the user, **not** read from device location. |
| Device ID | Identifiers | App Functionality | APNs device token plus a locally generated install UUID (`limuDeviceID`), sent to `devices/push-token.php` |
| Other Data | Other Data | App Functionality | KYC fields with no matching Apple category: `gender`, `dateOfBirth`, `clientType`, `businessName`, `businessCategory`, `businessSize`, `businessOffering`, `tradeIntent`, `goodsCategories`, `termsAccepted` |

### Explicitly **not** declared

| Not declared | Why |
| --- | --- |
| Precise or Coarse Location | No `CoreLocation` import anywhere. The district is a picker value. |
| Photos or Videos | The app **displays** order-form item photos from URLs; it never reads the photo library. No `PhotosPicker`, no `UIImagePickerController`, no `NSPhotoLibraryUsageDescription`. |
| Camera / Microphone | No `AVFoundation` capture. |
| Contacts | No `Contacts` import. |
| Payment Info | `APIClient.uploadPaymentProof` and `AppState.uploadPayment` exist, but **nothing in the UI calls them** — there is no invoices screen in 1.0. Nothing is transmitted, so nothing is declared. **This must be added the moment a payment-proof UI ships** (see below). |
| Purchases | No in-app purchase, no StoreKit. |
| Usage Data / Diagnostics | No analytics or crash SDK integrated (L9). |
| Search History, Browsing History, Sensitive Info, Health, Financial Info | Not touched. |

### When the payment-proof UI ships

Adding a screen that calls `AppState.uploadPayment` changes the answers. Before that build goes
out, update **both** files:

- App Store Connect: add **Payment Info** (amount, transaction ID) and **Other User Content**
  (the uploaded receipt file, which may be a photo or a PDF).
- `PrivacyInfo.xcprivacy`: add `NSPrivacyCollectedDataTypePaymentInfo` and
  `NSPrivacyCollectedDataTypeOtherUserContent`, both linked, both App Functionality.
- If the file is picked from the photo library rather than the Files app, add
  `NSPhotoLibraryUsageDescription` to `LimuMobileInfo.plist` too — a missing usage string is a
  guaranteed crash on first use and an automatic rejection.

## Privacy manifest — required-reason APIs

`Limu Mobile/PrivacyInfo.xcprivacy` is a filesystem-synchronised file inside the `Limu Mobile`
group, so Xcode 16+ bundles it into the target automatically (`objectVersion = 77`,
`PBXFileSystemSynchronizedRootGroup`). No project-file edit is needed — but **verify it appears in
Build Phases → Copy Bundle Resources** of the archive before uploading.

| API category | Reason code | Why |
| --- | --- | --- |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | `UserDefaults` is read and written only by this app, for its own data: the install UUID (`limuDeviceID`), the stored push token, and API base-URL overrides. Never shared with an app group or another app. |

Keychain (`SecItemAdd` / `SecItemCopyMatching` in `APIClient.swift`) is **not** a required-reason
API and needs no declaration. No file-timestamp, disk-space, active-keyboard or system-boot-time
APIs are used.

`NSPrivacyTracking` is `false` and `NSPrivacyTrackingDomains` is empty, which is consistent with
declaring no tracking in App Store Connect. These two must never disagree.

## Privacy policy

**`https://limu.co.mw/policy`**

Declared in App Store Connect, and linked from inside the app in two places — a Privacy Policy row
in Profile, and a link on the Delete Account screen. The constant lives in `LimuLinks.privacyPolicy`
(`Limu Mobile/DesignSystem.swift`); change it in one place and both links follow.

Before submitting, confirm the page is live, public, and reachable without a login — Apple checks
it, and a 404 or a redirect to a sign-in wall stops the review. The page has to cover, at minimum:

- What is collected — the six data types in the table above.
- Why — delivering the freight-forwarding service.
- Who it is shared with — nobody. No third-party processors are integrated.
- How long it is retained, and which records survive account deletion (customs, tax and accounting
  records that Limu Trade is legally required to keep).
- How a client deletes their account.

That last pair matters more than it looks: the retention carve-out in the policy is what makes the
in-app deletion flow defensible to a reviewer. If the policy is silent on it, the rejection arrives
at the privacy step instead of the deletion step.

### Account deletion — App Store Review Guideline 5.1.1(v)

**Implemented in the app.** `Profile → Delete Account` requires the account password plus the word
DELETE typed out, then calls `AppState.deleteAccount(password:)`.

**Backend implemented, not yet deployed.** `DELETE profile/delete.php` now exists in the portal
repository (`gochi20/limu`). It destroys the credential, sessions, device tokens, verification codes
and KYC submission, anonymises the `Clients` row, and writes a hashed audit record. It has not been
deployed to `portal.limu.co.mw` or run against a database yet, so the flow stays unverified end to
end. Detail in [`ACCOUNT-DELETION.md`](../../ACCOUNT-DELETION.md).

Worth noting for the questionnaire: deletion **anonymises** rather than erases the client row,
because cargo, shipment and invoice records are keyed to it and are legally retained. The privacy
policy has to describe that carve-out.
