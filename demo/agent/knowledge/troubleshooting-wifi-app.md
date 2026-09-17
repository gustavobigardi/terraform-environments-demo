# Solução de Problemas — Wi-Fi e App Contoso Brew

**Este documento se aplica somente à Barista X2.** A Barista X1 não possui Wi-Fi, Bluetooth nem integração com o app Contoso Brew.

## O que o app Contoso Brew faz

- Agenda o preaquecimento da cafeteira.
- Salva e sincroniza receitas (dose, nível de moagem, volume e temperatura).
- Mostra o contador de cafés e os avisos de descalcificação (a cada 400 cafés) e de limpeza do grupo.
- Exibe os códigos E01 a E12 em tempo real.
- Atualiza o firmware.
- Registra a garantia estendida de 36 meses (em até 30 dias da nota fiscal).
- Abre chamados com envio automático do log de erros.

A cafeteira funciona normalmente sem conexão: preparo de café, vapor, descalcificação e limpeza não dependem do app.

## Requisitos de rede

| Requisito | Detalhe |
|---|---|
| Frequência | **Somente 2,4 GHz** (802.11 b/g/n) |
| Segurança | WPA2-Personal ou modo misto WPA2/WPA3 (WPA3 puro não é suportado) |
| Canais | 1 a 11 |
| Rede | SSID visível (redes ocultas não são suportadas) |
| Portal cativo | Não suportado (redes de hotel, condomínio ou empresa com página de login) |
| Portas de saída | TCP 443 e TCP 8883 liberadas no firewall |
| Celular | Android 10 ou superior, ou iOS 15 ou superior, com Bluetooth ativado (no Android, também a localização) |

## Rede 2,4 GHz ou 5 GHz

A Barista X2 só se conecta em 2,4 GHz. Essa frequência tem alcance maior e atravessa melhor paredes, o que é adequado para eletrodomésticos. Redes de 5 GHz são mais rápidas, mas não são reconhecidas pelo módulo da cafeteira.

### Roteador dual-band com o mesmo nome de rede

Muitos roteadores transmitem 2,4 GHz e 5 GHz com o mesmo nome (recurso chamado de "band steering"). Nesse caso, o celular pode estar em 5 GHz durante o emparelhamento e a conexão falha. Soluções, em ordem de preferência:

1. No painel do roteador, crie uma rede 2,4 GHz com nome separado (por exemplo, `MinhaCasa_2G`) e use essa rede no emparelhamento.
2. Desative temporariamente a banda de 5 GHz, faça o emparelhamento e reative em seguida.
3. Aproxime-se da cafeteira e do roteador, onde o celular tende a escolher 2,4 GHz.

Depois do emparelhamento, o celular pode voltar a usar 5 GHz ou dados móveis: o app se comunica com a cafeteira pela nuvem.

## Ícone de Wi-Fi no display

| Ícone | Significado |
|---|---|
| Azul fixo | Conectado à internet |
| Azul piscando | Modo de emparelhamento ativo (janela de 3 minutos) |
| Laranja fixo | Conectado ao roteador, mas sem acesso à internet |
| Cinza com traço | Wi-Fi desativado |
| Código E09 | Falha de conexão |

## Problemas no emparelhamento

### O app não encontra a cafeteira

1. Confirme que o Bluetooth do celular está ligado e que o app tem permissão de Bluetooth (e de localização, no Android).
2. Fique a até 2 metros da cafeteira.
3. Verifique se o ícone de Wi-Fi está azul piscando. A janela de emparelhamento dura 3 minutos; se expirou, acesse novamente **Menu > Configurações > Wi-Fi > Emparelhar**.
4. Feche e reabra o app.

### A cafeteira já está vinculada a outra conta

Cada Barista X2 aceita 1 conta principal e até 4 convidados. Peça ao titular para removê-la em **Dispositivo > Remover** ou faça o reset de rede (próxima seção).

### O app mostra a cafeteira offline, mas o ícone está azul fixo

Feche o app completamente, confirme que está logado na conta correta e reabra. Se continuar offline por mais de 10 minutos, desligue a cafeteira por 1 minuto e religue.

## Reset de rede

O reset de rede apaga apenas as credenciais de Wi-Fi e o vínculo com o app. **Receitas, contadores de cafés, histórico de descalcificação e registro de garantia são preservados.**

### Pelos botões físicos

1. Com a máquina ligada e em repouso (sem preparo em andamento), **segure os botões Menu e Vapor ao mesmo tempo por 10 segundos**.
2. Solte quando o display mostrar "Rede redefinida" e a máquina emitir um bipe duplo.
3. No app, remova a cafeteira antiga em **Dispositivo > Remover**.
4. Refaça o emparelhamento conforme `barista-x2-manual.md`, seção "Emparelhamento Wi-Fi com o app".

### Pelo menu

Acesse **Menu > Configurações > Wi-Fi > Redefinir rede** e confirme.

### Diferença para o padrão de fábrica

**Menu > Configurações > Restaurar padrão de fábrica** apaga também receitas, nível de moagem e preferências. O registro da garantia estendida não é perdido, pois fica nos servidores da Contoso Café.

## Erro E09 — falha de conexão

O código E09 aparece quando a cafeteira não consegue se conectar à rede ou à nuvem por mais de 5 minutos. A máquina continua preparando café; toque no aviso para dispensá-lo.

### Causas mais comuns

- Senha do Wi-Fi alterada ou roteador substituído.
- Roteador configurado somente em 5 GHz ou em WPA3 puro.
- Sinal fraco: abaixo de -70 dBm. Veja a intensidade em **Menu > Configurações > Wi-Fi > Diagnóstico**.
- Firewall bloqueando a porta TCP 8883.
- Roteador sem endereços IP disponíveis (DHCP esgotado).

### Passo a passo

1. Verifique se outros dispositivos acessam a internet pela mesma rede.
2. Abra **Menu > Configurações > Wi-Fi > Diagnóstico** e confira o sinal. Se estiver abaixo de -70 dBm, aproxime o roteador ou use um repetidor 2,4 GHz.
3. Reinicie o roteador e a cafeteira (desligue ambos por 1 minuto).
4. Confirme que a rede é 2,4 GHz com WPA2 (seção "Requisitos de rede").
5. Faça o reset de rede e emparelhe novamente.
6. Teste com o roteador do celular (hotspot) configurado em 2,4 GHz. Se conectar, o problema está no roteador; se não conectar, abra um chamado.

Se o E09 persistir após o passo 6, o módulo Wi-Fi pode estar com defeito. Abra um chamado conforme `garantia-e-assistencia.md`.

## Atualização de firmware

A versão atual do firmware da Barista X2 é a **3.4.2** (setembro de 2026). Para conferir a versão instalada, acesse **Menu > Configurações > Sobre**.

### Atualização automática

Com **Atualização automática** ativada no app (**Dispositivo > Firmware**), a cafeteira se atualiza às 3h, desde que esteja ligada ou em modo de espera.

### Atualização manual

1. No app, acesse **Dispositivo > Firmware > Verificar atualizações**, ou na máquina **Menu > Configurações > Sobre > Atualizar**.
2. Mantenha a cafeteira ligada, em repouso e conectada durante todo o processo.
3. A atualização leva cerca de 8 minutos; o progresso aparece no display.
4. A máquina reinicia sozinha ao final. Não a desligue da tomada.

### Se a atualização falhar (E10)

Desligue a cafeteira, aguarde 1 minuto, religue e repita a atualização. A versão anterior continua funcionando. Após 3 falhas seguidas, abra um chamado.
