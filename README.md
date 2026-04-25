# Lógica Reconfigurável (LRCO7A) — UTFPR Apucarana

Repositório dos projetos e atividades da disciplina de **Lógica Reconfigurável (LRCO7A)** do curso de **Engenharia da Computação** da **UTFPR — Câmpus Apucarana**.

Todo o desenvolvimento é em **VHDL** para a placa **Terasic DE10-Lite** (FPGA Intel/Altera **MAX 10 — 10M50DAF484C7G**), utilizando o **Quartus Prime Lite**.

> Repositório em construção — atualizado ao longo do semestre conforme novas atividades e projetos forem desenvolvidos.

---

## Estrutura do repositório

```
projetosfpga/
├── atividade1/                        ← AT1: Portas lógicas (NOT, AND, OR, NAND, NOR, XOR, XNOR)
├── atividade2/                        ← AT2: Circuito de máquina de cópias (Karnaugh)
├── atividade3/                        ← AT3: Decodificador BCD → 7 segmentos
├── projeto-acelerometro-vga/          ← Projeto integrador: ADXL345 + VGA + LEDs
│   ├── vhdl/                          ← Versão final 100% VHDL
│   └── referencia-verilog/            ← Versão híbrida Verilog+VHDL (referência)
├── prototipos/                        ← Rascunhos, testbenches e protótipos
├── templates/
│   └── relatorio-tecnico/             ← Template LaTeX para relatórios
├── README.md
└── .gitignore
```

Cada atividade segue o mesmo padrão:

```
atividadeN/
├── enunciado.pdf       ← Enunciado fornecido pela disciplina
├── relatorio.pdf       ← Relatório final entregue
├── atividadeN.vhd      ← Código-fonte VHDL
├── atividadeN.qpf      ← Arquivo de projeto Quartus
├── atividadeN.qsf      ← Configurações (device, pinagem, arquivos)
└── relatorio/          ← Fontes LaTeX do relatório (.tex, .bib, imagens)
```

---

## Atividades

### Atividade 1 — Portas lógicas
**Pasta:** [`atividade1/`](atividade1/) · **Relatório:** [`atividade1/relatorio.pdf`](atividade1/relatorio.pdf)

Implementação em VHDL das 8 portas lógicas básicas (NOT A, NOT B, AND, OR, NAND, NOR, XOR, XNOR) com duas entradas A e B. Inclui simulação com **GHDL + GTKWave** e modelagem com **Logisim** (`atividade1.circ`).

### Atividade 2 — Circuito de controle (máquina de cópias)
**Pasta:** [`atividade2/`](atividade2/) · **Relatório:** [`atividade2/relatorio.pdf`](atividade2/relatorio.pdf)

Saída em nível alto quando 2 ou mais chaves estão fechadas. Combinação `SW1·SW4` é *don't care* (nunca ocorre). Equação simplificada via mapa de Karnaugh:

```
z = SW1·SW2 + SW1·SW3 + SW2·SW3 + SW2·SW4 + SW3·SW4
```

**Pinagem:** chaves SW0–SW3 da placa, saída em LEDR0.

### Atividade 3 — Decodificador BCD → 7 segmentos
**Pasta:** [`atividade3/`](atividade3/) · **Relatório:** [`atividade3/relatorio.pdf`](atividade3/relatorio.pdf)

Decodificador combinacional que converte dois valores BCD de 4 bits (8 chaves) em dois displays de 7 segmentos (anodo comum). Valores acima de 9 exibem `E` (erro). Atividade desenvolvida em dupla com **Lucas Viana**.

---

## Projeto integrador — Acelerômetro + VGA + LEDs

**Pasta:** [`projeto-acelerometro-vga/`](projeto-acelerometro-vga/)

Combina três periféricos da DE10-Lite em um único sistema combinacional:

1. **Acelerômetro ADXL345** lido via **SPI 3-wire** (PLL dedicada de 2 MHz)
2. **Saída VGA 640×480 @ 60 Hz** com PLL de ~25 MHz
3. **10 LEDs vermelhos** com padrão de "nível de bolha" indicando o eixo X

Inclinando a placa no eixo X, uma **barra branca vertical** se desloca no monitor VGA e o padrão de LEDs acompanha. Como toda a lógica é combinacional e o SPI/VGA rodam em paralelo dentro do FPGA, basta amostrar o valor do acelerômetro e propagar para os módulos de saída — sem CPU nem firmware.

### Subpastas

- **[`vhdl/`](projeto-acelerometro-vga/vhdl/)** — versão final com **todos os módulos reescritos em VHDL** (exceto as PLLs, que continuam em Verilog por serem IP gerado pelo Quartus). É a versão recomendada para abrir no Quartus. Veja o [README dedicado](projeto-acelerometro-vga/vhdl/README.md) para instruções de compilação.
- **[`referencia-verilog/`](projeto-acelerometro-vga/referencia-verilog/)** — versão híbrida com módulos originais em Verilog (referência da Terasic) e adaptações em VHDL. Mantida como histórico e para garantir o mapeamento correto de pinos.

### Hierarquia (versão `vhdl/`)

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

## Protótipos e ideias

**Pasta:** [`prototipos/`](prototipos/)

Rascunhos, protótipos e versões alternativas — não são entregáveis, mas servem de histórico de experimentação. Inclui:

- `accel_vga_top.vhd` — primeira tentativa de top-level integrado
- `game_logic.vhd` — esboço de lógica de jogo controlada por inclinação
- `tb_vga_render.vhd` — testbench para renderização VGA
- Scripts ModelSim (`.do`) para simulações específicas

---

## Templates

**Pasta:** [`templates/relatorio-tecnico/`](templates/relatorio-tecnico/)

Template LaTeX padrão para relatórios técnicos da disciplina. Copie a pasta para iniciar um novo relatório.

---

## Como abrir os projetos no Quartus

Cada subprojeto contém um arquivo `.qpf` (Quartus Project File). Para abrir:

1. Abra o **Quartus Prime Lite**.
2. **File → Open Project...**
3. Navegue até a pasta da atividade desejada e selecione o `.qpf`.

> O dispositivo de destino é sempre o **MAX 10 — 10M50DAF484C7G** (DE10-Lite).
> Se a pinagem não estiver carregada, importe via **Assignments → Import Assignments** apontando para o `.qsf` da pasta.

---

## Pré-requisitos

- **Quartus Prime Lite** (18.1 ou superior recomendado)
- **Placa Terasic DE10-Lite** com cabo USB-Blaster
- (Opcional, para simulação) **ModelSim**, **GHDL** + **GTKWave**
- (Opcional, para os relatórios) **LaTeX** (TeXLive / MikTeX)

---

## Sobre o `.gitignore`

Projetos do Quartus geram **muitos arquivos intermediários grandes** (`db/`, `incremental_db/`, `output_files/`, `simulation/`, `*.qws`, etc.). Esses arquivos são **regenerados na compilação** e estão ignorados para manter o repositório enxuto.

O CD do fabricante (`DE10-Lite_v.2.2.0_SystemCD/`, ~207 MB) também não é versionado — é IP da Terasic/Intel e está disponível no site oficial.

---

## Autor

**Pedro Lucas dos Reis Silva** · RA 2272040
Engenharia da Computação · UTFPR Apucarana
📧 [pedrolucas@alunos.utfpr.edu.br](mailto:pedrolucas@alunos.utfpr.edu.br)
🔗 [github.com/plreis](https://github.com/plreis)
