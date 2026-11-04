# SHAHM prototype — agent instructions

Source of truth for requirements: SHAHM-SRS-001 v1.0 (Product Owner). Labels there
(CONFIRMED / INHERITED / PROPOSED / OPEN / PROTOTYPE) matter: never implement an
OPEN decision as if approved — make it a labelled demo assumption with its O-xxx ID
(see `OpenDecision` and `SimTag` in `src/shared/components/ui.tsx`).

## Rules
- React 18 + TypeScript + Vite + Tailwind. Arabic-first, RTL; use logical classes (`ms-`, `pe-`, `start-`, `end-`).
- Brand colours come from `tailwind.config.js` tokens (primary #8C2335, secondary #263D34, ink #242424, cream #F5F0E8, sand #C8A98A). Use the logo via `<Logo />`; do not alter the artwork.
- Layering: `domain` (pure rules) ← `application` (use cases/store) ← `features` (UI). UI never owns pricing, dispatch, wallet or order-transition rules.
- Use cases return `Result`; surface them with `reportResult()` toasts.
- Money is integer fils (`jodToFils`, `formatMoney`). No floats for money.
- Customer name, phone and meal value are optional; destination is required.
- GPS is tracked during active delivery only. Never present stale, demo or last-known locations as live.
- Captain wallet: Admin recharge only; no debits/reservations until O-019…O-028 are decided.
- Never invent support phone numbers, emails or WhatsApp links.
- Delivery completion is confirmed by the Captain only (no OTP/photo/signature).
- Keep presenter-only controls inside the demo tools drawer, clearly marked.

## Verify
`npm run build` must pass (tsc + vite build).
