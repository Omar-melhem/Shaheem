---
name: shahm-login-design
description: Use when creating, reviewing or modifying the SHAHM login page (src/features/auth/LoginPage.tsx and src/features/auth/components/*) — layout, logo treatment, watermark, copy, motion and responsive presentation.
---

# SHAHM login design

Files: `LoginPage.tsx` (composition only) → `components/LoginLayout`, `BrandShowcase`, `LoginHeader`, `LoginForm`, `DemoAccountsPanel`. Keep that split; don't add components for trivial markup.

1. Brand first: logo via `<Logo />` (`LOGO_SRC` = the official PNG with only its white margins trimmed — no CSS crop/scale). Palette tokens in `tailwind.config.js`. Never redraw, recolour or distort the logo; never add colours or fonts.
2. Layout (RTL): **right** = white form panel; **left** = cream brand showcase (`from-cream to-cream-dark`), content centred on both axes, text centred. The showcase is hidden below `md`; `LoginHeader` then shows a small logo. One prominent logo per view.
3. Copy: headline «منصة تشغيل التوصيل للأعمال» and one short sentence. No badges, statistics, slogans or invented claims.
4. Default scene (`backgrounds/BrandBackground`): `VehicleAnimation` (original vector car in SHAHM maroon with green-tinted glass — a car, not a van or bus; clearly coloured, right→left, ~9 s pass + 5 s pause, turning wheels, transform only, parked under reduced motion) behind a large `LogoWatermark` (monochrome, ~7%, 125% width, centred). Van runs at ~67% height: behind the watermark, never over the copy. Hidden on mobile with the showcase.
5. Motion: Tailwind `animate-rise` / `animate-fade` (tokens in `tailwind.config.js`), always behind `motion-safe:`, short staggers via `motion-safe:[animation-delay:…]`. No bounce, spin, pulse or parallax. Inputs/buttons have 150 ms transitions in the shared primitives.
6. Demo accounts stay collapsed in `DemoAccountsPanel` (native `<details>`), labelled تجريبي, outline buttons only.
8. Backgrounds: `backgrounds/` holds preview variants (aurora, silk, grid — original CSS/SVG, no packages) chosen via `?bg=` (`useBackgroundPreview`). Default stays `original` until the PO picks one; then delete the others, the selector and the hook.
7. Check 390 / 820 / 1280 / 1440 px: no horizontal scroll, demo-tools button never covers controls, visible focus.
