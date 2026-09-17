# Códigos de Erro — Barista X1 e Barista X2

Os dois modelos da Contoso Café sinalizam problemas de formas diferentes:

- **Barista X1:** não tem display. Usa **códigos de luz** (L1 a L5) no anel do botão Liga/Desliga.
- **Barista X2:** usa **códigos E01 a E12** exibidos no display touch e também enviados ao app Contoso Brew.

Um código "E" nunca aparece na Barista X1, e um código "L" nunca aparece na Barista X2. Se o cliente não souber o modelo, pergunte se a máquina tem display (X2) ou apenas botões com luz (X1).

## Barista X1 — códigos de luz

| Código | Luz | Causa provável | Ação recomendada | Abrir chamado? |
|---|---|---|---|---|
| L1 | Âmbar piscando | Contador de descalcificação atingido (200 cafés ou 2 meses) | Fazer a descalcificação com Contoso DescalPro, conforme `barista-x1-manual.md`, seção "Descalcificação" | Não |
| L2 | Vermelho fixo | Reservatório vazio ou mal encaixado | Encher até MAX (1,2 L) e pressionar o reservatório até ouvir o clique | Somente se persistir com o reservatório cheio e encaixado |
| L3 | Vermelho piscando | Superaquecimento ou falha do sensor de temperatura | Desligar, aguardar 30 minutos e religar; manter 10 cm de espaço livre ao redor da máquina | Sim, se ocorrer 3 vezes em 24 horas |
| L4 | Vermelho e âmbar alternando | Falha na bomba ou ar no circuito | Encher o reservatório, abrir a manopla de vapor por 30 segundos e pressionar Café duplo sem porta-filtro; se não sair água, parar de usar | Sim, se não resolver na primeira tentativa |
| L5 | Todas as luzes piscando juntas | Erro na placa eletrônica | Desligar da tomada por 5 minutos e religar | Sim, se persistir após religar |

### Situações da X1 que não são erro

- **Branco piscando:** aquecimento normal (cerca de 40 segundos).
- **Âmbar fixo:** modo de descalcificação em andamento. Para sair sem concluir, segure Café simples e Café duplo por 5 segundos e faça dois enxágues com água limpa.

## Barista X2 — códigos E01 a E12

| Código | Mensagem no display | Causa provável | Ação recomendada | Abrir chamado? |
|---|---|---|---|---|
| E01 | Sem água | Reservatório vazio, mal encaixado ou boia presa | Encher até MAX (2,5 L), reencaixar e verificar se a boia se move livremente | Somente se persistir com o reservatório cheio |
| E02 | Falha no aquecimento | Falha na resistência ou no sensor da caldeira de café | Desligar por 1 minuto e religar | Sim, se persistir após religar |
| E03 | Temperatura excessiva | Superaquecimento, ventilação obstruída | Desligar, aguardar 30 minutos e garantir 10 cm de espaço livre | Sim, se ocorrer 3 vezes em 24 horas |
| E04 | Moedor travado | Grão oleoso, corpo estranho ou moagem fina demais (níveis 1–2) | Desligar, esvaziar o reservatório de grãos, escovar o moedor e ajustar para nível 5 ou superior | Sim, se persistir após a limpeza |
| E05 | Sem grãos | Reservatório de grãos vazio ou tampa mal fechada | Adicionar grãos (até 250 g) e fechar a tampa | Não |
| E06 | Bandeja cheia | Bandeja de gotejamento cheia ou mal encaixada | Esvaziar e encaixar até o batente | Não |
| E07 | Descalcificação vencida | 500 cafés sem descalcificar; vapor bloqueado | Executar Menu > Manutenção > Descalcificar (35 min), conforme `barista-x2-manual.md` | Não |
| E08 | Baixo fluxo | Moagem fina demais (abaixo do nível 3), filtro AP-2 saturado ou calcário | Engrossar a moagem, trocar o filtro AP-2 e executar Menu > Manutenção > Enxaguar grupo | Sim, se persistir após as três ações |
| E09 | Falha de conexão | Wi-Fi indisponível, senha alterada, rede 5 GHz ou sinal fraco | Seguir `troubleshooting-wifi-app.md`, seção "Erro E09". A máquina continua fazendo café normalmente | Sim, se persistir após reset de rede e teste com outra rede 2,4 GHz |
| E10 | Falha na atualização | Conexão interrompida durante a atualização de firmware | Desligar, religar e repetir a atualização pelo app | Sim, após 3 falhas seguidas |
| E11 | Falha no sensor de vapor | Sensor de pressão da caldeira de vapor | Não usar o vapor; o preparo de café continua disponível se o display permitir | Sim, sempre |
| E12 | Erro interno | Falha de comunicação da placa eletrônica | Desligar da tomada por 5 minutos e religar | Sim, se persistir após religar |

## Quando abrir chamado

Abra um chamado de assistência técnica quando:

1. O código indicar "Sim, sempre" (E11).
2. A ação recomendada não resolver o problema (L2, L4, L5, E01, E02, E04, E08, E12).
3. O mesmo código se repetir 3 vezes em 24 horas (L3, E03).
4. A atualização de firmware falhar 3 vezes seguidas (E10).
5. A conexão falhar mesmo após reset de rede e teste com outra rede 2,4 GHz (E09).

Códigos L1, E05, E06 e E07 são avisos de manutenção e **não** geram chamado.

### Informações necessárias para o chamado

- Modelo e número de série (`CX1-` ou `CX2-` seguido de 8 dígitos).
- Código exibido (luz ou código E) e quando começou.
- Ações já realizadas.
- Na Barista X1, um vídeo de até 30 segundos mostrando as luzes ajuda na triagem.
- Na Barista X2, abrir o chamado pelo app (**Dispositivo > Suporte > Abrir chamado**) envia o log de erros automaticamente.

Canais, prazos de atendimento e assistências autorizadas: `garantia-e-assistencia.md`.
