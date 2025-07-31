#!/bin/bash

apt update
apt upgrade -y
apt install nginx -y

# --------------------------
# Criação página padrão HTML
# --------------------------
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Projeto AWS</title>
</head>
<body>
    <h1>Olá, Mundo! Site configurado na AWS está no ar!</h1>
    <p>Este servidor foi configurado automaticamente na inicialização.</p>
</body>
</html>
EOF

# -----------------------------------------------------------------------------------------
# Mudar o usuário de ubuntu para ec2-user em todas as ocorrências se a AMI for Amazon Linux
# -----------------------------------------------------------------------------------------
mkdir -p /home/ubuntu/scripts

cat <<EOF > /home/ubuntu/scripts/monitoramento.sh
#!/bin/bash

SITE_URL="http://localhost"
# ---------------------------------
# COLOQUE A URL DO SEU WEBHOOK AQUI
# ---------------------------------
WEBHOOK_URL="SUA_URL_WEBHOOK_AQUI"
LOG_FILE="/var/log/monitoramento.log"
HTTP_STATUS=\$(curl -o /dev/null -s -w "%{http_code}" \$SITE_URL)
TIMESTAMP=\$(date "+%d-%m-%Y %H:%M:%S")

if [ \$HTTP_STATUS -ne 200 ]; then
    LOG_MESSAGE="[\$TIMESTAMP] ALERTA: Site indisponível! Status HTTP: \$HTTP_STATUS"
    JSON_PAYLOAD="{\\"content\\": \\"🚨 **Alerta de Inatividade!** 🚨\\nO site está fora do ar. Código de status: \$HTTP_STATUS\"}"
    curl -H "Content-Type: application/json" -X POST -d "\$JSON_PAYLOAD" \$WEBHOOK_URL
else
    LOG_MESSAGE="[\$TIMESTAMP] SUCESSO: Site funcionando normalmente. Status HTTP: \$HTTP_STATUS"
fi

echo \$LOG_MESSAGE | sudo tee -a \$LOG_FILE
EOF

chmod +x /home/ubuntu/scripts/monitoramento.sh
touch /var/log/monitoramento.log
echo "* * * * * /home/ubuntu/scripts/monitoramento.sh" | crontab -u ubuntu -

systemctl start nginx