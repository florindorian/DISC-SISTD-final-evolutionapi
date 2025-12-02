#!/bin/sh

echo "🚀 [n8n-init] Iniciando configuração automática..."

# 1. SUBSTITUIÇÃO DE VARIÁVEIS
echo "🔄 [n8n-init] Substituindo secrets no template de credenciais..."
# O comando 'envsubst' substitui as variáveis (${...}) do template com os valores reais injetados pelo Docker Compose/env.
envsubst < /setup/credentials.template.json > /setup/credentials.json
echo "✅ [n8n-init] Template de credenciais gerado com sucesso."

# O n8n precisa que o arquivo de credenciais não seja read-only
# Criou-se o arquivo de destino (credentials.json) em /setup/ para o n8n poder rodar o import.
# Como o arquivo foi criado dentro do container, ele pertence ao UID 1000.


# Aguarda n8n estar pronto
echo "⏳ [n8n-init] Aguardando n8n iniciar..."
until wget -q --spider http://localhost:5678/healthz 2>/dev/null; do
  sleep 3
done
echo "✅ [n8n-init] n8n está pronto!"

# Verifica se já foi inicializado
if [ -f /home/node/.n8n/.initialized ]; then
  echo "ℹ️  [n8n-init] Ambiente já inicializado. Pulando importação."
  exit 0
fi

echo "📥 [n8n-init] Importando credenciais..."
if n8n import:credentials --input=/setup/credentials.json 2>&1 | tee /tmp/import-creds.log; then
  echo "✅ [n8n-init] Credenciais importadas com sucesso!"
else
  echo "⚠️  [n8n-init] Erro ao importar credenciais. Verifique /tmp/import-creds.log"
fi

echo "📥 [n8n-init] Importando workflow..."
if n8n import:workflow --input=/setup/CodeParfumAgent.json 2>&1 | tee /tmp/import-workflow.log; then
  echo "✅ [n8n-init] Workflow importado com sucesso!"
else
  echo "⚠️  [n8n-init] Erro ao importar workflow. Verifique /tmp/import-workflow.log"
fi

# Marca como inicializado
touch /home/node/.n8n/.initialized
echo "🎉 [n8n-init] Configuração concluída!"