# RideDispatch

A simple, fast, mobile-first web app that replaces phone-call ride dispatching
with a live dashboard. Captains submit pickup/dropoff via Google Maps search;
the Admin sees everything update in real time and accepts/completes rides
with one tap.

---

## ✨ Features

- **Two roles only:** one Admin (full dashboard) and unlimited Captains (self-registering, no email/OTP).
- **Permanent login** — captains stay logged in until they manually log out.
- **Google Maps Places search** for pickup & dropoff, with live route preview (Directions API).
- **Real-time updates** via Django Channels + WebSockets — no page refresh needed.
- **Daily automatic reset** of ride history at midnight (captain accounts are untouched).
- **Search & filter** rides by captain name / status on the Admin dashboard.
- **Dark mode / Light mode** toggle (persisted in the browser).
- **Clean Bootstrap 5 UI** — no animations, no clutter, mobile-first.

---

## 📁 Folder Structure

```
ridedispatch/
├── ridedispatch/        # Project settings, ASGI, URLs
├── accounts/             # Captain registration/login (CaptainProfile model)
├── rides/                 # RideRequest model, submit/accept/complete views
├── dashboard/             # Admin & Captain dashboard views
├── notifications/         # WebSocket consumer + daily reset scheduler
├── templates/              # All HTML templates (base, accounts, dashboard)
├── static/
│   ├── css/main.css        # All styling (light + dark mode)
│   └── js/
│       ├── captain.js       # Maps, ride form, WebSocket (captain side)
│       ├── admin.js          # Live feed, filters, accept/done (admin side)
│       └── theme.js           # Dark mode toggle
├── requirements.txt
├── .env.example
├── setup.sh                 # One-command setup script
└── manage.py
```

---

## 🚀 Installation Guide

### 1. Prerequisites
- Python 3.10+
- A Google Cloud project with **Maps JavaScript API**, **Places API**, and
  **Directions API** enabled, and an API key with those APIs allowed
  (https://console.cloud.google.com/google/maps-apis).

### 2. Setup

```bash
# Clone / unzip the project, then:
cd ridedispatch
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate

cp .env.example .env
# Edit .env and paste your GOOGLE_MAPS_API_KEY and a SECRET_KEY

# Export the env vars (or use django-environ / python-dotenv if preferred)
export $(cat .env | xargs)    # Windows: use `set` per line instead

chmod +x setup.sh
./setup.sh
```

The `setup.sh` script installs dependencies, runs migrations, prompts you to
create your **one Admin account** (`createsuperuser` — this account
automatically has `is_staff=True`, which is what makes it the Admin), and
collects static files.

### 3. Run the server

For full real-time WebSocket support, run with **Daphne** (not the plain dev server):

```bash
daphne -b 0.0.0.0 -p 8000 ridedispatch.asgi:application
```

Or, for quick local testing without WebSockets working fully:

```bash
python manage.py runserver
```

Visit `http://127.0.0.1:8000/` — you'll be redirected to login.

- **Admin** logs in with the superuser credentials → sees the full dashboard at `/dashboard/admin/`.
- **Captains** register themselves at `/accounts/register/` → land on `/dashboard/captain/`.

---

## ⏰ Daily Reset (choose one)

**Option A — Built-in scheduler (already wired up):**
APScheduler starts automatically inside `notifications/apps.py` and deletes
all ride requests every day at midnight server time. No extra setup needed
when running via Daphne.

**Option B — System cron (more reliable for production):**
```bash
crontab -e
# Add this line (adjust paths):
0 0 * * * cd /path/to/ridedispatch && /path/to/venv/bin/python manage.py reset_rides
```
If you use cron, you can remove the APScheduler block in `notifications/apps.py`
to avoid double-resets.

---

## 🗄️ Database Models

| Model | Purpose |
|---|---|
| `User` (Django built-in) | Both Admin and Captains. `is_staff=True` = Admin. |
| `CaptainProfile` | Extends User — tracks online status, last seen. |
| `RideRequest` | One row per captain per ride slot (1/2/3) per day. Holds pickup/dropoff names, lat/lng, status, timestamps. |

Status flow: `pending → accepted → done`. Daily reset truncates `RideRequest` only.

---

## 🔒 Security

- CSRF protection on all POST endpoints (Django default + JS fetch headers).
- All views require authentication (`@login_required`); Admin-only actions check `is_staff`.
- Django ORM only — no raw SQL, so standard SQL-injection protection applies.
- Django's built-in password hashing (PBKDF2) for all accounts.
- Admin panel at `/admin/` uses Django's own auth and is staff-only by default.

---

## 🧩 Tech Stack

- **Backend:** Django 5, Django Channels (WebSockets), SQLite
- **Frontend:** HTML, vanilla JavaScript, Bootstrap 5, Bootstrap Icons
- **Maps:** Google Maps JavaScript API, Places API, Directions API
- **Scheduler:** APScheduler (in-process) or system cron

---

## 🛠️ Customization Notes

- Default map center is set to Karachi (`24.8607, 67.0011`) in `static/js/captain.js` — change `defaultCenter` to your city.
- To allow more than 3 ride slots, update `SLOT_CHOICES` in `rides/models.py` and the loop in `templates/dashboard/captain.html`.
- For production, swap `CHANNEL_LAYERS` in `settings.py` to use Redis instead of `InMemoryChannelLayer` (needed if you run multiple server processes).
