#!/bin/bash

SITE_URL="http://localhost"
WEBHOOK_URL="COLOQUE A URL DO SEU WEBHOOK AQUI"
LOG_FILE="/var/log/monitoramento.log"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" $SITE_URL)
TIMESTAMP=$(date "+%d-%m-%Y %H:%M:%S")

if [ $HTTP_STATUS -ne 200 ]; then
    LOG_MESSAGE="[$TIMESTAMP] ALERTA: Site indisponível! Status HTTP: $HTTP_STATUS"
    JSON_PAYLOAD="{\"content\": \"🚨 **Alerta de Inatividade!** 🚨\nO site está fora do ar. Código de status: $HTTP_STATUS\"}"
    curl -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" $WEBHOOK_URL
else
    LOG_MESSAGE="[$TIMESTAMP] SUCESSO: Site funcionando normalmente. Status HTTP: $HTTP_STATUS"
fi

echo $LOG_MESSAGE | sudo tee -a $LOG_FILE