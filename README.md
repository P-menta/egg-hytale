# Hytale Server Egg — fork apenas de tradução (PT-BR)

![GitHub License](https://img.shields.io/github/license/NATroutter/egg-hytale?style=for-the-badge) ![GitHub Issues](https://img.shields.io/github/issues/NATroutter/egg-hytale?style=for-the-badge)
![GitHub Stars](https://img.shields.io/github/stars/NATroutter/egg-hytale?style=for-the-badge) ![GitHub Forks](https://img.shields.io/github/forks/NATroutter/egg-hytale?style=for-the-badge)

Eggs de painel para hospedar servidores do jogo Hytale tanto no Pelican quanto no Pterodactyl.

## Visão geral

Este egg fornece instalação e inicialização automatizadas para servidores Hytale. Ele baixa os arquivos do servidor, prepara o ambiente e inicia o servidor com parâmetros personalizáveis.

Tanto o Pelican Panel quanto o Pterodactyl Panel são suportados, com arquivos de egg dedicados para cada plataforma.

## Recursos

- Instalação automatizada do servidor Hytale
- Download automático dos arquivos do servidor a partir de fontes oficiais
- Parâmetros do servidor configuráveis
- Setup e deploy simplificados
- Suporte a pacotes de assets personalizados
- Gerenciamento de backups
- Múltiplos modos de autenticação

## Instalação

### Pelican Panel

1. Baixe o arquivo [egg-hytale.pelican.json](egg-hytale.pelican.json) deste repositório
2. No Pelican Panel, vá em **Admin Panel** > **Eggs**
3. Clique em **Import**
4. Selecione o arquivo JSON baixado e clique em **Submit**

### Pterodactyl Panel

1. Baixe o arquivo [egg-hytale.pterodactyl.json](egg-hytale.pterodactyl.json) deste repositório
2. No Pterodactyl Panel, vá em **Admin Panel** > **Nests**
3. Selecione ou crie um nest para o egg
4. Clique em **Import Egg**
5. Selecione o arquivo JSON baixado e clique em **Import**

## Atualizando o egg

Quando uma nova versão do egg for lançada, siga os passos abaixo para atualizar:

### Pelican Panel

1. Baixe a versão mais recente do [egg-hytale.pelican.json](egg-hytale.pelican.json) deste repositório
2. No Pelican Panel, vá em **Admin Panel** > **Eggs**
3. Clique no egg "Hytale" na lista
4. Clique em **Import** (canto superior direito) e selecione o arquivo JSON baixado

### Pterodactyl Panel

1. Baixe a versão mais recente do [egg-hytale.pterodactyl.json](egg-hytale.pterodactyl.json) deste repositório
2. No Pterodactyl Panel, vá em **Admin Panel** > **Nests**
3. Clique no nest onde o egg do Hytale foi importado
4. Clique no egg do Hytale para abri-lo
5. No topo da página, na seção de atualização do egg, selecione o novo arquivo e clique em **Update Egg**

## Configuração do servidor

As seguintes opções podem ser configuradas:

| Opção | Descrição | Padrão |
| ---------- | ------------- | --------- |
| `Perfil do Jogo (usuário)` | Username do perfil Hytale para autenticação do servidor. Visite [accounts.hytale.com](https://accounts.hytale.com/) → Game Profiles para encontrar seu username. Deixe vazio para usar o primeiro/perfil padrão. | (vazio) |
| `Pacote de Assets` | Pacote de assets (.zip) que será enviado aos jogadores | `Assets.zip` |
| `Aceitar Plugins Antecipados` | Confirma que carregar plugins antecipados não é suportado e pode causar instabilidade | `false` |
| `Permitir Operadores` | Define se operadores (ops) são permitidos | `true` |
| `Modo de Autenticação` | Modo de autenticação (authenticated ou offline) | `authenticated` |
| `Atualização Automática` | Atualiza o servidor Hytale automaticamente | `true` |
| `Argumentos da JVM` | Argumentos adicionais da JVM para configuração avançada. | Ver config do egg |
| `Usar Cache Ahead-Of-Time (AOT)` | O servidor inclui um cache AOT (HytaleServer.aot) que melhora o boot ao pular o aquecimento do JIT | `true` |
| `Desativar Relatório de Falhas (Sentry)` | Desative o Sentry durante o desenvolvimento ativo de plugins para evitar enviar erros do seu ambiente | `true` |
| `Ativar Backups` | Ativa backups automáticos | `false` |
| `Frequência de Backup` | Intervalo de backup em minutos | `30` |
| `Canal de Versão` | Qual canal de lançamento você quer usar | `release` |
| `Reserva de Memória` | Quantidade de RAM (em MB) reservada para o sistema, para o servidor não consumir tudo. O Java usará o restante. | `0` |

### Autenticação na primeira execução

Na primeira inicialização, o Hytale downloader vai pedir autenticação com sua conta Hytale. Você verá uma mensagem/bandeira pedindo para abrir uma URL (ela é única para você) parecida com esta:

```txt
Autentique o servidor acessando a seguinte URL:
https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=XXXXXXXX
```

**Para concluir a autenticação:**

1. Abra a URL fornecida no seu navegador
2. Entre com sua conta Hytale
3. Autorize o servidor
4. Volte ao console — o download continuará automaticamente

Essa etapa de autenticação é necessária apenas na configuração inicial. Nas próximas inicializações, não deve ser necessário autenticar novamente (desde que o cache de token esteja válido).

## Licença

Este projeto é licenciado sob a licença MIT — veja o arquivo LICENSE para mais detalhes.

## Agradecimentos

- Equipe do Hytale pelo jogo e software do servidor
- Pelican Panel e Pterodactyl Panel pelas plataformas de hospedagem
- Contribuidores da comunidade

## Links

- [Hytale Official Website](https://hytale.com/)
- [Pelican Panel](https://pelican.dev/)
- [Pterodactyl Panel](https://pterodactyl.io/)
- [Report Issues](https://github.com/NATroutter/egg-hytale/issues)

## Suporte

Se você tiver problemas ou dúvidas:

- Verifique as issues existentes para possíveis soluções
- Abra uma issue no GitHub

---

**Nota**: este é um egg não oficial, criado pela comunidade, e não possui suporte oficial da Hypixel Studios ou da equipe do Hytale.
