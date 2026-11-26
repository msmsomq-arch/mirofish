# Build the Vue frontend with a supported Node.js version.
FROM node:22-bookworm-slim AS frontend-build
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN npm ci --prefix frontend
COPY frontend ./frontend
COPY locales ./locales
RUN npm run build --prefix frontend

# Runtime image: Flask serves both the API and the compiled frontend.
FROM python:3.11
WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/
COPY backend/pyproject.toml backend/uv.lock ./backend/
RUN cd backend && uv sync --frozen --no-dev

COPY backend ./backend
COPY --from=frontend-build /app/frontend/dist ./frontend/dist

RUN pip install --no-cache-dir gunicorn

ENV PYTHONUNBUFFERED=1
ENV FLASK_DEBUG=false
WORKDIR /app/backend

EXPOSE 10000
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 4 --timeout 180 'app:create_app()'"]
