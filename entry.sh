#!/bin/bash

################################################################################
# Script de entrada do egg-hytale
#
# Este script gerencia:
# - Download e atualização do servidor Hytale
# - Autenticação com os serviços da Hytale
# - Geração de tokens de sessão
# - Execução do script principal de inicialização do servidor
#
# NÃO EDITE ESTE ARQUIVO - ele é gerenciado pela imagem Docker.
# Para personalizar as configurações do servidor, use as variáveis de
# configuração do egg no painel do Pelican ou Pterodactyl.
################################################################################

DOWNLOAD_URL="https://downloader.hytale.com/hytale-downloader.zip"
DOWNLOAD_FILE="hytale-downloader.zip"
DOWNLOADER="./hytale-downloader-linux-amd64"
AUTH_CACHE_FILE=".hytale-auth-tokens.json"

# Função para extrair os arquivos do servidor baixados
extract_server_files() {
    echo "Extraindo arquivos do servidor..."
    SERVER_ZIP="server.zip"

    if [ -f "$SERVER_ZIP" ]; then
        echo "Arquivo do servidor encontrado: $SERVER_ZIP"

        # Extract to current directory
        unzip -o "$SERVER_ZIP"

        if [ $? -ne 0 ]; then
            echo "Erro: Falha ao extrair $SERVER_ZIP"
            exit 1
        fi

        echo "Extração concluída com sucesso."

        # Move contents from Server folder to current directory
        if [ -d "Server" ]; then
            echo "Movendo arquivos do servidor do diretório Server..."
            mv Server/* .
            rmdir Server
            echo "✓ Arquivos do servidor movidos para o diretório raiz."
        fi

        # Clean up the zip file
        echo "Removendo arquivo compactado..."
        rm "$SERVER_ZIP"
        echo "✓ Arquivo removido."
    else
        echo "Erro: Arquivo do servidor não encontrado em $SERVER_ZIP"
        exit 1
    fi
}

# Função para verificar se existem tokens em cache
check_cached_tokens() {
    if [ -f "$AUTH_CACHE_FILE" ]; then
        # Check if jq is available
        if ! command -v jq &> /dev/null; then
            echo "Aviso: jq não encontrado; não é possível usar tokens em cache"
            return 1
        fi

        # Validate JSON format
        if ! jq empty "$AUTH_CACHE_FILE" 2>/dev/null; then
            echo "Aviso: Arquivo de token em cache inválido; removendo..."
            rm "$AUTH_CACHE_FILE"
            return 1
        fi

        echo "✓ Tokens de autenticação em cache encontrados"
        return 0
    fi
    return 1
}

# Função para carregar tokens em cache (apenas refresh_token + profile_uuid)
load_cached_tokens() {
    REFRESH_TOKEN=$(jq -r '.refresh_token' "$AUTH_CACHE_FILE")
    PROFILE_UUID=$(jq -r '.profile_uuid' "$AUTH_CACHE_FILE")

    # Validate required tokens are present
    if [ -z "$REFRESH_TOKEN" ] || [ "$REFRESH_TOKEN" = "null" ] || \
       [ -z "$PROFILE_UUID" ] || [ "$PROFILE_UUID" = "null" ]; then
        echo "Erro: Tokens em cache incompletos; autenticando novamente..."
        rm "$AUTH_CACHE_FILE"
        return 1
    fi

    echo "✓ Refresh token + UUID do perfil carregados do cache"
    return 0
}

# Função para atualizar o access token usando o refresh token em cache
refresh_access_token() {
    echo "Atualizando access token..."

    TOKEN_RESPONSE=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=hytale-server" \
      -d "grant_type=refresh_token" \
      -d "refresh_token=$REFRESH_TOKEN")

    ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')
    if [ -n "$ERROR" ]; then
        echo "Erro: Falha ao atualizar o access token: $ERROR"
        return 1
    fi

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
    NEW_REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token // empty')

    if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
        echo "Erro: Nenhum access token retornado na atualização"
        return 1
    fi

    # Update refresh token if a new one was provided
    if [ -n "$NEW_REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "null" ]; then
        REFRESH_TOKEN="$NEW_REFRESH_TOKEN"
    fi

    echo "✓ Access token atualizado"
    return 0
}

# Função para criar uma nova sessão de jogo
create_game_session() {
    echo "Criando sessão do servidor de jogo..."

    SESSION_RESPONSE=$(curl -s -X POST "https://sessions.hytale.com/game-session/new" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"uuid\": \"${PROFILE_UUID}\"}")

    # Validate JSON response
    if ! echo "$SESSION_RESPONSE" | jq empty 2>/dev/null; then
        echo "Erro: Resposta JSON inválida ao criar a sessão do servidor"
        echo "Resposta: $SESSION_RESPONSE"
        return 1
    fi

    # Extract session and identity tokens
    SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.sessionToken')
    IDENTITY_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.identityToken')

    if [ -z "$SESSION_TOKEN" ] || [ "$SESSION_TOKEN" = "null" ]; then
        echo "Erro: Falha ao criar a sessão do servidor de jogo"
        echo "Resposta: $SESSION_RESPONSE"
        return 1
    fi

    echo "✓ Sessão do servidor de jogo criada com sucesso!"
    return 0
}

# Função para salvar tokens de autenticação (apenas refresh_token + profile_uuid)
save_auth_tokens() {
    cat > "$AUTH_CACHE_FILE" << EOF
{
  "refresh_token": "$REFRESH_TOKEN",
  "profile_uuid": "$PROFILE_UUID",
  "timestamp": $(date +%s)
}
EOF
    echo "✓ Refresh token armazenado em cache para uso futuro"
}

# Função para realizar a autenticação completa
perform_authentication() {
    echo "Obtendo tokens de autenticação..."

    # Step 1: Request device code
    AUTH_RESPONSE=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/device/auth" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=hytale-server" \
      -d "scope=openid offline auth:server")

    # Extract device_code and verification_uri_complete using jq
    DEVICE_CODE=$(echo "$AUTH_RESPONSE" | jq -r '.device_code')
    VERIFICATION_URI=$(echo "$AUTH_RESPONSE" | jq -r '.verification_uri_complete')
    POLL_INTERVAL=$(echo "$AUTH_RESPONSE" | jq -r '.interval')

    # Exibe o banner de autenticação
    echo ""
    echo "╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "║                   AUTENTICAÇÃO DO SERVIDOR HYTALE NECESSÁRIA                ║"
    echo "╠═════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                             ║"
    echo "║  Autentique o servidor acessando a seguinte URL:                            ║"
    echo "║                                                                             ║"
    echo "║  $VERIFICATION_URI  ║"
    echo "║                                                                             ║"
    echo "║  1. Clique no link acima ou copie para o navegador                          ║"
    echo "║  2. Entre com sua conta Hytale                                              ║"
    echo "║  3. Autorize o servidor                                                     ║"
    echo "║                                                                             ║"
    echo "║  Aguardando autenticação...                                                 ║"
    echo "║                                                                             ║"
    echo "╚═════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 2: Poll for access token
    ACCESS_TOKEN=""
    while [ -z "$ACCESS_TOKEN" ]; do
        sleep $POLL_INTERVAL

        TOKEN_RESPONSE=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -d "client_id=hytale-server" \
          -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
          -d "device_code=$DEVICE_CODE")

        # Check if we got an error
        ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

        if [ "$ERROR" = "authorization_pending" ]; then
            echo "Ainda aguardando autenticação..."
            continue
        elif [ -n "$ERROR" ]; then
            echo "Erro de autenticação: $ERROR"
            exit 1
        else
            # Successfully authenticated
            ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
            REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token')
            echo ""
            echo "✓ Autenticação realizada com sucesso!"
            echo ""
        fi
    done

    # Busca perfis de jogo disponíveis
    echo "Buscando perfis de jogo..."

    PROFILES_RESPONSE=$(curl -s -X GET "https://account-data.hytale.com/my-account/get-profiles" \
      -H "Authorization: Bearer $ACCESS_TOKEN")

    # Check if profiles list is empty
    PROFILES_COUNT=$(echo "$PROFILES_RESPONSE" | jq '.profiles | length')

    if [ "$PROFILES_COUNT" -eq 0 ]; then
        echo "Erro: Nenhum perfil de jogo encontrado. Você precisa ter o Hytale para rodar um servidor."
        exit 1
    fi

    # Select profile based on GAME_PROFILE variable
    if [ -n "$GAME_PROFILE" ]; then
        # User specified a profile username, find matching UUID
        echo "Procurando perfil: $GAME_PROFILE"
        PROFILE_UUID=$(echo "$PROFILES_RESPONSE" | jq -r ".profiles[] | select(.username == \"$GAME_PROFILE\") | .uuid")

        if [ -z "$PROFILE_UUID" ] || [ "$PROFILE_UUID" = "null" ]; then
            echo "Erro: Perfil '$GAME_PROFILE' não encontrado."
            echo "Perfis disponíveis:"
            echo "$PROFILES_RESPONSE" | jq -r '.profiles[] | "  - \(.username)"'
            exit 1
        fi

        echo "✓ Usando perfil: $GAME_PROFILE (UUID: $PROFILE_UUID)"
    else
        # Use first profile from the list
        PROFILE_UUID=$(echo "$PROFILES_RESPONSE" | jq -r '.profiles[0].uuid')
        PROFILE_USERNAME=$(echo "$PROFILES_RESPONSE" | jq -r '.profiles[0].username')

        echo "✓ Usando perfil padrão: $PROFILE_USERNAME (UUID: $PROFILE_UUID)"
    fi

    echo ""

    # Salva refresh token + perfil para uso futuro
    save_auth_tokens

    # Create game server session
    if ! create_game_session; then
        exit 1
    fi
    echo ""
}

# Copia o template do start.sh para /home/container
echo "Copiando template do start.sh para /home/container..."
cp /usr/local/bin/start.sh /home/container/start.sh
chmod 755 /home/container/start.sh

# Check if the downloader exists
if [ ! -f "$DOWNLOADER" ]; then
    echo "Erro: Hytale downloader não encontrado!"
    echo "Execute o script de instalação primeiro."
    exit 1
fi

# Check if the downloader is executable
if [ ! -x "$DOWNLOADER" ]; then
    echo "Ajustando permissões de execução..."
    chmod +x "$DOWNLOADER"
fi

INITIAL_SETUP=0

# Check if credentials file exists, if not run the updater
if [ ! -f ".hytale-downloader-credentials.json" ]; then
    INITIAL_SETUP=1
    echo "Arquivo de credenciais não encontrado; executando configuração inicial..."
    echo "Iniciando Hytale downloader..."
    $DOWNLOADER -check-update
    $DOWNLOADER -patchline $PATCHLINE -download-path server.zip
    extract_server_files

    # Save version info after initial setup
    DOWNLOADER_VERSION=$($DOWNLOADER -print-version)
    echo "$DOWNLOADER_VERSION" > version.txt
    echo "Informações de versão salvas para uso futuro!"
fi

# Run automatic update if enabled
if [ "${AUTOMATIC_UPDATE}" = "1" ] && [ "${INITIAL_SETUP}" = "0" ]; then
    echo "Iniciando Hytale downloader..."

    # Read local version from file
    if [ -f "version.txt" ]; then
        LOCAL_VERSION=$(cat version.txt)
    else
        echo "version.txt não encontrado; forçando atualização"
        LOCAL_VERSION=""
    fi

    # Get remote/downloader version
    DOWNLOADER_VERSION=$($DOWNLOADER -print-version)

    echo "Versão local: $LOCAL_VERSION"
    echo "Versão do downloader: $DOWNLOADER_VERSION"

    # Compare versions
    if [ "$LOCAL_VERSION" != "$DOWNLOADER_VERSION" ]; then
        echo "Versões diferentes; executando atualização..."

        $DOWNLOADER -check-update
        $DOWNLOADER -patchline $PATCHLINE -download-path server.zip
        extract_server_files

        # Update version.txt after successful update
        echo "$DOWNLOADER_VERSION" > version.txt
		echo "Informações de versão salvas para uso futuro!"
    else
        echo "Versões iguais; pulando atualização"
    fi
fi

# Check if server files were downloaded correctly
if [ ! -f "HytaleServer.jar" ]; then
    echo "Erro: HytaleServer.jar não encontrado!"
    echo "Os arquivos do servidor não foram baixados corretamente."
    exit 1
fi

# Check for cached authentication tokens
if check_cached_tokens && load_cached_tokens; then
    echo "Usando autenticação em cache..."
    if refresh_access_token; then
        # Update cache in case refresh token rotated
        save_auth_tokens
        # Create fresh game session
        if ! create_game_session; then
            exit 1
        fi
    else
        # Refresh failed, need full re-auth
        echo "Refresh token expirou; autenticando novamente..."
        rm -f "$AUTH_CACHE_FILE"
        perform_authentication
    fi
else
    # Perform full authentication if no valid cache exists
    perform_authentication
fi

# Exporta os tokens de sessão para ficarem disponíveis no start.sh
export SESSION_TOKEN
export IDENTITY_TOKEN
export PROFILE_UUID

# Chama o entrypoint do Pterodactyl, que executará o start.sh
exec /bin/bash /entrypoint.sh