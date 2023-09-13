#!/bin/bash
tmp_cronfile=$(mktemp)

echo "* * * * * /usr/bin/php ${HUMHUB_DIR}/protected/yii queue/run >/dev/null 2>&1" >> "$tmp_cronfile"
echo "* * * * * /usr/bin/php ${HUMHUB_DIR}/protected/yii cron/run >/dev/null 2>&1" >> "$tmp_cronfile"

# Carregue o arquivo temporário no crontab do usuário www-data
sudo crontab -u www-data "$tmp_cronfile"

# Remova o arquivo temporário
rm "$tmp_cronfile"

echo "Tarefas adicionadas ao crontab do usuário www-data."

echo '' > ~/.bash_history