#!/bin/bash
# ScamShield Lao — Start Backend Server
set -e

cd "$(dirname "$0")/backend"

# Create .env if it doesn't exist
if [ ! -f .env ]; then
  cp .env.example .env
  echo "⚠  Created backend/.env — please add your OPENROUTER_API_KEY"
fi

# Activate venv
source venv/bin/activate

echo "🚀 Starting ScamShield Lao backend on http://localhost:8000"
echo "📚 API docs: http://localhost:8000/docs"
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
