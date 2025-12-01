#!/bin/bash

START_PORT=${1:-9000}
END_PORT=${2:-9099}

echo "Iniciando a busca por portas em uso no intervalo: ${START_PORT} - ${END_PORT}"
echo ""

is_port_in_use() {
  netstat -tuln | grep -q ":$1\ " || lsof -i :$1 > /dev/null 2>&1
}

UNAVAILABLE_COUNT=0
for (( port = START_PORT; port <= END_PORT; port++ )); do
  if is_port_in_use "$port"; then
    echo "Porta ${port} está EM USO."
    ((UNAVAILABLE_COUNT++))
  fi
done

echo "--- Busca concluída ---"
echo "${UNAVAILABLE_COUNT} porta(s) não disponível(is) encontrada(s)"