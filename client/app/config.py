"""Settings read from environment variables (nothing is hard-coded)."""
import os


class Config:
    # "mock": purchases are simulated in the browser (static/js/mock-api.js).
    # "http": the browser calls /api/buy and /api/purchases on this same origin,
    #         which your backend will provide.
    API_MODE = os.getenv("API_MODE", "mock").lower()

    # How often the browser re-checks pending orders (milliseconds).
    POLL_INTERVAL_MS = int(os.getenv("POLL_INTERVAL_MS", "1500"))

    # Static files carry a content hash in their URL, so they can be cached for a year.
    SEND_FILE_MAX_AGE_DEFAULT = 60 * 60 * 24 * 365
