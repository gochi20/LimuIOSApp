# Limu Mobile Registration Email OTP QA

- Source visual truth: existing Limu authentication flow and shared design-system components
- Implementation screenshot: `/Users/applguy/Desktop/Limu Mobile/tmp/design-qa-registration-otp/verification-ready.png`
- Viewport: native iPhone 17e, 390 × 844 points at 3× scale
- State: pending registration with a valid six-digit OTP entered

## Findings

- No actionable P0, P1, or P2 mismatches remain.
- Registration transitions to a dedicated email-verification screen instead of authenticating immediately.
- The screen uses the shared branded header, palette, typography, field, and primary-button treatments.
- The code field accepts digits only, stops at six digits, and keeps Verify Email disabled until complete.
- The destination email, 10-minute expiry, resend action, and delivery-failure recovery are clearly communicated.
- A correct OTP activates the credential, returns the first session, and enters the authenticated app; an incorrect or expired OTP does not.
- Pending users who later attempt to sign in are redirected back to the verification screen.
- Labels and controls are exposed correctly in the accessibility tree without clipping or truncation.

## Patches Made

- Added the SwiftUI email-verification state, code input, resend feedback, and pending-login recovery.
- Added V4 registration OTP issuance, verification, resend, throttling, expiry, attempt limiting, and SMTP delivery through the existing Limu mail helper.
- Updated the OpenAPI contract, API README, and smoke tests.

## Follow-up Polish

- No remaining P3 items for the requested registration email-verification flow.

final result: passed

---

# Limu Mobile Country Phone Input QA

- Source visual truth: existing Limu authentication/profile forms and shared design-system fields
- State: registration, KYC personal details, and edit profile phone-number entry

## Findings

- Phone fields now use a shared country-code selector with Malawi selected by default.
- The national number input formats live according to the selected country grouping.
- Input is capped at the selected country’s maximum national-number length.
- Simulator testing caught and fixed a paste/fast-entry edge case so the visible text is capped/formatted too, not just the stored value.
- Country selection sheet opens correctly; switching Malawi to Zambia updates the code from `+265` to `+260`, changes the placeholder, and re-groups the entered number.
- Form progression/save actions stay disabled until the selected country’s phone length is valid.
- The saved value is normalized as an international number, for example `+265 888 000 000`.

## Patches Made

- Added reusable phone country metadata, formatter, picker sheet, and `CountryPhoneField`.
- Hardened the phone input with a UIKit-backed field delegate for reliable formatting during typing and paste-style entry.
- Replaced registration, KYC, and edit-profile phone fields with the new shared component.
- Added phone-validity checks to registration, KYC personal-step progression, and profile save.

final result: passed

---

# Limu Mobile Forgot Password Reset-Link QA

- Source visual truth: existing Limu authentication flow and shared design-system components
- Deep-link smoke screenshot: `/Users/applguy/Desktop/Limu Mobile/tmp/forgot-password-reset-link/deeplink-reset-screen.png`
- Viewport: native iPhone 17 simulator
- State: iOS recognized the registered `limu://` scheme and displayed the app-open confirmation

## Findings

- Forgot password now requests a reset link instead of asking the user to start from a manual code.
- Reset links are generated as `limu://reset-password?token=...&purpose=password_reset` by default.
- The iOS app registers the `limu` URL scheme and routes accepted reset links into the unauthenticated change-password form.
- The change-password form keeps the token hidden when opened from a link, shows a secure-link confirmation, and requires a valid new password before submit.
- The API smoke test confirms the link shape, token completion, old-password rejection, and new-password login.

## Patches Made

- Added password-reset deep-link handling in `ContentView` and the auth reset screen.
- Added URL scheme registration in `LimuMobileInfo.plist`.
- Updated V4 reset-link email generation, README/OpenAPI notes, and smoke coverage.

final result: passed
