import type { PlaceProvider, PlaceSuggestion } from '@/application/ports';
import { PlaceProviderError } from '@/application/ports';

// Simulated place catalogue for Amman. Coordinates are approximate demo values,
// not provider data. "سوبرماركت الخالد" is the illustrative landmark from the SRS.

interface MockPlace extends PlaceSuggestion {
  aliases: string[];
}

const PLACES: MockPlace[] = [
  // الجبيهة
  { id: 'p-khaled', name: 'سوبرماركت الخالد', context: 'الجبيهة، عمّان', kind: 'business', position: { lat: 32.0235, lng: 35.8712 }, aliases: ['الخالد', 'al khaled supermarket', 'khaled', 'jubaiha'] },
  { id: 'p-uj', name: 'الجامعة الأردنية — البوابة الرئيسية', context: 'الجبيهة، عمّان', kind: 'landmark', position: { lat: 32.0152, lng: 35.8727 }, aliases: ['الجامعه الاردنيه', 'university of jordan', 'uj'] },
  { id: 'p-manhal', name: 'دوار المنهل', context: 'الجبيهة، عمّان', kind: 'landmark', position: { lat: 32.0302, lng: 35.8648 }, aliases: ['المنهل', 'manhal'] },
  { id: 'p-yajouz', name: 'شارع ياجوز', context: 'الجبيهة، عمّان', kind: 'street', position: { lat: 32.0355, lng: 35.8805 }, aliases: ['ياجوز', 'yajouz street'] },
  { id: 'p-jubaiha', name: 'الجبيهة', context: 'حي — عمّان', kind: 'neighborhood', position: { lat: 32.0250, lng: 35.8700 }, aliases: ['al jubaiha', 'jubaiha', 'الجبيهه'] },
  // تلاع العلي
  { id: 'p-waha', name: 'دوار الواحة', context: 'تلاع العلي، عمّان', kind: 'landmark', position: { lat: 31.9952, lng: 35.8602 }, aliases: ['الواحه', 'waha circle'] },
  { id: 'p-gardens', name: 'شارع وصفي التل (الجاردنز)', context: 'تلاع العلي، عمّان', kind: 'street', position: { lat: 31.9905, lng: 35.8660 }, aliases: ['الجاردنز', 'gardens', 'wasfi al tal'] },
  { id: 'p-rania', name: 'شارع الملكة رانيا', context: 'تلاع العلي، عمّان', kind: 'street', position: { lat: 32.0025, lng: 35.8705 }, aliases: ['الملكه رانيا', 'queen rania street'] },
  { id: 'p-tla', name: 'تلاع العلي', context: 'حي — عمّان', kind: 'neighborhood', position: { lat: 31.9990, lng: 35.8620 }, aliases: ["tla' al-ali", 'tla al ali'] },
  // خلدا
  { id: 'p-citymall', name: 'سيتي مول', context: 'خلدا، عمّان', kind: 'business', position: { lat: 31.9893, lng: 35.8342 }, aliases: ['city mall', 'سيتي مول'] },
  { id: 'p-khalda-circle', name: 'دوار خلدا', context: 'خلدا، عمّان', kind: 'landmark', position: { lat: 31.9992, lng: 35.8302 }, aliases: ['khalda circle'] },
  { id: 'p-amer', name: 'شارع عامر بن مالك', context: 'خلدا، عمّان', kind: 'street', position: { lat: 32.0052, lng: 35.8252 }, aliases: ['عامر بن مالك', 'amer bin malik'] },
  { id: 'p-khalda', name: 'خلدا', context: 'حي — عمّان', kind: 'neighborhood', position: { lat: 31.9975, lng: 35.8300 }, aliases: ['khalda'] },
  // أم أذينة
  { id: 'p-uthaina', name: 'دوار أم أذينة', context: 'أم أذينة، عمّان', kind: 'landmark', position: { lat: 31.9762, lng: 35.8652 }, aliases: ['ام اذينه', 'um uthaina'] },
  { id: 'p-saad', name: 'شارع سعد بن أبي وقاص', context: 'أم أذينة، عمّان', kind: 'street', position: { lat: 31.9782, lng: 35.8702 }, aliases: ['سعد بن ابي وقاص'] },
  // الصويفية
  { id: 'p-wakalat', name: 'شارع الوكالات', context: 'الصويفية، عمّان', kind: 'street', position: { lat: 31.9572, lng: 35.8602 }, aliases: ['الوكالات', 'wakalat street'] },
  { id: 'p-sweifieh', name: 'دوار الصويفية', context: 'الصويفية، عمّان', kind: 'landmark', position: { lat: 31.9552, lng: 35.8552 }, aliases: ['الصويفيه', 'sweifieh'] },
  // الشميساني
  { id: 'p-sharaf', name: 'شارع عبد الحميد شرف', context: 'الشميساني، عمّان', kind: 'street', position: { lat: 31.9702, lng: 35.9002 }, aliases: ['عبدالحميد شرف', 'shmeisani'] },
  { id: 'p-thaqafa', name: 'شارع الثقافة', context: 'الشميساني، عمّان', kind: 'street', position: { lat: 31.9722, lng: 35.9052 }, aliases: ['الثقافه', 'culture street'] },
  // عبدون
  { id: 'p-taj', name: 'تاج مول', context: 'عبدون، عمّان', kind: 'business', position: { lat: 31.9422, lng: 35.8852 }, aliases: ['taj mall'] },
  { id: 'p-abdoun-bridge', name: 'جسر عبدون', context: 'عبدون، عمّان', kind: 'landmark', position: { lat: 31.9462, lng: 35.8932 }, aliases: ['abdoun bridge', 'عبدون'] },
  // Outside the seeded service areas — used to demonstrate the out-of-area state.
  { id: 'p-mecca', name: 'مكة مول', context: 'عمّان', kind: 'business', position: { lat: 31.9762, lng: 35.8432 }, aliases: ['mecca mall', 'مكه مول'] },
  { id: 'p-downtown', name: 'وسط البلد', context: 'عمّان', kind: 'neighborhood', position: { lat: 31.9516, lng: 35.9340 }, aliases: ['downtown', 'البلد'] },
  { id: 'p-airport', name: 'مطار الملكة علياء الدولي', context: 'عمّان', kind: 'landmark', position: { lat: 31.7225, lng: 35.9932 }, aliases: ['airport', 'المطار'] },
  { id: 'p-zarqa', name: 'الزرقاء — وسط المدينة', context: 'الزرقاء', kind: 'neighborhood', position: { lat: 32.0728, lng: 36.0880 }, aliases: ['zarqa', 'الزرقاء'] },
  // A provider result without usable coordinates (SRS §5.4 failure case).
  { id: 'p-nocoords', name: 'مجمع النخيل التجاري (بلا إحداثيات)', context: 'نتيجة ناقصة من المزوّد', kind: 'business', position: null, aliases: ['النخيل', 'nakheel'] },
];

const STOP_WORDS = new Set(['بجانب', 'جنب', 'قرب', 'بالقرب', 'من', 'عند', 'مقابل', 'خلف', 'بجوار', 'next', 'to', 'near', 'the', 'by', 'opposite', 'behind', 'شارع']);

/** Normalizes Arabic letter variants and strips diacritics/punctuation. */
export function normalizeArabic(text: string): string {
  return text
    .toLowerCase()
    .replace(/[ً-ْـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/[،,.'’\-—()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(query: string): string[] {
  return normalizeArabic(query)
    .split(' ')
    .filter((t) => t.length > 1 && !STOP_WORDS.has(t))
    .map((t) => t.replace(/^ال(?=..)/, ''));
}

function score(place: MockPlace, tokens: string[]): number {
  const haystack = normalizeArabic([place.name, place.context, ...place.aliases].join(' '));
  const nameHay = normalizeArabic(place.name);
  let s = 0;
  for (const t of tokens) {
    if (nameHay.includes(t)) s += 3;
    else if (haystack.includes(t)) s += 1;
  }
  return s;
}

export class MockPlaceProvider implements PlaceProvider {
  readonly isSimulated = true;

  constructor(private readonly isDown: () => boolean) {}

  async search(query: string, signal?: AbortSignal): Promise<PlaceSuggestion[]> {
    await new Promise<void>((resolve, reject) => {
      const t = setTimeout(resolve, 280);
      signal?.addEventListener('abort', () => {
        clearTimeout(t);
        reject(new DOMException('aborted', 'AbortError'));
      });
    });
    if (this.isDown()) throw new PlaceProviderError('place provider unavailable');
    const tokens = tokenize(query);
    if (tokens.length === 0) return [];
    return PLACES.map((p) => ({ p, s: score(p, tokens) }))
      .filter((x) => x.s > 0)
      .sort((a, b) => b.s - a.s || (a.p.kind === 'neighborhood' ? 1 : -1))
      .slice(0, 7)
      .map(({ p }) => ({ id: p.id, name: p.name, context: p.context, kind: p.kind, position: p.position }));
  }
}
