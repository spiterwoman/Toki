mytoki.app

# Toki – Your Space Calendar Companion

Toki is a space-themed productivity web app that combines a daily agenda, calendar, weather, and NASA content into a single interface. It’s designed primarily for students and busy professionals who want a fun but focused way to keep track of their day.

> _“Your Space Calendar Companion”_ – daily summary, events, tasks all in one place.

---

## 🚀 Features

- **Authentication**
  - Email + password login and signup
  - Temporary password “reset” flow
  - Frontend integration with `POST /api/loginUser`
- **Daily Summary**
  - Shows today’s tasks and events in chronological order
  - Highlights priorities and reminders
- **Calendar View**
  - Month layout
  - Click through to view or manage events
- **Weather**
  - Simple summary for current conditions
  - High/low temperature, sunrise, and sunset
- **NASA Photo of the Day**
  - Surface the daily NASA image with title/description
- **UCF Parking Tracker**
  - UCF parking tracker
---

## 🧰 Tech Stack

**Frontend**

- [React](https://react.dev/)
- [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vitejs.dev/) (for dev server & build tooling)
- [React Router](https://reactrouter.com/) for client-side routing
- Custom components:
  - `PageShell` – layout wrapper, background, and navigation shell
  - `GlassCard` – reusable glassmorphism card
  - `Dialog` components (e.g. `Dialog`, `DialogContent`, `DialogHeader`, `DialogTitle`)

**Backend**

- An HTTP API providing endpoints such as:
  - `POST /api/loginUser` (login)
  - `POST /api/signup` (signup)
- Deployed under the same domain as the app (e.g. `https://mytoki.app/api/...`)
