# Create a Trackmania dedicated server account

Use this procedure to create dedicated server (DS) credentials or replace an
unusable pair. Account creation is separate from installing or hosting a server.

The Ubisoft account owns the DS accounts. Its email/password signs into the
website; the DS login/password authenticates the server. OAuth client IDs/secrets
from `api.trackmania.com` are separate application credentials.

Trackmania also offers a [service account](https://www.trackmania.com/player/service-account)
for API access as the linked Ubisoft player, inheriting that player's
permissions. DS accounts use a server identity with endpoint-specific API
limitations. See the community-maintained [service account reference](https://github.com/openplanet-nl/nadeoapi-docs/blob/main/docs/auth/service.md)
and [DS reference](https://github.com/openplanet-nl/nadeoapi-docs/blob/main/docs/auth/dedi.md).

## Create and save the account

1. Sign into [Trackmania](https://www.trackmania.com/) with the intended Ubisoft
   owner account. Verify the displayed identity before creating anything. If a
   shared browser is signed into someone else, use an isolated/incognito session
   or another browser profile, then verify the owner there.
2. Open [dedicated server account management](https://www.trackmania.com/player/dedicated-servers).
   The signed-in account menu also links there through **My server accounts**.
3. Create an account with the requested DS login, following the current form's
   validation and password flow. Read the actual form rather than assuming
   character/length limits or how passwords are supplied. If the requested login
   is unavailable, report that result before choosing another name.
4. Confirm the new login appears under the intended owner. Save its login and
   password to the user's chosen secret manager, or keep the secure view
   available while the user saves them. Update the application's private
   credential configuration when requested. Keep passwords and tokens out of
   chat, logs, screenshots, and tracked files.
5. When configuring an integration, make one controlled authentication check
   with the new DS pair for the audiences it needs (Core: `NadeoServices`; Live:
   `NadeoLiveServices`). Report pass/fail without credentials or tokens. Preserve
   the previous working configuration until the replacement is verified.

**Done:** the requested DS login is listed under the intended Ubisoft owner and
its credentials are securely saved; any requested integration check has an
explicit result.

## If creation or authentication is blocked

Record the failing step and exact displayed error/status, excluding secrets.
An HTTP 403 alone does not establish an incorrect password or expired Club
Access. Use an explicit access/subscription prompt as evidence for that gate.

Pause account creation for owner sign-in, account recovery, MFA, CAPTCHA, or
another human verification step that cannot be completed with available
authorization. State the concrete action needed and keep the relevant page
available. After a failed controlled authentication check, investigate the
reported failure before another attempt; avoid blind login retries.
