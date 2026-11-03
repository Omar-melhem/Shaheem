---
name: shahm-rtl-arabic
description: Use when writing or reviewing Arabic UI, RTL layout, bidirectional text or Arabic typography anywhere in the SHAHM prototype.
---

# SHAHM RTL & Arabic

- The document is `dir="rtl"`. Use logical utilities (`ms-`, `me-`, `ps-`, `pe-`, `start-`, `end-`, `border-s`, `text-start`); use physical `left/right` only for centring tricks or Leaflet internals.
- Usernames, passwords, phone numbers, references and URLs render `dir="ltr"` inside RTL text.
- Typography: Tajawal (placeholder until the PO supplies brand fonts). Keep weights to bold/extrabold for headings, regular/medium for body; line lengths short.
- Copy: short, natural Arabic; actions are verbs («دخول», «حفظ», «إضافة تاجر»); errors say what is wrong and how to fix it.
- Money via `formatMoney` (د.أ, integer fils); dates via `src/shared/lib/format.ts`.
- Check icon direction (arrows point toward reading flow), focus order and screen-reader order follow the visual RTL order.
