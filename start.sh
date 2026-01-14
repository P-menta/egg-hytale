#!/bin/bash

################################################################################
# AVISO: NÃO EDITE ESTE ARQUIVO MANUALMENTE!
#
# Este arquivo é gerenciado automaticamente pelo egg-hytale.
# Qualquer alteração manual será sobrescrita na próxima atualização.
#
# Para personalizar as configurações do servidor, use as variáveis de
# configuração do egg no painel do Pelican ou Pterodactyl.
################################################################################

echo "Iniciando servidor Hytale..."

# Monta o comando Java
JAVA_CMD="java"

# Adiciona cache AOT se habilitado
if [ "${LEVERAGE_AHEAD_OF_TIME_CACHE}" = "1" ]; then
    JAVA_CMD="${JAVA_CMD} -XX:AOTCache=HytaleServer.aot"
fi

# Adiciona memória máxima se definida e maior que MEMORY_OVERHEAD
if [ -n "${SERVER_MEMORY}" ] && [ "${SERVER_MEMORY}" -gt "${MEMORY_OVERHEAD}" ] 2>/dev/null; then
    JAVA_MEMORY=$((SERVER_MEMORY - MEMORY_OVERHEAD))
    JAVA_CMD="${JAVA_CMD} -Xmx${JAVA_MEMORY}M"
fi

# Adiciona argumentos da JVM se definidos
if [ -n "${JVM_ARGS}" ]; then
    JAVA_CMD="${JAVA_CMD} ${JVM_ARGS}"
fi

JAVA_CMD="${JAVA_CMD} -jar HytaleServer.jar"

# Adiciona parâmetro de assets se definido e terminar com .zip
if [ -n "${ASSET_PACK}" ] && [[ "${ASSET_PACK}" == *.zip ]]; then
    JAVA_CMD="${JAVA_CMD} --assets ${ASSET_PACK}"
fi

# Adiciona flag accept-early-plugins se a variável estiver ativada
if [ "${ACCEPT_EARLY_PLUGINS}" = "1" ]; then
    JAVA_CMD="${JAVA_CMD} --accept-early-plugins"
fi

JAVA_CMD="${JAVA_CMD} --auth-mode ${AUTH_MODE}"

# Adiciona flag allow-op se a variável estiver ativada
if [ "${ALLOW_OP}" = "1" ]; then
    JAVA_CMD="${JAVA_CMD} --allow-op"
fi

# Adiciona flag disable-sentry se habilitado
if [ "${DISABLE_SENTRY}" = "1" ]; then
    JAVA_CMD="${JAVA_CMD} --disable-sentry"
fi

# Adiciona parâmetros de backup se habilitado
if [ "${ENABLE_BACKUPS}" = "1" ]; then
    JAVA_CMD="${JAVA_CMD} --backup --backup-dir ./backup --backup-frequency ${BACKUP_FREQUENCY}"
fi

# Adiciona tokens de sessão e UUID do dono
JAVA_CMD="${JAVA_CMD} --session-token ${SESSION_TOKEN}"
JAVA_CMD="${JAVA_CMD} --identity-token ${IDENTITY_TOKEN}"
JAVA_CMD="${JAVA_CMD} --owner-uuid ${PROFILE_UUID}"

# Adiciona endereço de bind
JAVA_CMD="${JAVA_CMD} --bind 0.0.0.0:${SERVER_PORT}"

# Executa o comando
eval $JAVA_CMD
