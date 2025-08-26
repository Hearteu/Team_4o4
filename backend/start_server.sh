#!/bin/bash

# Activate virtual environment
source venv/bin/activate

# Run Django development server
echo "Starting Django development server..."
echo "API will be available at: http://localhost:8000/api/"
echo "Admin interface at: http://localhost:8000/admin/"
echo "Press Ctrl+C to stop the server"
echo ""

python manage.py runserver 0.0.0.0:8000
