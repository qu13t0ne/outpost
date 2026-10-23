# Authentik OIDC runbook (Phase 2)

**Status: not executed.** This is the runbook for wiring single sign-on. Nothing here has been
applied to a live host yet. Read [exposure-model.md](./exposure-model.md) first for the tiers and the
authentication policy this follows.

## Scope

Phase 2 implements **OIDC only**, for exactly two applications:

| Application | Provider slug | Tier |
| ----------- | ------------- | ---- |
| Nextcloud   | `nextcloud`   | VPN  |
| Immich      | `immich`      | VPN  |

Everything else keeps what it already has, on purpose:

| Service              | Why no OIDC                                                           |
| -------------------- | --------------------------------------------------------------------- |
| Wallabag             | Native auth plus TOTP. Phone use all day; an edge gate breaks the API |
| Syncthing            | Native auth plus an API key; sync traffic is not HTTP                 |
| CyberChef, Speedtest | LAN tier, unauthenticated or app-native                               |
| Dashy                | VPN tier, no auth, contains no data                                   |
| Authentik itself     | Its own login                                                         |

**No proxy outpost is implemented.** Nothing uses `forward_auth`, so the proxy-provider path is out
of scope. Authentik's embedded outpost stays unused.

Portainer is gone from this repository, so it is not part of this phase.

## Why OIDC and not a proxy gate

`forward_auth` authenticates with a cookie. A cookie cannot be sent by a CalDAV client, a desktop
sync client, a mobile app using an API key, or an Immich public share link. A gate in front of
Nextcloud or Immich therefore either breaks those clients or has to be bypassed on exactly the paths
that matter. OIDC gives identity without breaking them. Full reasoning in
[exposure-model.md](./exposure-model.md#authentication-policy).

## Prerequisites

1. Authentik is running from [`../01_authentik/`](../01_authentik/) with a real `.env`.
2. Two DNS names resolve, from browsers **and from the application containers**:
   - `auth.<domain>` (Authentik), resolved by split DNS to server1
   - `cloud.<domain>` and `photos.<domain>`, resolved to server1
   Both app hosts are reached through Caddy on server1, so all three names point at server1.
3. Caddy has a site block for `auth.<domain>` on the **LAN/VPN listener only**. Do not create a
   Cloudflare Tunnel ingress rule for it. The IdP must never be internet-reachable; that is the whole
   reason Nextcloud is VPN-only.
4. The tailnet is up, because the VPN-tier route is how a phone or laptop reaches all three names.

Verify point 2 from inside the app containers, not just from your laptop:

```sh
docker exec <nextcloud-container> curl -fsS -o /dev/null \
  https://auth.<domain>/application/o/nextcloud/.well-known/openid-configuration
```

If that fails, the container's resolver does not know about split DNS. Fix the host's Docker DNS
configuration (or the container's `extra_hosts`) before going further. A container that cannot reach
the issuer is the single most common cause of "OIDC does not work".

## Step 1: initial Authentik setup

1. Browse to `https://auth.<domain>/` and complete the initial setup flow to set the `akadmin`
   password. Store it in the password manager; it is the break-glass for the IdP itself.
2. Confirm the version matches the pinned `AUTHENTIK_TAG` in the compose file.
3. Enforce MFA at the **authentication flow**, not per application. Adding a TOTP or WebAuthn stage
   to the flow means every application inherits it and none can be partially protected. Per-app policy
   bindings are how people end up with one app silently missing MFA.
4. Log in from a private window and confirm the MFA stage actually fires before creating any provider.

## Step 2: providers and applications

Repeat for each application. Values that must match exactly are called out.

1. **Providers > Create > OAuth2/OpenID Provider**
   - Name: `nextcloud` (and `immich`)
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID / secret: generated. Copy the secret once; it is not shown again.
   - Redirect URIs: **strict matching**, exact strings, no trailing slash:

| Application   | Redirect URI                                 |
| ------------- | -------------------------------------------- |
| Nextcloud     | `https://cloud.<domain>/apps/user_oidc/code` |
| Immich web    | `https://photos.<domain>/auth/callback`      |
| Immich mobile | `app.immich:///oauth-callback`               |

   - Signing key: the default self-signed certificate is fine here, because the apps fetch JWKS over
     the same TLS they already trust through Caddy.
2. **Applications > Create**
   - Name and slug must be `nextcloud` and `immich`. The slug is part of the issuer URL.
   - Provider: the one just created.
3. Issuer URLs, which the applications need:

   ```
   https://auth.<domain>/application/o/nextcloud/
   https://auth.<domain>/application/o/immich/
   ```

   Discovery documents:

   ```
   https://auth.<domain>/application/o/nextcloud/.well-known/openid-configuration
   https://auth.<domain>/application/o/immich/.well-known/openid-configuration
   ```

4. **Claims.** Both applications need `openid`, `profile`, `email`. Group claims are
   **version-dependent**: check the ID token before relying on them. If `groups` is absent, add a
   scope mapping that returns the user's groups under the `groups` claim and attach it to the
   provider.

## Step 3: Nextcloud

Run these inside the AIO Nextcloud container (`docker exec -it <container> bash`), or use the
administrative UI. Keep the local admin account working throughout.

1. Enable the app: `occ app:install user_oidc` (or `occ app:enable user_oidc` if already present).
2. Register the provider:

   ```sh
   occ user_oidc:provider authentik \
     --clientid="<client-id>" \
     --clientsecret="<client-secret>" \
     --discoveryuri="https://auth.<domain>/application/o/nextcloud/.well-known/openid-configuration" \
     --scope="openid profile email"
   ```

3. Verify in **Administration settings > OpenID Connect**: the provider is listed and the redirect
   URI shown there matches what was registered in Authentik character for character.
4. Test with a non-admin account before changing anything about local login.
5. Only after a successful login:
   - Disable the app-local TOTP requirement for OIDC users, so people are not prompted twice.
   - Keep `akadmin`-equivalent local access: the existing local Nextcloud admin account stays. Do not
     disable local login until the break-glass path is written down and tested.
6. **DAV and desktop sync are unaffected** and still use app passwords. OIDC does not replace them,
   and nothing in this phase adds a gate in front of `/remote.php/dav`. That is intentional.

## Step 4: Immich

Immich configuration lives in `immich/.env`, which is gitignored. Set the values on the host; the
names below are stable, but OIDC support is recent, so pin `IMMICH_VERSION` rather than tracking
`latest` and re-read the Immich release notes for the pinned version before changing anything.

```
IMMICH_OIDC_ISSUER=https://auth.<domain>/application/o/immich/
IMMICH_OIDC_CLIENT_ID=<client-id>
IMMICH_OIDC_CLIENT_SECRET=<client-secret>
IMMICH_OIDC_SCOPE=openid profile email
IMMICH_OIDC_AUTO_REGISTER=true
IMMICH_OIDC_BUTTON_TEXT=Sign in with Authentik
IMMICH_OIDC_MOBILE_REDIRECT_URI=app.immich:///oauth-callback
```

Notes:

- **Register both redirect URIs**, web and mobile, or the mobile app fails while the web app works.
- `AUTO_REGISTER=true` is a convenience for family accounts. It also means anyone who can complete
  the IdP login gets an Immich account. That is acceptable while the IdP is VPN-only and MFA is
  enforced; revisit if the IdP ever becomes internet-reachable.
- **Public share links must keep working unauthenticated.** After enabling OIDC, re-test a share link
  in a private window with no session.
- Existing Immich API keys keep working. If they do not, something has been put in front of the app
  that should not be there.

## Break-glass

Write the local admin credentials for both applications into the password manager **before** starting.
Not after.

- **Authentik down or unreachable.** New OIDC logins fail; existing sessions last until token expiry.
  Both apps keep local admin accounts: use them. Fix Authentik, do not disable OIDC under pressure.
- **IdP misconfigured, redirect loop.** Log in with the local admin account on the app host, fix the
  provider, retry.
- **Immich unusable.** Unset the `IMMICH_OIDC_*` variables, restart the `immich-server` container, log
  in locally, fix, re-set.
- **Nextcloud unusable.** `occ user_oidc:provider --delete <id>`, or disable the app. Local login
  returns.
- **Lost `akadmin` password.** From the host:
  `docker exec -it authentik ak create_recovery_key 10 akadmin`, then open the printed link.

## Verification checklist

- [ ] `akadmin` can log in with MFA from a private window.
- [ ] Nextcloud: browser login via OIDC as a non-admin account.
- [ ] Nextcloud: desktop client syncs, mobile app logs in, CalDAV works.
- [ ] Nextcloud: local break-glass admin still logs in.
- [ ] Immich: web login via OIDC.
- [ ] Immich: mobile app completes the browser hand-off.
- [ ] Immich: a public share link opens in a private window with no login.
- [ ] Immich: an existing API key still authenticates.
- [ ] Group claim present in the ID token, if group mapping is being relied on.
- [ ] No `forward_auth` directive exists anywhere in the live Caddyfile.

## Failure modes, in the order they usually happen

- **`redirect_uri` mismatch.** Authentik compares exact strings. Check scheme, host, path and trailing
  slash.
- **Container cannot reach the issuer.** Split DNS is not visible inside the container. Test with
  `curl` from inside it.
- **`invalid issuer`.** Trailing slash missing or doubled on the issuer URL. The app's issuer must
  match the `iss` claim byte for byte.
- **Login works, then tokens are rejected.** Clock skew between server1 and the app host. Check
  `timedatectl` on both.
- **Works in the browser, fails in the app.** The mobile redirect URI is not registered.
- **Group-based admin rights do not apply.** The `groups` claim is absent, or the app's group
  provisioning is version-dependent. Do not gate admin rights on it until verified.
- **A share link now demands a login.** Something is in front of Immich at the proxy. Remove it: the
  gate belongs at the IdP, not at the edge.
