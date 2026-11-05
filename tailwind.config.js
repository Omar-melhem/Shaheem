/** @type {import('tailwindcss').Config} */
// SHAHM brand palette supplied by the Product Owner:
// #8C2335 maroon · #263D34 forest · #242424 ink · #F5F0E8 cream · #C8A98A sand
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#FBF2F4', 100: '#F5E0E4', 200: '#E9BCC5', 300: '#D58E9C', 400: '#B85468',
          500: '#8C2335', 600: '#7A1E2E', 700: '#641826', 800: '#4E131E', 900: '#3A0E16',
          DEFAULT: '#8C2335',
        },
        secondary: {
          50: '#EEF3F1', 100: '#D6E2DD', 200: '#ADC5BB', 300: '#7FA294', 400: '#4F7466',
          500: '#263D34', 600: '#20342C', 700: '#1A2A24', 800: '#14201B', 900: '#0E1613',
          DEFAULT: '#263D34',
        },
        ink: { DEFAULT: '#242424', soft: '#4A4A4A', muted: '#6E6A64' },
        cream: { DEFAULT: '#F5F0E8', dark: '#EDE5D8', deep: '#E3D8C6' },
        sand: { DEFAULT: '#C8A98A', light: '#E6D6C5', dark: '#A88866' },
      },
      fontFamily: {
        sans: ['Tajawal', 'system-ui', 'sans-serif'],
      },
      // One-time entrance motion (login). Elements stay usable during it; disabled under reduced motion.
      keyframes: {
        rise: { from: { opacity: '0', transform: 'translateY(10px)' }, to: { opacity: '1', transform: 'none' } },
        fade: { from: { opacity: '0' }, to: { opacity: '1' } },
      },
      animation: {
        rise: 'rise 500ms cubic-bezier(0.2, 0.7, 0.2, 1) both',
        fade: 'fade 600ms ease-out both',
      },
      boxShadow: {
        card: '0 1px 2px rgba(36,36,36,0.06), 0 1px 3px rgba(36,36,36,0.08)',
        pop: '0 10px 30px rgba(36,36,36,0.18)',
      },
    },
  },
  plugins: [],
};
