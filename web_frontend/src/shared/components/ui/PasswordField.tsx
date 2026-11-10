import { forwardRef, useState, type InputHTMLAttributes, type ReactNode } from 'react';
import { Eye, EyeOff } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { Input } from './Inputs';
import { InputIcon, INPUT_ICON_PAD } from './InputIcon';

/**
 * Password input with a keyboard-accessible show/hide toggle and an optional
 * leading icon. The value is LTR inside an RTL page, so the paddings use the
 * page direction (rtl:/ltr:) to stay clear of the icon and the toggle.
 */
export const PasswordField = forwardRef<HTMLInputElement, Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> & { icon?: ReactNode }>(function PasswordField(
  { className, icon, ...rest },
  ref,
) {
  const [visible, setVisible] = useState(false);
  return (
    <InputIcon icon={icon}>
      <Input ref={ref} type={visible ? 'text' : 'password'} dir="ltr" className={cn('rtl:pl-11 rtl:text-right ltr:pr-11', icon && INPUT_ICON_PAD, className)} {...rest} />
      <button
        type="button"
        onClick={() => setVisible((v) => !v)}
        aria-label={visible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور'}
        aria-pressed={visible}
        className="absolute inset-y-0 end-0 flex w-11 items-center justify-center rounded-e-xl text-ink-muted hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300"
      >
        {visible ? <EyeOff className="h-4 w-4" aria-hidden /> : <Eye className="h-4 w-4" aria-hidden />}
      </button>
    </InputIcon>
  );
});
