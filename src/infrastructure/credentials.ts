/** Letters and digits without look-alikes (0/O, 1/l/I), so a handed-over password is read correctly. */
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
const LENGTH = 10;

/** One-time temporary password from the browser's CSPRNG (demo password reset). */
export function generateTemporaryPassword(): string {
  const bytes = new Uint32Array(LENGTH);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (n) => ALPHABET[n % ALPHABET.length]).join('');
}
