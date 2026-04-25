# DE10_LITE_GSensor_VGA - Documentacao do Projeto

## Visao Geral

Projeto para a placa **DE10-Lite** (FPGA MAX 10 - 10M50DAF484C7G) que combina dois subsistemas:

1. **Acelerometro (GSensor)**: leitura do eixo X do acelerometro ADXL345 integrado na placa via interface SPI
2. **Display VGA**: exibicao de uma barra vertical branca em um monitor VGA 640x480@60Hz, cuja posicao horizontal reflete a inclinacao da placa

Quando a placa e inclinada para a esquerda ou direita, a barra se move correspondentemente na tela. Os 10 LEDs da placa tambem indicam a magnitude e direcao da inclinacao, mantendo o comportamento do projeto GSensor original da Terasic.

---

## Plataforma

| Item | Valor |
|------|-------|
| Placa | DE10-Lite (Terasic) |
| FPGA | Intel MAX 10 - 10M50DAF484C7G |
| Ferramenta | Quartus Prime 25.1 Lite Edition |
| Linguagem | VHDL (fontes do usuario) + Verilog (IPs de PLL gerados pelo Quartus) |
| Acelerometro | Analog Devices ADXL345 (3 eixos, interface SPI) |
| Resolucao VGA | 640 x 480 @ 60 Hz |

---

## Estrutura de Arquivos

```
projeto/
|
|-- DE10_LITE_GSensor_VGA.qpf          # Arquivo de projeto Quartus
|-- DE10_LITE_GSensor_VGA.qsf          # Configuracoes do projeto (pin assignments, fontes)
|-- DE10_LITE_GSensor_VGA.vhd          # Top-level VHDL
|
|-- vhdlgsensor/                       # Subsistema do acelerometro (VHDL)
|   |-- spi_param_pkg.vhd             #   Package de constantes SPI/ADXL345
|   |-- spi_controller.vhd            #   Controlador SPI de baixo nivel (16 bits)
|   |-- spi_ee_config.vhd             #   FSM de configuracao e leitura do ADXL345
|   |-- reset_delay.vhd               #   Gerador de reset com atraso (~21 ms)
|   |-- led_driver.vhd                #   Decodificador de LEDs por inclinacao
|
|-- vhdlvga/                           # Subsistema VGA (VHDL)
|   |-- video_sync_generator.vhd      #   Gerador de sincronismo VGA (HS, VS, blank)
|   |-- vga_controller.vhd            #   Controlador VGA com cursor do acelerometro
|
|-- veriloggsensor/                    # Fontes Verilog originais (referencia)
|   |-- spi_pll.v                     #   PLL SPI (IP gerado pelo Quartus)
|   |-- spi_pll.qip                   #   Metadados do IP PLL SPI
|   |-- spi_param.h                   #   Header de parametros (equivale ao pkg VHDL)
|   |-- spi_controller.v              #   Versao Verilog original
|   |-- spi_ee_config.v               #   Versao Verilog original
|   |-- reset_delay.v                 #   Versao Verilog original
|   |-- led_driver.v                  #   Versao Verilog original
|
|-- verilogvga/                        # Fontes VGA Verilog originais (referencia)
|   |-- vga_pll.v                     #   PLL VGA (IP gerado pelo Quartus)
|   |-- vga_pll.qip                   #   Metadados do IP PLL VGA
|   |-- vga_controller.v              #   Versao Verilog original
|   |-- video_sync_generator.v        #   Versao Verilog original
|
|-- output_files/                      # Saida da compilacao
|   |-- DE10_LITE_GSensor_VGA.sof     #   Bitstream SRAM (programacao volatil)
|   |-- DE10_LITE_GSensor_VGA.pof     #   Bitstream Flash (programacao permanente)
|   |-- *.rpt                         #   Relatorios de sintese, fitting, timing
|
|-- db/                                # Banco de dados interno do Quartus
|-- incremental_db/                    # Cache de compilacao incremental
```

---

## Arquitetura do Sistema

```
                    MAX10_CLK1_50 (50 MHz)
                          |
              +-----------+-----------+
              |                       |
         [spi_pll]               [vga_pll]
          2 MHz                   ~25 MHz
           |   |                     |
      spi_clk  spi_clk_out    vga_ctrl_clk
           |   |                     |
    +------+---+------+        +-----+--------+
    |                 |        |              |
[reset_delay]  [spi_ee_config] |    [vga_controller]
    |              |           |         |
 dly_rst      data_x[15:0]    |    VGA_HS, VGA_VS
    |              |           |    VGA_R, VGA_G, VGA_B
    |         +----+----+      |
    |         |         |      |
    |   [led_driver]  [CDC]----+
    |         |      2-stage
    |      LEDR[9:0]  sync
    |
    +-- Reset para todos os blocos
```

### Dominios de Clock

O projeto opera em **tres dominios de clock**:

| Dominio | Frequencia | Origem | Uso |
|---------|-----------|--------|-----|
| MAX10_CLK1_50 | 50 MHz | Oscilador da placa | Reset delay, LED driver |
| spi_clk / spi_clk_out | 2 MHz | spi_pll (ALTPLL) | Comunicacao SPI com ADXL345 |
| vga_ctrl_clk | ~25.175 MHz | vga_pll (ALTPLL) | Pixel clock VGA 640x480@60Hz |

### Cruzamento de Dominios (CDC)

Os dados do acelerometro (`data_x[9:0]`) sao gerados no dominio SPI (2 MHz) e consumidos no dominio VGA (~25 MHz). Para evitar metaestabilidade, um **sincronizador de dois flip-flops** faz a travessia:

```
dominio SPI          |    dominio VGA
                     |
data_x[9:0] ------->| FF1 (accel_sync1) --> FF2 (accel_sync2) --> logica de cursor
                     |
```

---

## Descricao dos Modulos

### 1. DE10_LITE_GSensor_VGA (Top-Level)

**Arquivo**: `DE10_LITE_GSensor_VGA.vhd`

Entidade principal que instancia todos os submudulos e implementa:
- Tie-off dos pinos SDRAM (nao utilizados)
- Sincronizador CDC de dois estagios
- Mapeamento aceleracao -> posicao do cursor VGA
- Clamping do cursor no intervalo [0, 639]

**Formula de mapeamento**:
```
cursor_x = clamp(320 + (raw * 5) / 8, 0, 639)
```

Onde `raw` e o valor signed de 10 bits do eixo X do acelerometro:
- `raw = 0` -> coluna 320 (centro, placa nivelada)
- `raw = +511` -> coluna 639 (extremo direito)
- `raw = -512` -> coluna 0 (extremo esquerdo)

### 2. reset_delay

**Arquivo**: `vhdlgsensor/reset_delay.vhd`

Gera um sinal de reset ativo-alto com atraso de aproximadamente 21 ms (2^20 ciclos a 50 MHz). Garante que os PLLs tenham tempo de estabilizar antes que o restante do circuito comece a operar.

| Porta | Direcao | Descricao |
|-------|---------|-----------|
| reset_n | in | Reset externo ativo baixo (KEY[0]) |
| clk | in | Clock 50 MHz |
| rst_out | out | Reset ativo alto atrasado |

### 3. spi_pll (IP Quartus)

**Arquivo**: `veriloggsensor/spi_pll.v` (gerado pelo IP Catalog)

PLL (ALTPLL) que gera dois clocks de 2 MHz a partir do clock de 50 MHz:
- **c0** (`spi_clk`): clock principal SPI
- **c1** (`spi_clk_out`): clock defasado para gerar o sinal de clock externo ao sensor

### 4. spi_controller

**Arquivo**: `vhdlgsensor/spi_controller.vhd`

Controlador SPI de baixo nivel que realiza transacoes de 16 bits com o ADXL345:

- **Formato da palavra**: `[15] R/W | [14:8] endereco | [7:0] dados`
- **Contador regressivo**: de 15 a 0 (16 ciclos por transacao)
- **Linha bidirecional SDIO**: tristate durante fase de dados em modo leitura
- **Chip select**: ativo durante toda a transacao (`spi_go = '1'`)

| Porta | Direcao | Descricao |
|-------|---------|-----------|
| reset_n | in | Reset ativo baixo |
| spi_clk | in | Clock SPI 2 MHz |
| spi_clk_out | in | Clock SPI defasado |
| p2s_data | in | Dados paralelo->serial (16 bits) |
| spi_go | in | Inicia transferencia |
| spi_end | out | Indica fim da transferencia |
| s2p_data | out | Dados serial->paralelo (8 bits) |
| spi_sdio | inout | Linha bidirecional SPI |
| spi_csn | out | Chip select ativo baixo |
| spi_clk_o | out | Clock SPI para o sensor |

### 5. spi_ee_config

**Arquivo**: `vhdlgsensor/spi_ee_config.vhd`

FSM (maquina de estados finitos) que gerencia a configuracao e leitura continua do ADXL345:

**Fase 1 - Inicializacao** (11 escritas de registros):

| # | Registro | Valor | Descricao |
|---|----------|-------|-----------|
| 0 | THRESH_ACT (0x24) | 0x20 | Limiar de atividade |
| 1 | THRESH_INACT (0x25) | 0x03 | Limiar de inatividade |
| 2 | TIME_INACT (0x26) | 0x01 | Tempo de inatividade |
| 3 | ACT_INACT_CTL (0x27) | 0x7F | Controle atividade/inatividade |
| 4 | THRESH_FF (0x28) | 0x09 | Limiar de queda livre |
| 5 | TIME_FF (0x29) | 0x46 | Tempo de queda livre |
| 6 | BW_RATE (0x2C) | 0x09 | Taxa de dados: 50 Hz |
| 7 | INT_ENABLE (0x2E) | 0x10 | Habilita interrupcao DATA_READY |
| 8 | INT_MAP (0x2F) | 0x10 | Mapeia DATA_READY para INT2 |
| 9 | DATA_FORMAT (0x31) | 0x40 | Modo SPI 3 fios |
| 10 | POWER_CONTROL (0x2D) | 0x08 | Inicia medicoes |

**Fase 2 - Leitura continua**:
1. Verifica interrupcao INT2 ou timeout -> le registro INT_SOURCE
2. Se bit DATA_READY ativo -> le byte baixo do eixo X (0x32)
3. Le byte alto do eixo X (0x33)
4. Atualiza saidas `data_l` e `data_h`
5. Volta ao passo 1

### 6. spi_param_pkg

**Arquivo**: `vhdlgsensor/spi_param_pkg.vhd`

Package VHDL contendo todas as constantes do subsistema SPI (equivalente ao `spi_param.h` Verilog):
- Dimensoes de dados (SI_DataL=15, SO_DataL=7, IDLE_MSB=14)
- Modos de operacao (SPI_WRITE_MODE, SPI_READ_MODE)
- Numero de registros de inicializacao (INI_NUMBER=11)
- Estados da FSM (SPI_IDLE, SPI_TRANSFER)
- Enderecos de registros do ADXL345 (escrita e leitura)

### 7. led_driver

**Arquivo**: `vhdlgsensor/led_driver.vhd`

Converte os dados do acelerometro (10 bits signed) em padroes visuais nos 10 LEDs da placa:

- **Resolucao +/- 2g** (g_int2='1'): usa bits [9:5] diretamente
- **Resolucao +/- 1g** (g_int2='0'): usa 9 bits com saturacao
- **Indicador de atividade**: quando ha deteccao de movimento, os LEDs piscam por ~168 ms antes de mostrar o padrao de inclinacao
- O padrao de LEDs acesos indica a magnitude e direcao da inclinacao

### 8. vga_pll (IP Quartus)

**Arquivo**: `verilogvga/vga_pll.v` (gerado pelo IP Catalog)

PLL (ALTPLL) que gera o pixel clock de ~25.175 MHz a partir do clock de 50 MHz para o padrao VGA 640x480@60Hz.

### 9. video_sync_generator

**Arquivo**: `vhdlvga/video_sync_generator.vhd`

Gerador de sincronismo VGA com temporização padrao 640x480@60Hz:

| Parametro | Horizontal (pixels) | Vertical (linhas) |
|-----------|--------------------|--------------------|
| Total | 800 | 525 |
| Sync pulse | 96 | 2 |
| Back porch | 144 | 34 |
| Area visivel | 640 | 480 |
| Front porch | 16 | 11 |

- Contadores operam na **borda de descida** do pixel clock
- Saidas (HS, VS, blank_n) registradas na borda de descida

### 10. vga_controller

**Arquivo**: `vhdlvga/vga_controller.vhd`

Controlador VGA que gera a imagem com a barra do cursor:

- Instancia o `video_sync_generator` para sincronismo
- Mantem um **contador de coluna** (0-639) para rastrear a posicao horizontal
- Gera cores:
  - **Barra branca** (0xFFFFFF): nas colunas `cursor_x +/- 2` (5 pixels de largura)
  - **Fundo cinza escuro** (0x202020): restante da area visivel
  - **Preto** (0x000000): durante blanking
- **Pipeline de sincronismo**: HS/VS/blank sao atrasados 2 ciclos para alinhar com os dados de cor
- Saida VGA de 4 bits por canal (R, G, B)

---

## Pinagem Principal

### Clocks
| Sinal | Pino | Descricao |
|-------|------|-----------|
| ADC_CLK_10 | PIN_N5 | Clock 10 MHz (nao utilizado) |
| MAX10_CLK1_50 | PIN_P11 | Clock principal 50 MHz |
| MAX10_CLK2_50 | PIN_N14 | Clock 50 MHz secundario (nao utilizado) |

### Acelerometro (ADXL345)
| Sinal | Pino | Descricao |
|-------|------|-----------|
| GSENSOR_CS_N | PIN_AB16 | Chip select SPI (ativo baixo) |
| GSENSOR_SCLK | PIN_AB15 | Clock SPI |
| GSENSOR_SDI | PIN_V11 | Dados SPI (bidirecional) |
| GSENSOR_SDO | PIN_V12 | Dados SPI secundario |
| GSENSOR_INT[1] | PIN_Y14 | Interrupcao 1 |
| GSENSOR_INT[2] | PIN_Y13 | Interrupcao 2 |

### VGA
| Sinal | Pino | Descricao |
|-------|------|-----------|
| VGA_HS | PIN_N3 | Sincronismo horizontal |
| VGA_VS | PIN_N1 | Sincronismo vertical |
| VGA_R[3:0] | PIN_Y1, Y2, V1, AA1 | Canal vermelho (4 bits) |
| VGA_G[3:0] | PIN_R1, R2, T2, W1 | Canal verde (4 bits) |
| VGA_B[3:0] | PIN_N2, P4, T1, P1 | Canal azul (4 bits) |

### Botoes e LEDs
| Sinal | Pino | Descricao |
|-------|------|-----------|
| KEY[0] | PIN_B8 | Botao de reset |
| KEY[1] | PIN_A7 | Botao secundario (nao utilizado) |
| LEDR[9:0] | PIN_A8..B11 | 10 LEDs vermelhos |

---

## Fluxo de Dados

```
  ADXL345          SPI (2 MHz)              VGA (~25 MHz)           Monitor
+---------+    +----------------+    +------------------------+    +-------+
| Sensor  |--->| spi_ee_config  |--->| CDC (2 flip-flops)     |    |       |
| eixo X  |    | + spi_controller|   | accel_sync1 -> sync2   |    |       |
+---------+    +-------+--------+    +----------+-------------+    |       |
                       |                        |                  |       |
                       v                        v                  |       |
                  data_x[9:0]          raw -> *5 -> >>3 -> +320    |       |
                  (signed 10b)          -> clamp(0, 639)           |       |
                       |                        |                  |       |
                       v                        v                  |       |
                 +----------+          +----------------+          |       |
                 |led_driver|          |vga_controller  |--------->| VGA   |
                 +----+-----+          | cursor branco  |  HS,VS  |       |
                      |                | fundo cinza    |  R,G,B  |       |
                      v                +----------------+          +-------+
                  LEDR[9:0]
```

---

## Conversao Verilog para VHDL

O projeto foi originalmente escrito em Verilog e convertido para VHDL. As principais diferencas na conversao foram:

### Mapeamento de conceitos

| Verilog | VHDL |
|---------|------|
| `spi_param.h` (include) | `spi_param_pkg.vhd` (package) |
| `parameter` | `constant` no package |
| `wire` / `reg` | `signal` |
| `assign` | Atribuicao concorrente (`<=` fora de process) |
| `always @(posedge clk)` | `process(clk) ... rising_edge(clk)` |
| `always @(negedge clk)` | `process(clk) ... falling_edge(clk)` |
| `always @(*)` ou `always @(var)` | `process(var)` (combinatorial) |
| Truncamento implicito | `resize()` explicito |
| `$signed()` | `signed()` cast |
| `>>>` (shift aritmetico) | Extracao de bits `scaled(13 downto 3)` |
| `? :` (ternario) | `when ... else` |
| `1'bz` | `'Z'` |
| `negedge reset` | `reset_n = '0'` no sensitivity list |

### Problemas encontrados e corrigidos

1. **Colisao de nomes**: `WRITE_MODE` e `READ_MODE` no package colidiam com nomes do pacote `standard` do VHDL. Renomeados para `SPI_WRITE_MODE` e `SPI_READ_MODE`.

2. **Largura de multiplicacao**: em Verilog, `signed(11b) * signed(5b)` pode ser atribuido a um wire de 14 bits com truncamento implicito. Em VHDL, `signed * signed` retorna tamanho exato (A'length + B'length), exigindo `resize()` explicito.

3. **Sinal nao utilizado**: `vga_blank_n` declarado mas nunca lido no top-level. Removido e substituido por `open` no port map.

### PLLs

Os PLLs (`spi_pll` e `vga_pll`) permanecem em Verilog pois sao IPs gerados automaticamente pelo Quartus (ALTPLL). O Quartus suporta projetos com linguagens mistas sem problemas. Para ter PLLs em VHDL, e necessario regenera-los pelo IP Catalog selecionando VHDL como formato de saida.

---

## Como Compilar

1. Abrir o Quartus Prime (25.1 Lite Edition ou superior)
2. Abrir o projeto: `File > Open Project > DE10_LITE_GSensor_VGA.qpf`
3. Compilar: `Processing > Start Compilation` (ou Ctrl+L)
4. Aguardar a compilacao completa (sintese, fitting, timing analysis, assembler)

## Como Programar a Placa

1. Conectar a DE10-Lite via cabo USB-Blaster
2. `Tools > Programmer`
3. Para programacao **volatil** (perde ao desligar): usar `DE10_LITE_GSensor_VGA.sof`
4. Para programacao **permanente** (flash): usar `DE10_LITE_GSensor_VGA.pof`
5. Clicar em "Start"

## Como Usar

1. Conectar um monitor VGA ao conector VGA da placa
2. Programar a FPGA
3. A tela mostrara um fundo cinza escuro com uma barra branca vertical no centro
4. Inclinar a placa para a esquerda/direita: a barra se move acompanhando
5. Os LEDs indicam a magnitude da inclinacao
6. Pressionar KEY[0] para resetar o sistema

---

## Recursos Utilizados da FPGA

- 2x ALTPLL (PLL SPI + PLL VGA)
- Pinos GPIO: acelerometro SPI, VGA, LEDs, botoes
- Logica combinacional e registradores para FSM SPI, geracao VGA e CDC
- SDRAM e Arduino headers nao utilizados (tied off)
