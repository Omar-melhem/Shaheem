# SHAHM prototype — agent instructions

Source of truth for requirements: SHAHM-SRS-001 v1.0 (Product Owner). Labels there
(CONFIRMED / INHERITED / PROPOSED / OPEN / PROTOTYPE) matter: never implement an
OPEN decision as if approved — make it a labelled demo assumption with its O-xxx ID
(see `OpenDecision` and `SimTag` in `src/shared/components/ui/DemoLabels.tsx`).

## Rules
- React 18 + TypeScript + Vite + Tailwind. Arabic-first, RTL; use logical classes (`ms-`, `pe-`, `start-`, `end-`).
- Brand colours come from `tailwind.config.js` tokens (primary #8C2335, secondary #263D34, ink #242424, cream #F5F0E8, sand #C8A98A). Use the logo via `<Logo />`; do not alter the artwork.
- Layering: `domain` (pure rules) ← `application` (use cases/store) ← `features` (UI). UI never owns pricing, dispatch, wallet or order-transition rules.
- Use cases return `Result`; surface them with `reportResult()` toasts.
- Money is integer fils (`jodToFils`, `formatMoney`). No floats for money.
- Pricing: fixed fee per merchant + zone (Zone-Based Pricing Spec), read-only and locked on the order. Owner decision 2026-11-02: the merchant pins the customer (place search or map tap, like a delivery app) and the zone is detected from the pin via zone polygons (`resolveLocationFee`, re-checked in `createOrder`). Never distance-based. Zones without a drawn boundary cannot be matched.
- Request form: customer phone + customer pin + address description (building/floor) required; name and meal value optional. Delivery instructions and location notes were removed (owner, 2026-11-02).
- Place search is OpenStreetMap/Photon via `src/infrastructure/placeSearch.ts` (demo provider, O-018).
- GPS is tracked during active delivery only. Never present stale, demo or last-known locations as live.
- Captain wallet: Admin recharge only; no debits/reservations until O-019…O-028 are decided.
- Never invent support phone numbers, emails or WhatsApp links.
- Delivery completion is confirmed by the Captain only (no OTP/photo/signature).
- Keep presenter-only controls inside the demo tools drawer, clearly marked.

## Components
- Shared primitives live one-per-file in `src/shared/components/ui/` (imported via `@/shared/components/ui`); they never import features. Reuse `SearchField`, `PasswordField`, `SettingsSection`/`SettingsRow`, `Field` before writing new markup.
- Feature-specific components stay in their feature folder; pages compose them. Don't extract trivial one-offs.
- Sign-out always via `useSignOut`; sign-in via `useDemoSignIn` (role routing from the account, not the UI).
- Settings pages wire only controls backed by real store state; everything else is read-only (`SettingsRow readOnly`) — no Save buttons that do nothing.
- Business category (`MERCHANT_CATEGORIES`, OPEN-FE-07 proposed taxonomy) is classification only — never use it for pricing, dispatch or eligibility. `null` = legacy «غير مصنّف»; never default it.
- Merchants cannot edit their profile, category, pickup location or prices (Admin-owned).
- Project skills: `.claude/skills/shahm-login-design`, `shahm-auth-forms`, `shahm-auth-ux`, `shahm-rtl-arabic`, `shahm-design-system`.
- Logo: always `<Logo />` / `LogoWatermark` (trimmed official PNG, no CSS cropping). Motion only via `motion-safe:animate-rise|fade`.

## Verify
`npm test` (business-rule checks in `tests/`, esbuild + node, no framework) and `npm run build` (tsc incl. tests + vite build) must pass. Add a `check()` to `tests/logic.test.ts` when changing a store rule.

## Agents (.claude/agents)
Third-party agents from ECC (affaan-m/ECC) and claude-code-templates (davila7), licences alongside.
Project rules above win over any agent or `~/.claude/rules/ecc` guidance. In particular:
- Never delete `package-lock.json` or reinstall dependencies to "fix" a build; fix the error.
- This is a prototype: don't impose 80% coverage/TDD or add test frameworks unasked; `npm test` + `npm run build` are the gate.
- Don't add libraries, backends or new business rules on an agent's suggestion.
