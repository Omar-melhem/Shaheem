const dateTime = new Intl.DateTimeFormat('ar-JO-u-nu-latn', {
  day: 'numeric',
  month: 'short',
  hour: 'numeric',
  minute: '2-digit',
});
const time = new Intl.DateTimeFormat('ar-JO-u-nu-latn', { hour: 'numeric', minute: '2-digit', second: '2-digit' });
const date = new Intl.DateTimeFormat('ar-JO-u-nu-latn', { day: 'numeric', month: 'long', year: 'numeric' });

export const formatDateTime = (ts: number) => dateTime.format(ts);
export const formatTime = (ts: number) => time.format(ts);
export const formatDate = (ts: number) => date.format(ts);

export function formatRelative(ts: number, now: number = Date.now()): string {
  const sec = Math.max(0, Math.round((now - ts) / 1000));
  if (sec < 10) return 'الآن';
  if (sec < 60) return `منذ ${sec} ث`;
  const min = Math.round(sec / 60);
  if (min < 60) return `منذ ${min} د`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `منذ ${hr} س`;
  return formatDateTime(ts);
}

export function formatCountdown(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}
