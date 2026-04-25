# Lógica Reconfigurável (LRCO7A) — UTFPR Apucarana

Repositório dos projetos e atividades da disciplina de **Lógica Reconfigurável (LRCO7A)** do curso de **Engenharia da Computação** da **UTFPR — Câmpus Apucarana**.

Todo o desenvolvimento é em **VHDL** para a placa **Terasic DE10-Lite** (FPGA Intel/Altera **MAX 10 — 10M50DAF484C7G**), utilizando o **Quartus Prime Lite**.

> Repositório em construção — será atualizado ao longo do semestre conforme novas atividades e projetos forem desenvolvidos.

---

## Estrutura do repositório

```
projetosfpga/
├── atividade1/             ← Atividade 1: Portas lógicas básicas (relatório 1 e 2)
├── ATIVIDADE2LOGICA/       ← Atividade 2: Circuito de máquina de cópias (Karnaugh)
├── atividade3/             ← Atividade 3: Decodificador BCD → 7 segmentos
├── game/                   ← Projeto integrador: Acelerômetro + VGA + LEDs
│   ├── projeto/            ← Versão híbrida (Verilog + VHDL) — base de referência
│   └── fullvhdl/           ← Versão final 100% VHDL
├── ideiasprojetosfpga/     ← Rascunhos e protótipos de ideias (game logic, etc.)
└── README.md
```

---

## Atividades

### Atividade 1 — Portas lógicas
**Pasta:** [`atividade1/`](atividade1/)

Implementação em VHDL das 8 portas lógicas básicas (NOT A, NOT B, AND, OR, NAND, NOR, XOR, XNOR) com duas entradas A e B. Inclui dois relatórios:

- `relatorio1/` — Implementação inicial e simulação com GTKWave/GHDL.
- `relatorio2/` — Exercício de circuito de máquina de cópias com mapa de Karnaugh.

### Atividade 2 — Circuito de controle (máquina de cópias)
**Pasta:** [`ATIVIDADE2LOGICA/`](ATIVIDADE2LOGICA/)

Saída em nível alto quando 2 ou mais chaves estão fechadas. Considera `SW1·SW4` como *don't care* (combinação que nunca ocorre). Equação simplificada via mapa de Karnaugh.

**Pinagem:** SW0–SW3 nas chaves físicas, saída em LEDR0.

### Atividade 3 — Decodificador BCD → 7 segmentos
**Pasta:** [`atividade3/`](atividade3/)

Decodificador combinacional que converte dois valores BCD de 4 bits (8 chaves) em dois displays de 7 segmentos (anodo comum). Valores acima de 9 exibem `E` (erro).

---

## Projeto integrador — Acelerômetro + VGA + LEDs

**Pasta:** [`game/`](game/)

Projeto que combina três periféricos da DE10-Lite:

1. **Acelerômetro ADXL345** lido via **SPI 3-wire** (PLL dedicada de 2 MHz)
2. **Saída VGA 640×480@60Hz** com PLL de ~25 MHz
3. **10 LEDs vermelhos** indicando posição do eixo X (efeito de "nível de bolha")

A inclinação da placa no eixo X move uma **barra branca vertical** no monitor VGA e desloca o padrão de LEDs acesos. Como toda a lógica é combinacional (e o SPI/VGA rodam em paralelo dentro do FPGA), basta amostrar o valor do acelerômetro e propagar para os módulos de saída — não há CPU nem firmware envolvidos.

### Subpastas

- **`game/projeto/`** — Versão híbrida com módulos originais em Verilog (referência da Terasic) e adaptações em VHDL. Usada como base para garantir a pinagem correta do `g-sensor`.
- **`game/fullvhdl/`** — Versão final com **todos os módulos reescritos em VHDL** (exceto as PLLs, que continuam em Verilog por serem IP gerado pelo Quartus). É a versão recomendada para abrir no Quartus.

> Veja o [`README.md`](game/fullvhdl/README.md) dentro de `game/fullvhdl/` para instruções detalhadas de compilação, mapeamento de pinos e troubleshooting.

### Hierarquia (versão fullvhdl)

```
DE10_LITE_GSensor_VGA (top)
├── reset_delay              — atraso de reset pós-power-on
├── spi_pll                  — PLL 2 MHz para SPI (Verilog IP)
├── spi_ee_config            — FSM de inicialização e leitura contínua
│   └── spi_controller       — bit-bang SPI com tristate SDIO
├── led_driver               — mapeamento aceleração → LEDs
├── vga_pll                  — PLL ~25 MHz para VGA (Verilog IP)
└── vga_controller           — controlador VGA com cursor
    └── video_sync_generator — gerador de sync H/V
```

---

## Ideias e protótipos

**Pasta:** [`ideiasprojetosfpga/`](ideiasprojetosfpga/)

Espaço para rascunhos, protótipos e versões alternativas dos projetos — não são entregáveis, mas servem de histórico de experimentação (ex.: `accel_vga_top.vhd`, `game_logic.vhd`, testbenches de VGA).

---

## Como abrir os projetos no Quartus

Cada subprojeto contém um arquivo `.qpf` (Quartus Project File). Para abrir:

1. Abra o **Quartus Prime Lite**.
2. **File → Open Project...**
3. Navegue até a pasta da atividade desejada e selecione o `.qpf`.

> O dispositivo de destino é sempre o **MAX 10 — 10M50DAF484C7G** (DE10-Lite).
> Se o pinout não estiver carregado, importe via **Assignments → Import Assignments** apontando para o `.qsf` da pasta.

---

## Pré-requisitos

- **Quartus Prime Lite** (versão 18.1 ou superior recomendada)
- **Placa Terasic DE10-Lite** com cabo USB-Blaster
- (Opcional, para simulação) **ModelSim**, **GHDL** + **GTKWave**
- (Opcional, para os relatórios) **LaTeX** (TeXLive / MikTeX)

---

## Observações sobre o `.gitignore`

Projetos do Quartus geram **muitos arquivos intermediários grandes** (`db/`, `incremental_db/`, `output_files/`, `simulation/`, `*.qws`, etc.). Esses arquivos são **regenerados na compilação** e estão ignorados no `.gitignore` para manter o repositório enxuto.

O conteúdo de `DE10-Lite_v.2.2.0_SystemCD/` (CD do fabricante) também não é versionado — é IP da Terasic/Intel e está disponível no site oficial.

---

## Autor

**Pedro Lucas Reis** — Engenharia da Computação · UTFPR Apucarana
📧 pedrolucas@alunos.utfpr.edu.br
🔗 [github.com/plreis](https://github.com/plreis)
