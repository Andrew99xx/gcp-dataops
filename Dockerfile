# api/Dockerfile
FROM python:3.11-slim

# Create & switch to app directory
WORKDIR /app

# Copy and install only the runtime requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the FastAPI app
COPY main.py .

# The PORT env‐var is picked up by uvicorn below
ENV PORT=8080
EXPOSE 8080

# Start the app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
