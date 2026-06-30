#!/bin/bash
# Quick setup script — run this after installing requirements.txt
set -e

echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo "🗄️  Applying migrations..."
python manage.py makemigrations accounts rides dashboard notifications
python manage.py migrate

echo "👤 Create your Admin account now:"
python manage.py createsuperuser

echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

echo ""
echo "✅ Setup complete!"
echo "Run the server with: python manage.py runserver"
echo "Or for WebSocket support (recommended): daphne -b 0.0.0.0 -p 8000 ridedispatch.asgi:application"
