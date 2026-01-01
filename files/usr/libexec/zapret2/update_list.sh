#!/bin/sh

set -e

LIST_NAME="$1"
CONFIG_FILE="/etc/config/zapret2"
CACHE_DIR="/var/lib/zapret/lists"
LOG_FILE="/var/log/zapret_update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Создаем директории если нет
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting update for list: $LIST_NAME"

# Получаем URL из конфигурации
URL=$(uci -q get zapret2.$LIST_NAME.url)
if [ -z "$URL" ]; then
    log "ERROR: No URL found for list $LIST_NAME"
    exit 1
fi

# Определяем тип списка
LIST_TYPE=$(uci -q get zapret2.$LIST_NAME.type || echo "domains")
LIST_FILE="$CACHE_DIR/${LIST_NAME}.list"

log "Downloading from: $URL"
log "Type: $LIST_TYPE"
log "Output: $LIST_FILE"

# Скачиваем список
TEMP_FILE="/tmp/zapret_list_$$.tmp"

if echo "$URL" | grep -q "^file://"; then
    # Локальный файл
    LOCAL_FILE="${URL#file://}"
    if [ -f "$LOCAL_FILE" ]; then
        cp "$LOCAL_FILE" "$TEMP_FILE"
        log "Copied local file: $LOCAL_FILE"
    else
        log "ERROR: Local file not found: $LOCAL_FILE"
        exit 1
    fi
else
    # Удаленный URL
    if echo "$URL" | grep -q "\.csv$"; then
        # CSV формат (dump.csv)
        wget -q -O "$TEMP_FILE" "$URL" || {
            log "ERROR: Failed to download CSV from $URL"
            exit 1
        }
        
        # Конвертируем CSV в список доменов
        awk -F';' '{print $2}' "$TEMP_FILE" | grep -v "^$" | sort -u > "${TEMP_FILE}.clean"
        mv "${TEMP_FILE}.clean" "$TEMP_FILE"
        
    elif echo "$URL" | grep -q "\.txt$"; then
        # Текстовый формат
        wget -q -O "$TEMP_FILE" "$URL" || {
            log "ERROR: Failed to download TXT from $URL"
            exit 1
        }
        
    else
        # Другой формат, пытаемся скачать как есть
        wget -q -O "$TEMP_FILE" "$URL" || {
            log "ERROR: Failed to download from $URL"
            exit 1
        }
    fi
fi

# Обрабатываем список в зависимости от типа
case "$LIST_TYPE" in
    "domains")
        # Извлекаем домены
        grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$TEMP_FILE" | sort -u > "$LIST_FILE"
        ;;
    "ips")
        # Извлекаем IP-адреса
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' "$TEMP_FILE" | sort -u > "$LIST_FILE"
        ;;
    "urls")
        # Копируем как есть (URL-паттерны)
        grep -v "^#" "$TEMP_FILE" | grep -v "^$" | sort -u > "$LIST_FILE"
        ;;
    "mixed")
        # Оставляем как есть
        grep -v "^#" "$TEMP_FILE" | grep -v "^$" | sort -u > "$LIST_FILE"
        ;;
    *)
        # По умолчанию - домены
        grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$TEMP_FILE" | sort -u > "$LIST_FILE"
        ;;
esac

# Подсчитываем количество записей
COUNT=$(wc -l < "$LIST_FILE")
log "List processed. Entries: $COUNT"

# Обновляем конфигурацию
uci set zapret2.$LIST_NAME.entries="$COUNT"
uci commit zapret2

# Очистка
rm -f "$TEMP_FILE"

# Перезапускаем zapret если он запущен
if pgrep -f zapret >/dev/null; then
    log "Restarting zapret service..."
    /etc/init.d/zapret restart >/dev/null 2>&1 || true
fi

log "Update completed successfully for list: $LIST_NAME"
echo "Successfully updated $LIST_NAME with $COUNT entries"
