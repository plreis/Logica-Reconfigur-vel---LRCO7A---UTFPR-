# Projeto: DE10_LITE_GSensor_VGA

Projeto VHDL para a placa **Terasic DE10-Lite (MAX 10 — 10M50DAF484C7G)**.  
Combina o acelerômetro ADXL345 (G-Sensor via SPI) com saída VGA 640×480@60Hz.

## O que o projeto faz

- Lê o eixo X do acelerômetro via SPI 3-wire (2 MHz, PLL dedicada)
- Exibe uma **barra branca vertical** no monitor VGA cuja posição muda com a inclinação
- Controla os **10 LEDs vermelhos** com o padrão de nível de bolha do demo original

---

## Estrutura de pastas

```
fullvhdl/
├── DE10_LITE_GSensor_VGA.vhd      ← Top-level (ENTIDADE PRINCIPAL)
├── DE10_LITE_GSensor_VGA.qpf      ← Arquivo de projeto Quartus
├── DE10_LITE_GSensor_VGA.qsf      ← Configurações do projeto (device, arquivos, pinos)
├── pll/
│   ├── spi_pll/
│   │   ├── spi_pll.v              ← PLL 2 MHz para SPI (Verilog — gerado pelo Quartus)
│   │   ├── spi_pll_bb.v           ← Black-box para simulação
│   │   ├── spi_pll.ppf            ← Metadado do IP
│   │   └── spi_pll.qip            ← Referência IP para Quartus
│   └── vga_pll/
│       ├── vga_pll.v              ← PLL ~25 MHz para VGA (Verilog — gerado pelo Quartus)
│       ├── vga_pll_bb.v           ← Black-box para simulação
│       └── vga_pll.qip            ← Referência IP para Quartus
├── vhdlgsensor/
│   ├── spi_param_pkg.vhd          ← Constantes do ADXL345 (pacote VHDL)
│   ├── spi_controller.vhd         ← Controlador SPI bit-a-bit (tristate SDIO)
│   ├── spi_ee_config.vhd          ← FSM: inicialização + leitura contínua eixo X
│   ├── reset_delay.vhd            ← Atraso de reset (~21 ms)
│   └── led_driver.vhd             ← Mapeamento aceleração → LEDs
└── vhdlvga/
    ├── video_sync_generator.vhd   ← Gerador de sync VGA 640×480@60Hz
    └── vga_controller.vhd         ← Controlador VGA + lógica da barra do cursor
```

---

## Como abrir o projeto no Quartus Prime (passo a passo)

### Opção A — Abrir pelo arquivo .qpf (recomendado)

1. Abra o **Quartus Prime Lite**
2. Vá em **File → Open Project...**
3. Navegue até esta pasta (`fullvhdl/`)
4. Selecione o arquivo **`DE10_LITE_GSensor_VGA.qpf`**
5. Clique em **Open**

O Quartus carregará automaticamente todos os arquivos configurados no `.qsf`.

---

### Opção B — Criar um projeto novo do zero

Use esta opção se quiser recriar o projeto completamente via assistente:

1. Abra o **Quartus Prime Lite**
2. Vá em **File → New Project Wizard...**
3. **Passo 1 — Diretório e nome:**
   - Working directory: caminho completo para esta pasta `fullvhdl/`
   - Project name: `DE10_LITE_GSensor_VGA`
   - Top-level entity: `DE10_LITE_GSensor_VGA`
   - Clique **Next**
4. **Passo 2 — Tipo de projeto:** selecione *Empty project*, clique **Next**
5. **Passo 3 — Adicionar arquivos:** adicione TODOS os arquivos abaixo na ordem:

   | Arquivo | Tipo |
   |---------|------|
   | `pll/spi_pll/spi_pll.qip` | QIP (IP File) |
   | `pll/vga_pll/vga_pll.qip` | QIP (IP File) |
   | `vhdlgsensor/spi_param_pkg.vhd` | VHDL |
   | `vhdlgsensor/spi_controller.vhd` | VHDL |
   | `vhdlgsensor/spi_ee_config.vhd` | VHDL |
   | `vhdlgsensor/reset_delay.vhd` | VHDL |
   | `vhdlgsensor/led_driver.vhd` | VHDL |
   | `vhdlvga/video_sync_generator.vhd` | VHDL |
   | `vhdlvga/vga_controller.vhd` | VHDL |
   | `DE10_LITE_GSensor_VGA.vhd` | VHDL |

   > **IMPORTANTE:** adicione os arquivos `.qip` antes dos VHDL.  
   > Para adicionar um `.qip`: clique em **Add**, mude o filtro de tipo para *All Files*, selecione o `.qip` e clique **Open**.

6. **Passo 4 — Device:**
   - Family: **MAX 10**
   - Device: **10M50DAF484C7G**  
     (no campo de filtro, digita `10M50DAF484C7G` e seleciona da lista)
   - Clique **Next**

7. **Passo 5 — EDA Tools:** deixe padrão, clique **Next**
8. Clique **Finish**

---

### Verificar a entidade top-level

Após abrir o projeto, confirme que a entidade top está correta:

1. Vá em **Assignments → Settings...**
2. Na aba **General**, confira:
   - Top-level entity: `DE10_LITE_GSensor_VGA`

---

## Compilar o projeto

1. Vá em **Processing → Start Compilation** (ou pressione `Ctrl+L`)
2. Aguarde — a compilação completa demora alguns minutos
3. Se aparecerem **erros**, veja a seção de troubleshooting abaixo
4. Se aparecerem apenas **warnings** (sem erros), o projeto está pronto para gravar

---

## Gravar na placa

1. Conecte a placa DE10-Lite via USB ao computador
2. Ligue a placa
3. Vá em **Tools → Programmer**
4. Clique em **Hardware Setup** e confirme que o cabo USB-Blaster aparece
5. Clique em **Add File...** e selecione o arquivo `.sof` gerado:  
   `output_files/DE10_LITE_GSensor_VGA.sof`
6. Marque a caixa **Program/Configure**
7. Clique em **Start**

> O arquivo `.sof` é volátil — será apagado ao desligar a placa.  
> Para gravar permanentemente, gere um `.pof` e use o modo CFM.

---

## Mapeamento de pinos (Pin Assignment)

Se o Quartus não reconhecer os pinos automaticamente pelo `.qsf`, adicione-os manualmente em  
**Assignments → Pin Planner** ou via **Assignments → Import Assignments** usando o arquivo `.qsf`.

Pinos principais:

| Sinal VHDL | Pino | Descrição |
|------------|------|-----------|
| `max10_clk1_50` | PIN_P11 | Clock 50 MHz |
| `key(0)` | PIN_B8 | Botão reset (ativo baixo) |
| `ledr(0..9)` | PIN_A8..PIN_B11 | LEDs vermelhos |
| `vga_r(3..0)` | PIN_AA1..PIN_V1 | VGA vermelho |
| `vga_g(3..0)` | PIN_Y2..PIN_W1 | VGA verde |
| `vga_b(3..0)` | PIN_R1..PIN_P1 | VGA azul |
| `vga_hs` | PIN_N3 | VGA sync horizontal |
| `vga_vs` | PIN_N1 | VGA sync vertical |
| `gsensor_cs_n` | PIN_AB16 | Acelerômetro CS |
| `gsensor_sclk` | PIN_AB15 | Acelerômetro clock |
| `gsensor_sdi` | PIN_V11 | Acelerômetro dados (bidirecional) |
| `gsensor_sdo` | PIN_V12 | Acelerômetro SDO |
| `gsensor_int(1)` | PIN_Y14 | Interrupção 1 do sensor |
| `gsensor_int(2)` | PIN_Y13 | Interrupção 2 do sensor |

---

## Troubleshooting

### Erro: `Use Clause error ... "write_mode"`
**Causa:** Constante com nome conflitante com VHDL built-in.  
**Status:** ✅ Já corrigido — `WRITE_MODE` renomeado para `SPI_WRITE` no pacote.

### Erro: `Can't find entity spi_pll` ou `vga_pll`
**Causa:** Arquivos `.qip` das PLLs não estão no projeto.  
**Solução:** Confirme que os arquivos `pll/spi_pll/spi_pll.qip` e `pll/vga_pll/vga_pll.qip` existem e estão listados no QSF ou adicionados pelo wizard.

### Erro: `Device ... is not supported`
**Causa:** Device no projeto é diferente do chip na placa.  
**Solução:** Vá em **Assignments → Device** e selecione `10M50DAF484C7G`.  
**Status:** ✅ Já corrigido no QSF.

### Warning: `Clock ... had hold time violation`
Pode aparecer por diferença de fase entre as PLLs. Não impede o funcionamento básico.

### LEDs não acendem / VGA sem imagem
1. Confirme que a placa está com o `.sof` gravado (LED CONF_DONE aceso)
2. Verifique o cabo VGA e se o monitor está no canal certo
3. Pressione KEY(0) para forçar reset

---

## Hierarquia de módulos

```
DE10_LITE_GSensor_VGA (top)
├── reset_delay          — atraso de reset pós-power-on
├── spi_pll              — PLL 2 MHz para SPI (Verilog IP)
├── spi_ee_config        — FSM principal do acelerômetro
│   └── spi_controller   — bit-bang SPI com tristate
├── led_driver           — LEDs de nível de bolha
├── vga_pll              — PLL ~25 MHz para VGA (Verilog IP)
└── vga_controller       — controlador VGA com cursor
    └── video_sync_generator — gerador de sync H/V
```
