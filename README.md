# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend updating the configuration to enable type-aware lint rules:

```js
export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...

      // Remove tseslint.configs.recommended and replace with this
      tseslint.configs.recommendedTypeChecked,
      // Alternatively, use this for stricter rules
      tseslint.configs.strictTypeChecked,
      // Optionally, add this for stylistic rules
      tseslint.configs.stylisticTypeChecked,

      // Other configs...
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

## Deploy on Vercel

- Frontend is a Vite React app; serverless API lives under `/api`.
- Live parking data is served by `api/ucf-parking.ts` and consumed by the UI.

Steps
- Push to GitHub/GitLab and import the repo in Vercel.
- Framework preset: Vite (auto-detected).
- Build command: `vite build` (auto). Output: `dist` (auto).
- Deploy. The API will be available at `/api/ucf-parking` on your domain.

Files
- `api/ucf-parking.ts:1` — Edge function that fetches the UCF availability page, parses to JSON, and caches for 60s.
- `src/services/ucfParking.ts:1` — Client fetches `/api/ucf-parking` first; in dev it can parse proxied HTML.
- `src/pages/UCFParkingPage.tsx:1` — UI renders live data with loading/error states and auto-refresh.
- `vite.config.ts:1` — Dev-only proxy for local CORS-free testing (`/api/ucf-parking` and `/proxy/ucf-parking`).

Local development
- `npm run dev` uses the Vite proxy so `/api/ucf-parking` works without a server.
- Optional: `vercel dev` to emulate Vercel locally.

Notes
- The Edge function includes a 60s in-memory cache to reduce upstream requests.
- If UCF markup changes, update the parsing logic in `api/ucf-parking.ts` (or `src/services/ucfParking.ts` for dev).
