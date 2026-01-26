# Notifications & Severity

**Channels**
- **Low** — Logbook only.
- **Normal** — Persistent Notification.
- **High** — Mobile App push.
- **Urgent** — Telegram (e.g., `notify.telegram_user_chat_id`).

**Expectations**
- Rate‑limit urgent messages (≥15 min between near‑duplicates).
- Keep messages short; use section dividers sparingly; minimal emoji (category icons like ⚡ 🏠 🌤️).
- For “changed behavior” notifications, prefer a one‑line summary + actionable next step.

**Examples (shape)**
- Title: `<icon> <Domain> — <Short Event>`
- Body: one‑line reason; optional next action
