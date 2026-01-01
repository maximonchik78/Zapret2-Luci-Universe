#!/bin/sh

set -e

CONFIG_FILE="/etc/config/zapret2"
LOG_FILE="/var/log/zapret_update.log"
CACHE_DIR="/var/lib/zapret/lists"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Создаем директории если нет
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting update of all block lists"

# Получаем все списки из конфигурации
LISTS=$(uci show zapret2 | grep "=list$" | cut -d'.' -f2 | cut -d'=' -f1)

if [ -z "$LISTS" ]; then
    log "No block lists found in configuration"
    exit 0
fi

TOTAL_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_LISTS=""

for LIST in $LISTS; do
    # Проверяем включен ли список
    ENABLED=$(uci -q get zapret2.$LIST.enabled || echo "1")
    
    if [ "$ENABLED" = "1" ]; then
        log "Updating list: $LIST"
        
        if /usr/libexec/zapret2/update_list.sh "$LIST" >> "$LOG_FILE" 2>&1; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            ENTRIES=$(uci -q get zapret2.$LIST.entries || echo "0")
            TOTAL_COUNT=$((TOTAL_COUNT + ENTRIES))
            log "✓ Successfully updated $LIST ($ENTRIES entries)"
        else
            FAILED_COUNT=$((FAILED_COUNT + 1))
            FAILED_LISTS="$FAILED_LISTS $LIST"
            log "✗ Failed to update $LIST"
        fi
        
        # Задержка между обновлениями чтобы не перегружать сеть
        sleep 2
    else
        log "Skipping disabled list: $LIST"
    fi
done

# Сводка
log "========================================"
log "Update Summary:"
log "  Total lists: $(echo $LISTS | wc -w)"
log "  Successfully updated: $SUCCESS_COUNT"
log "  Failed: $FAILED_COUNT"
log "  Total entries: $TOTAL_COUNT"

if [ -n "$FAILED_LISTS" ]; then
    log "  Failed lists:$FAILED_LISTS"
fi
log "========================================"

# Создаем отчет
REPORT_FILE="/tmp/zapret_update_report.txt"
cat > "$REPORT_FILE" << EOF
Zapret2 Block Lists Update Report
Generated: $(date)

Summary:
--------
Total lists configured: $(echo $LISTS | wc -w)
Successfully updated: $SUCCESS_COUNT
Failed: $FAILED_COUNT
Total entries in all lists: $TOTAL_COUNT

Updated lists:
-------------
EOF

for LIST in $LISTS; do
    ENABLED=$(uci -q get zapret2.$LIST.enabled || echo "1")
    if [ "$ENABLED" = "1" ]; then
        ENTRIES=$(uci -q get zapret2.$LIST.entries || echo "0")
        echo "  - $LIST: $ENTRIES entries" >> "$REPORT_FILE"
    fi
done

if [ -n "$FAILED_LISTS" ]; then
    echo "" >> "$REPORT_FILE"
    echo "Failed lists:" >> "$REPORT_FILE"
    for LIST in $FAILED_LISTS; do
        echo "  - $LIST" >> "$REPORT_FILE"
    done
fi

echo "" >> "$REPORT_FILE"
echo "Next scheduled update:" >> "$REPORT_FILE"
echo "  Daily at $(uci -q get zapret2.config.update_hour || echo "3"):00" >> "$REPORT_FILE"

log "Report saved to: $REPORT_FILE"

# Перезапускаем zapret если нужно
if [ "$SUCCESS_COUNT" -gt 0 ] && pgrep -f zapret >/dev/null; then
    log "Restarting zapret service to apply changes..."
    /etc/init.d/zapret restart >/dev/null 2>&1 || true
    log "Zapret service restarted"
fi

# Очищаем старые кэшированные списки (старше 7 дней)
find "$CACHE_DIR" -name "*.list" -mtime +7 -delete 2>/dev/null || true

log "All updates completed"
echo "Update completed: $SUCCESS_COUNT lists updated, $TOTAL_COUNT total entries"
