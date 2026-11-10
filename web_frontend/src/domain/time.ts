// Business time is Asia/Amman (CR v1.4 §6, §7), whatever timezone the browser is in.

export const BUSINESS_TZ = 'Asia/Amman';

const partsFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: BUSINESS_TZ,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hourCycle: 'h23',
});

function ammanParts(ts: number) {
  const p = Object.fromEntries(partsFormatter.formatToParts(ts).map((x) => [x.type, x.value]));
  return { y: +p.year, m: +p.month, d: +p.day, h: +p.hour, mi: +p.minute, s: +p.second };
}

/** Amman's UTC offset at an instant, in ms (handles any DST rule the runtime knows). */
function offsetMs(ts: number): number {
  const p = ammanParts(ts);
  return Date.UTC(p.y, p.m - 1, p.d, p.h, p.mi, p.s) - Math.floor(ts / 1000) * 1000;
}

/** Calendar day in Amman, "YYYY-MM-DD". */
export function ammanDayKey(ts: number): string {
  const p = ammanParts(ts);
  return `${p.y}-${String(p.m).padStart(2, '0')}-${String(p.d).padStart(2, '0')}`;
}

/** Amman wall-clock date ("YYYY-MM-DD") + time ("HH:mm") → epoch ms, or null if malformed. */
export function ammanWallTimeToEpoch(date: string, time: string): number | null {
  const dm = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  const tm = /^(\d{2}):(\d{2})$/.exec(time);
  if (!dm || !tm) return null;
  const [y, m, d, h, mi] = [+dm[1], +dm[2], +dm[3], +tm[1], +tm[2]];
  if (m < 1 || m > 12 || d < 1 || d > 31 || h > 23 || mi > 59) return null;
  const guess = Date.UTC(y, m - 1, d, h, mi);
  let ts = guess - offsetMs(guess);
  ts = guess - offsetMs(ts); // second pass settles a DST boundary
  const back = ammanParts(ts);
  if (back.y !== y || back.m !== m || back.d !== d) return null; // e.g. 31 February
  return ts;
}

/** Today, yesterday and the day before, as Amman calendar keys (CR v1.4 §7). */
export function lastThreeAmmanDays(now: number): [today: string, yesterday: string, beforeYesterday: string] {
  const [y, m, d] = ammanDayKey(now).split('-').map(Number);
  const key = (back: number) => new Date(Date.UTC(y, m - 1, d - back)).toISOString().slice(0, 10);
  return [key(0), key(1), key(2)];
}

const displayFormatter = new Intl.DateTimeFormat('ar-JO-u-nu-latn', {
  timeZone: BUSINESS_TZ,
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  hour: 'numeric',
  minute: '2-digit',
});
const timeFormatter = new Intl.DateTimeFormat('ar-JO-u-nu-latn', { timeZone: BUSINESS_TZ, hour: 'numeric', minute: '2-digit' });

/** "الأحد 9 تشرين الثاني، 3:30 م" in Amman time. */
export const formatAmmanDateTime = (ts: number) => displayFormatter.format(ts);
export const formatAmmanTime = (ts: number) => timeFormatter.format(ts);
