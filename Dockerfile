FROM python:3.12-slim

RUN useradd --create-home appuser

WORKDIR /app

RUN pip install poetry==1.8.2 --no-cache-dir

COPY pyproject.toml poetry.lock ./

RUN poetry config virtualenvs.create false \
    && poetry install --only main --no-interaction --no-ansi

COPY app.py ./
COPY templates/ ./templates/

USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
