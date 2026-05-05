#!/bin/bash

# ---------- Configuración ----------
BACKEND_LOCALE_DIR="./backend/myngo_api/locale"
LANGUAGES=("es" "en")  # Ajusta según tus idiomas

# Variables de entorno requeridas:
# TOLGEE_API_KEY, TOLGEE_API_URL (opcional, usa http://127.0.0.1:8085 por defecto)
# TOLGEE_PROJECT_ID (opcional si solo usas push/pull con path explícito)

ACTION=$1

# Verificar que la API key está presente
if [ -z "$TOLGEE_API_KEY" ]; then
    echo "❌ Error: TOLGEE_API_KEY no está definida en el entorno."
    exit 1
fi

# Construir argumentos comunes para la CLI
CLI_OPTS="--apiKey $TOLGEE_API_KEY"
if [ -n "$TOLGEE_API_URL" ]; then
    CLI_OPTS="$CLI_OPTS --apiUrl $TOLGEE_API_URL"
fi
if [ -n "$TOLGEE_PROJECT_ID" ]; then
    CLI_OPTS="$CLI_OPTS --projectId $TOLGEE_PROJECT_ID"
fi

push_backend() {
    echo "📤 Subiendo archivos .po a Tolgee..."
    for lang in "${LANGUAGES[@]}"; do
        PO_FILE="$BACKEND_LOCALE_DIR/$lang/LC_MESSAGES/django.po"
        if [ -f "$PO_FILE" ]; then
            echo "   Subiendo $lang: $PO_FILE"
            npx @tolgee/cli push $CLI_OPTS --path "$PO_FILE" --language "$lang" --format PO
            if [ $? -ne 0 ]; then
                echo "⚠️  Error al subir $lang"
            fi
        else
            echo "⚠️  No se encuentra $PO_FILE, omitiendo..."
        fi
    done
    echo "✅ Subida completada."
}

pull_backend() {
    echo "📥 Descargando archivos .po desde Tolgee..."
    for lang in "${LANGUAGES[@]}"; do
        PO_FILE="$BACKEND_LOCALE_DIR/$lang/LC_MESSAGES/django.po"
        # Asegurar que el directorio existe
        mkdir -p "$(dirname "$PO_FILE")"
        echo "   Descargando $lang -> $PO_FILE"
        npx @tolgee/cli pull $CLI_OPTS --path "$PO_FILE" --language "$lang" --format PO
        if [ $? -ne 0 ]; then
            echo "⚠️  Error al descargar $lang"
        fi
    done
    echo "✅ Descarga completada."
}

# ---------- Main ----------
if [ "$ACTION" == "push" ]; then
    push_backend
elif [ "$ACTION" == "pull" ]; then
    pull_backend
else
    echo "Uso: ./sync_translations.sh [push|pull]"
    exit 1
fi