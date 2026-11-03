---
name: shahm-auth-forms
description: Use when implementing or changing the SHAHM login form or shared auth form controls (LoginForm, PasswordField, Field, useDemoSignIn).
---

# SHAHM auth forms

- Compose from shared primitives in `src/shared/components/ui/` (`Field`, `Input`, `PasswordField`, `Button`); do not hand-roll inputs.
- The identifier is **username** (existing contract, OPEN-FE-02). Keep it.
- Validate required fields per field (`Field` `error` + `aria-describedby={fieldMessageId(id)}`) and focus the first invalid field.
- Submission: guard with a `submitting` flag, show `Button loading`, disable inputs — no double submit.
- Credential check, session start and role redirect live in `useDemoSignIn` (features/auth), not in the component. Routing comes from the authenticated account's role.
- The failure message is generic («اسم المستخدم أو كلمة المرور غير صحيحة») — never reveal whether an account exists.
- Never hardcode credentials in UI and never write passwords to localStorage/sessionStorage. Demo credentials live only in the prototype store/seed and are labelled demo.
