# DE10-Lite — GSensor + VGA

Projeto desenvolvido na disciplina de FPGA da UTFPR Apucarana.
Combina leitura do acelerômetro ADXL345 com exibição em monitor VGA na placa DE10-Lite (Intel MAX 10).

---

## Funcionamento

- O acelerômetro lê o **eixo X** via protocolo SPI
- Uma **barra vertical branca** se move horizontalmente no monitor conforme a inclinação da placa
- Os **10 LEDs** continuam indicando magnitude e direção da inclinação (comportamento original preservado)
- Placa nivelada → barra no centro (coluna 320)
- Inclinar para a esquerda → barra se move para a esquerda
- Inclinar para a direita → barra se move para a direita

---

## Estrutura do projeto

```
projeto/
├── DE10_LITE_GSensor_VGA.v        # Top-level Verilog
├── DE10_LITE_GSensor_VGA.vhd      # Top-level VHDL
├── DE10_LITE_GSensor_VGA.qpf      # Arquivo de projeto Quartus
├── DE10_LITE_GSensor_VGA.qsf      # Pinagem e arquivos fonte
├── DE10_LITE_GSensor.sdc          # Constraints de timing
│
├── veriloggsensor/                # Módulos Verilog — GSensor
│   ├── spi_param.h                # Constantes e endereços do ADXL345
│   ├── spi_pll.v / .qip           # PLL 2 MHz para SPI
│   ├── spi_controller.v           # Controlador SPI (16 bits, tristate)
│   ├── spi_ee_config.v            # FSM de inicialização e leitura do sensor
│   ├── reset_delay.v              # Delay de reset (~21 ms)
│   └── led_driver.v               # Decodificador aceleração → LEDs
│
├── verilogvga/                    # Módulos Verilog — VGA
│   ├── vga_pll.v / .qip           # PLL ~25 MHz para pixel clock
│   ├── video_sync_generator.v     # Sincronismo 640×480@60Hz
│   └── vga_controller.v           # Gerador de imagem com cursor
│
├── vhdlgsensor/                   # Conversão VHDL — GSensor
│   ├── spi_param_pkg.vhd          # Package com constantes (equiv. spi_param.h)
│   ├── reset_delay.vhd
│   ├── spi_controller.vhd
│   ├── spi_ee_config.vhd
│   └── led_driver.vhd
│
└── vhdlvga/                       # Conversão VHDL — VGA
    ├── video_sync_generator.vhd
    └── vga_controller.vhd
```

---

## Hardware utilizado

| Recurso | Uso |
|---------|-----|
| FPGA | Intel MAX 10 (10M50DAF484C7G) |
| Placa | DE10-Lite (Terasic) |
| Sensor | ADXL345 (acelerômetro 3 eixos, SPI) |
| Display | Monitor VGA 640×480 @ 60 Hz |
| LEDs | LEDR[9:0] — indicador de inclinação |

---

## Clocks

| Domínio | Frequência | Origem |
|---------|-----------|--------|
| `MAX10_CLK1_50` | 50 MHz | Oscilador da placa |
| `spi_clk` | 2 MHz | `spi_pll` (c0) |
| `spi_clk_out` | 2 MHz (defasado) | `spi_pll` (c1) |
| `vga_ctrl_clk` | ~25 MHz | `vga_pll` (c0) |

---

## Mapeamento de posição (aceleração → cursor)

```
cursor_x = clamp(320 + (raw × 5) >> 3,  0, 639)

raw = valor signed 10-bit do ADXL345 (complemento de dois)
  raw =    0  →  cursor = 320  (centro)
  raw = +511  →  cursor = 639  (direita)
  raw = -512  →  cursor =   0  (esquerda)
```

Sincronização de domínio de clock (CDC): dois flip-flops no domínio VGA
evitam metaestabilidade ao amostrar o dado SPI (2 MHz) no clock VGA (~25 MHz).

---

## Como abrir no Quartus

1. **File → Open Project** → selecionar `DE10_LITE_GSensor_VGA.qpf`
2. **Processing → Start Compilation** (`Ctrl+L`)
3. **Tools → Programmer** → gravar na placa

---

## Histórico de desenvolvimento

| Data | Descrição |
|------|-----------|
| 2026-04-08 | Projeto combinado Verilog criado e gravado na placa com sucesso |
| 2026-04-08 | Conversão completa para VHDL gerada |
