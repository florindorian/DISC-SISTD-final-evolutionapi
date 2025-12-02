#!/bin/sh
echo "🔧 [entrypoint] Iniciando container n8n..."

# Passo 1a: Instalar envsubst (somente se não existir, como root)
if ! command -v envsubst >/dev/null 2>&1; then
  echo "📦 [entrypoint] Instalando 'envsubst' (gettext) para substituição de secrets..."
  apk update && apk add gettext
fi

# Passo 1b: Instalar su-exec
if ! command -v su-exec >/dev/null 2>&1; then
  echo "📦 [entrypoint] Instalando 'su-exec' para gerenciamento de usuário..."
  # O pacote su-exec no Alpine é simplesmente 'su-exec'
  apk add su-exec
fi

# Passo 2: Iniciar o n8n em background como o usuário de destino (node/1000)
echo "⏳ [entrypoint] Mudando para usuário não-root (UID 1000) e iniciando n8n em background..."

# 2a. Iniciar o n8n em background como UID 1000
# Isto inicia o servidor web e o banco de dados no local correto (/home/node/.n8n)
su-exec 1000 n8n start & 
# O comando 'n8n start' deve rodar em background (&) para liberar o entrypoint
N8N_PID=$!
sleep 10 # Pequena pausa para garantir que o processo n8n inicie o servidor

# 2b. Executar o script de setup como UID 1000
if [ -f /setup/init-n8n.sh ]; then
  echo "🚀 [entrypoint] Executando script de setup (init-n8n.sh) como usuário 'node'..."
  # Executa o script de setup (incluindo envsubst e import) como UID 1000
  su-exec 1000 /setup/init-n8n.sh
else
  echo "⚠️  [entrypoint] Script init-n8n.sh não encontrado!"
fi


# Passo 3: Executar o script de setup
if [ -f /setup/init-n8n.sh ]; then
  echo "🚀 [entrypoint] Executando script de setup (init-n8n.sh)..."
  # O init-n8n.sh agora pode rodar, pois o n8n já está tentando iniciar
  /setup/init-n8n.sh
else
  echo "⚠️  [entrypoint] Script init-n8n.sh não encontrado!"
fi

# Passo 4: Mantém o n8n rodando em foreground
echo "✅ [entrypoint] Setup concluído. Mantendo n8n em execução..."
wait $N8N_PID