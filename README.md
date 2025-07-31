# Infraestrutura Web na AWS com Monitoramento Automatizado

## Descrição do Projeto

Este projeto consiste na criação e configuração de uma infraestrutura Web na Amazon Web Services (AWS). O objetivo principal é provisionar um ambiente seguro e resiliente para hospedar uma aplicação web, garantindo que ela permaneça disponível e operacional. Para isso, foi configurado um servidor web Nginx em uma instância EC2, dentro de uma VPC customizada.

Um dos pilares do projeto é a confiabilidade, alcançada através da implementação de um script de monitoramento automatizado. Esse script verifica continuamente a saúde do servidor web e, em caso de qualquer indisponibilidade, dispara notificações instantâneas via webhook para um canal do Discord, permitindo uma resposta rápida a incidentes. Adicionalmente, o projeto explora a automação da infraestrutura com o uso do `User Data` da EC2, permitindo que todo o ambiente seja configurado de forma automática no momento da inicialização do servidor.

---

## O que foi utilizado no projeto

* **AWS:** EC2, VPC, Sub-redes
* **AMI:** Ubuntu (ou Amazon Linux)
* **Servidor Web:** Nginx
* **Notificações:** Discord (via Webhook)
* **Automação:** User Data, Bash, Cron, cURL

---

## Guia de Implementação

### 1. Configuração do Ambiente na AWS

A base de todo o projeto é uma infraestrutura de rede robusta e isolada, construída com os seguintes componentes:

* **VPC (Virtual Private Cloud):** Foi criada uma VPC customizada para ser o perímetro de segurança da rede na nuvem. A VPC foi projetada com duas sub-redes públicas, para recursos que precisam de acesso à internet (como o servidor web), e duas sub-redes privadas, para recursos de back-end que devem permanecer isolados (como bancos de dados futuros).
* **EC2 (Elastic Compute Cloud):** Uma instância EC2, que funciona como um servidor virtual, foi lançada em uma das sub-redes públicas. É nesta máquina que a aplicação web e o script de monitoramento irão operar.
* **Security Group:** Foi configurado um Security Group para controlar o tráfego de entrada e saída. As regras essenciais configuradas foram:
    * **Porta `22` (SSH):** Liberada para acesso administrativo ao terminal.
    * **Porta `80` (HTTP):** Liberada para acesso público ao site.
* **Importante:** É possível automatizar toda a configuração do servidor usando um script de `User Data` durante a criação da instância EC2. Se seu objetivo é aprender o processo passo a passo, siga as instruções na ordem apresentada para a implementação manual. Caso contrário, sinta-se à vontade para avançar diretamente para a seção **automação com User Data**.

### 2. Configuração do Servidor Web (Nginx)

Com a instância no ar, o servidor web foi instalado e configurado via SSH.

* **Instalação do Nginx:** O Nginx foi escolhido por sua alta performance e eficiência. A instalação foi feita através do gerenciador de pacotes `apt`, após a atualização do sistema para garantir que todos os softwares estivessem em suas versões mais recentes e seguras.
    ```
    sudo apt update
    sudo apt upgrade -y
    sudo apt install nginx -y
    ```

* **Criação da Página HTML:** Para validar o funcionamento do servidor, uma página `index.html` customizada foi criada. Este arquivo serve como a "fachada" do site e foi colocado no diretório raiz do Nginx (`/var/www/html/`). Como este diretório é protegido, é necessário o uso do `sudo` para criar/editar arquivos aqui. 

    * Para criação da página html foi usado o comando `sudo nano index.html`
    ```
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
    ```

### 3. Script de Monitoramento

Para garantir a alta disponibilidade do site, foi o seguinte script de monitoramento em Bash.

* **Código-fonte do Script:**
    ```
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
    ```
* **Funcionamento:** O script usa o `curl` para fazer uma requisição HTTP interna ao servidor web (`http://localhost`). Ele analisa o código de status da resposta. Um status `200` (OK) indica que o site está saudável. Qualquer outro status é tratado como uma falha, o que dispara um alerta.
* **Notificações e Logs:** Em caso de falha, o script envia imediatamente uma mensagem detalhada para um canal do Discord através de um webhook. Simultaneamente, toda e qualquer verificação, seja de sucesso ou falha, é registrada com data e hora em um arquivo de log localizado em `/var/log/monitoramento.log`, criando um histórico de disponibilidade do serviço.    
* **Importante:** É necessário dar ao código a permissão para ser executado. Isso pode ser feito com o comando abaixo.\
    `chmod +x /caminho_para_o_arquivo/arquivo.sh`

### 4. Rodar o script de forma automática a cada minuto
 
Para automatizar o script, realizando o monitoramento a cada minuto, foi utilizado Cron.

* **Edição na ferramenta crontab:**\
    `crontab -e`

* **Adição da seguinte linha de comando para definir o tempo:**\
    `* * * * * /caminho_para_o_arquivo/arquivo.sh`
    * A entrada `* * * * *` define um tempo de 1 minuto entre cada chamada ao script passado. Para alterar esse tempo basta mudar da seguinte maneira -> `*/5 * * * *` (para 5 minutos nesse exemplo).
---

## Automação com User Data

Todo o processo de configuração do servidor pode ser automatizado. Utilizando o recurso **User Data** da EC2, um único script de inicialização foi criado para ser executado na primeira vez que a instância é ligada.

* **Script User Data:**
    ```bash
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
    ```

---

## Testes e Validação

Para validar a funcionalidade e a resiliência da solução, uma metodologia de testes em dois cenários foi aplicada.

1.  **Teste de Sucesso:** Este teste valida a configuração bem-sucedida do ambiente. O acesso ao endereço IP público da instância através de um navegador web resultou na exibição correta da página `index.html` customizada, confirmando que a VPC, as regras de Security Group e o servidor Nginx estavam operando como esperado.

    <img width="1855" height="864" alt="Image" src="https://github.com/user-attachments/assets/a437c531-7360-4eb7-a030-a120158c39d6" />

2.  **Teste de Falha:** Para garantir que o sistema de monitoramento é eficaz, uma falha foi simulada deliberadamente. O serviço Nginx foi interrompido no servidor com o comando `sudo systemctl stop nginx` para provar que o script detecta a falha e envia os alertas corretamente.
    * **Resultado:** Conforme o esperado, o script de monitoramento detectou a falha na verificação seguinte (em menos de um minuto) e enviou com sucesso um alerta de inatividade para o canal configurado no Discord.

    <img width="494" height="108" alt="Image" src="https://github.com/user-attachments/assets/1ff97905-2222-4449-904f-df16d6d77624" />

    * **Log:** O arquivo de log também registrou a falha, provando que o sistema de alertas e registro de eventos é totalmente funcional.

    <img width="1030" height="319" alt="Image" src="https://github.com/user-attachments/assets/a9facb31-1b8d-4f76-875e-616676c8d1cb" />
