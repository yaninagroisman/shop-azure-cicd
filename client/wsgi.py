"""Entry point used by Gunicorn (and `flask run`)."""
from app import create_app

app = create_app()
