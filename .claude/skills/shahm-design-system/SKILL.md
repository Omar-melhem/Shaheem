---
name: shahm-design-system
description: Use when building or changing any SHAHM screen, to reuse the existing tokens and shared components instead of creating new styles or duplicates.
---

# SHAHM design system

- Tokens: `tailwind.config.js` — primary #8C2335, secondary #263D34, ink #242424, cream #F5F0E8, sand #C8A98A (+ tints), shadows `card`/`pop`, motion `animate-rise`/`animate-fade`. Don't hardcode other colours.
- Shared primitives (one per file) in `src/shared/components/ui/`, imported from `@/shared/components/ui`: Button, Card/CardHeader, Badge, Field, Input/Textarea/Select (`inputBase`), SearchField, PasswordField, Toggle, Dialog/ConfirmDialog, Drawer, EmptyState, PageHeader, StatCard, DetailRow, Tabs, SettingsSection/SettingsRow, SimTag/OpenDecision.
- Brand: `Logo`, `LogoWatermark` in `src/shared/components/`.
- Change a primitive once and every screen follows; never copy its classes into a feature.
- Shared components take typed props and never import features or the store.
- Mark simulated data with `SimTag` and open PO decisions with `OpenDecision` + their ID.
