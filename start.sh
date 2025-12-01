#!/bin/bash

echo "🚀 Garantindo permissões de execução para os scripts de setup..."
# Garante que os scripts que o Docker vai executar ou chamar sejam executáveis no host
chmod +x setup/docker-entrypoint.sh
chmod +x setup/init-n8n.sh

echo "⚙️ Garantindo que o diretório de volume do n8n exista..."
mkdir -p volumes/.n8n

echo "🔑 Corrigindo permissões do volume para o UID 1000 (usuário n8n)..."
# O n8n precisa que este volume seja de propriedade do UID 1000 para escrever o config.
sudo chown -R 1000:1000 volumes/.n8n

echo "🐳 Iniciando containers com docker-compose..."
docker compose up -d

echo "✅ Verificando logs de inicialização do n8n..."
docker compose logs -f sistd-n8n