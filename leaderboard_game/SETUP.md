# Setup

**Reflex** — a reaction-time click game with a leaderboard. No accounts, no email, no PII — just a freely-chosen display name and a score.

## Local setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# edit .env with real values, especially DJANGO_SECRET_KEY and DB_PASSWORD
```

Generate a real secret key:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Create the Postgres database and user (adjust to your local Postgres setup):
```sql
CREATE DATABASE leaderboard;
CREATE USER leaderboard_user WITH PASSWORD 'change-me';
GRANT ALL PRIVILEGES ON DATABASE leaderboard TO leaderboard_user;
```

Load environment variables and run migrations:
```bash
export $(cat .env | xargs)
python manage.py migrate
python manage.py runserver
```

Visit `http://127.0.0.1:8000`.

## Notes

- `name` is validated server-side (letters/numbers/spaces/-/_, max 20 chars) — no free-form HTML, no script injection surface.
- Leaderboard rendering uses `textContent`, not `innerHTML`, on the client side — defense in depth against XSS even though the backend already validates input.
- `time_ms` is bounds-checked (50–10000ms) to reject obviously spoofed submissions without needing authentication.
- No IP addresses or any other identifying data are stored in the database.
