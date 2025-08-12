# 🐍 Etapa 1: Imagen base con Python
FROM python:3.11-slim as base

# 🔒 Evita errores por inputs interactivos
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 🧹 Instala dependencias del sistema
RUN apt-get update && apt-get install -y build-essential

# 📁 Crea directorio de la app
WORKDIR /app

# 📦 Copia e instala dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 📦 Copia el código fuente
COPY . .

# 🚀 Comando para ejecutar con Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
