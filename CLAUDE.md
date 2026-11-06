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
- Pricing: fixed fee per merchant + zone (Zone-Based Pricing Spec), read-only and locked on the order (`resolveZoneFee`, re-checked in `createOrder`). Never distance-based, and a pin never changes the fee.
- Request form (Required Zone change request, replaces the 2026-11-02 pin-first decision): a delivery area chosen from the list (`areaId`) and order value (`mealValue`, strictly positive fils) are required; the customer pin, name and phone are optional (a supplied phone must be 10 digits). Address description was removed; older orders keep theirs.
- Exact pin (`domain/destination.ts`): optional and never auto-placed. It must lie inside the chosen area's polygon (`destinationPinError`); a mismatch is surfaced, never reassigned, and an area with no boundary takes no pin. An area-only order has no `destination.position`: never store a centroid, 0,0 or a guessed address, and show `NO_EXACT_LOCATION` to Captain and Admin (`isAreaOnly`).
- Order value input: the form keeps raw text; `checkOrderValue` (`domain/orderValue.ts`) parses and formats on blur and at review only. `parseJodAmount` never goes through a float and reports the ambiguous "1,500" instead of guessing. The flow lives in `features/merchant/request-captain/`: validate → review dialog → one `createOrder`; failures stay in the dialog with the form intact, and the success toast only fires after an `ok` Result and must not imply a Captain accepted.
- Toasts are one global `Toaster`, fixed top-start of the viewport (top-right in RTL).
- Place search is OpenStreetMap/Photon via `src/infrastructure/placeSearch.ts` (demo provider, O-018).
- GPS is tracked during active delivery only. Never present stale, demo or last-known locations as live.
- Captain wallet (CR v1.3 §6): the owner approved a JOD 0.200 commission per delivered order, but **it is not implemented**: there is no backend, and debits must not run in browser code. Do not add debits, holds or an editable commission to the store; see `docs/wallet-commission-backend-contract.md`. `domain/commission.ts` is a display value only.
- Never invent support phone numbers, emails or WhatsApp links.
- Delivery completion is confirmed by the Captain only (no OTP/photo/signature).
- Keep presenter-only controls inside the demo tools drawer, clearly marked.
- Dispatch (Feature Updates v1.2 §5): public rounds of 60 s (`DISPATCH_ROUND_SEC`), max 3 (`MAX_DISPATCH_ROUNDS`), then the order goes to the Admin queue with `queueReason` — never a 4th automatic round, never cancelled/delivered by expiry. Logic lives in `application/dispatchRounds.ts`. Who receives each round is still the demo policy (O-005, FU §14.3).
- Phones (FU §1.3): exactly 10 digits via `domain/phone.ts` (`isValidPhone`, `normalizePhone`) and the shared `PhoneField`; store re-validates. Never apply it to prices, amounts, coordinates or IDs.
- Service areas belong to a Governorate (`domain/governorates.ts`). Delivery routes (origin → destination) are separate records and never change pricing until the owner approves route pricing (FU §14.5–14.6).
- Merchant location (CR v1.3 §3): City → Area → exact pin, via IDs (`domain/cities.ts`, `application/merchantLocation.ts`). City is its own layer, not a Governorate. A pin outside the Area polygon is an error, never a silent reassignment. `cityId`/`areaId` null = legacy text address, valid until Admin changes it.
- Price copy (CR v1.3 §4): `application/pricingCopy.ts`. Default fills missing prices only; overwrite needs separate confirmation; every copy is audited in `pricingAudit`. Order fee snapshots never change.
- Service Areas has no permanent map (CR v1.3 §5). Boundaries open in `ServiceAreaBoundaryEditor` from «تعديل الحدود» or the From-Area step only.
- Logo: `/brand/shahm-logo-transparent.png` has real transparency. Do not use `mix-blend-mode` or filters to hide a background.
- Admin cancel: existing policy only (`CANCELLABLE_STATUSES`, pre-acceptance, O-029) through `CancelOrderDialog`. No merchant-side cancel.

## Components
- Shared primitives live one-per-file in `src/shared/components/ui/` (imported via `@/shared/components/ui`); they never import features. Reuse `SearchField`, `PasswordField`, `PhoneField`, `InputIcon`, `InfoTooltip`, `SettingsSection`/`SettingsRow`, `Field` before writing new markup.
- Admin features with several parts have their own folder: `admin/dashboard`, `admin/dispatch`, `admin/live-map`, `admin/service-areas`, `admin/merchant-pricing`.
- Inputs with `dir="ltr"` inside the RTL page: pad with `rtl:`/`ltr:` variants (see `INPUT_ICON_PAD`), not `ps-`/`pe-`, which would follow the input's own direction.
- Feature-specific components stay in their feature folder; pages compose them. Don't extract trivial one-offs.
- Sign-out always via `useSignOut`; sign-in via `useDemoSignIn` (role routing from the account, not the UI).
- Settings pages wire only controls backed by real store state; everything else is read-only (`SettingsRow readOnly`) — no Save buttons that do nothing.
- Business category (`MERCHANT_CATEGORIES`, OPEN-FE-07 proposed taxonomy) is classification only — never use it for pricing, dispatch or eligibility. `null` = legacy «غير مصنّف»; never default it.
- Merchants cannot edit their profile, category, pickup location or prices (Admin-owned).
- Project skills: `.claude/skills/shahm-login-design`, `shahm-auth-forms`, `shahm-auth-ux`, `shahm-rtl-arabic`, `shahm-design-system`.
- Logo: always `<Logo />` / `LogoWatermark` (transparent official PNG, no CSS cropping). Motion only via `motion-safe:animate-rise|fade`.

## Verify
`npm test` (business-rule checks in `tests/`, esbuild + node, no framework) and `npm run build` (tsc incl. tests + vite build) must pass. Add a `check()` to `tests/logic.test.ts` when changing a store rule.

## Agents (.claude/agents)
Third-party agents from ECC (affaan-m/ECC) and claude-code-templates (davila7), licences alongside.
Project rules above win over any agent or `~/.claude/rules/ecc` guidance. In particular:
- Never delete `package-lock.json` or reinstall dependencies to "fix" a build; fix the error.
- This is a prototype: don't impose 80% coverage/TDD or add test frameworks unasked; `npm test` + `npm run build` are the gate.
- Don't add libraries, backends or new business rules on an agent's suggestion.
