---
name: shahm-auth-ux
description: Use when improving SHAHM authentication experience — Arabic copy, RTL, keyboard and screen-reader access, error/loading messaging, session and logout behaviour.
---

# SHAHM auth UX

- Short, natural Arabic copy. Labels «اسم المستخدم», «كلمة المرور»; action «دخول»; loading «جارٍ الدخول…».
- RTL with logical classes (`ms-`, `pe-`, `start-`, `end-`); username/password inputs are `dir="ltr"`.
- The password toggle is a real `<button>` with `aria-label` (إظهار/إخفاء كلمة المرور) and `aria-pressed`.
- Errors use `role="alert"`; the form-level error is linked to the form.
- No «نسيت كلمة المرور» or sign-up links — no working flow exists (OPEN-FE-03). Add only with a real destination.
- The session is per tab (sessionStorage). `useValidSession` ignores sessions for deleted accounts; `/login` redirects valid sessions home; sign-out always goes through `useSignOut`.
- Role guards: `RequireSession role=…`; a Merchant opening an Admin URL is redirected to `/merchant`.
