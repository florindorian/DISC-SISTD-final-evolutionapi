#!/bin/sh

echo "🔧 [entrypoint] Iniciando container n8n..."

# Inicia n8n em background
n8n start &
N8N_PID=$!

echo "⏳ [entrypoint] Aguardando 15 segundos para n8n inicializar..."
sleep 15

# Executa script de inicialização
if [ -f /setup/init-n8n.sh ]; then
  echo "🚀 [entrypoint] Executando script de setup..."
  /setup/init-n8n.sh
else
  echo "⚠️  [entrypoint] Script init-n8n.sh não encontrado!"
fi

# Mantém n8n rodando em foreground
echo "✅ [entrypoint] Setup concluído. n8n em execução..."
wait $N8N_PID