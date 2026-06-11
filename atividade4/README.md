# Atividade 4 — Multiplexador genérico

Implementação em VHDL de um **multiplexador genérico** parametrizável em
número de entradas e em largura de cada entrada, conforme proposto na
Atividade 4 da disciplina de Lógica Reconfigurável (UTFPR Apucarana, 2026/1).
A versão gravada na DE10-Lite é a configuração mínima exigida (4 entradas
de 2 bits) e usa **todos os 6 displays de 7 segmentos** para tornar a
operação do mux completamente visível em tempo real.

## 1. Conceito

Um multiplexador (mux) é um circuito combinacional que escolhe **uma**
entre N entradas e a encaminha para a saída, segundo um sinal de
seleção. O número de bits de seleção S e o número de entradas N estão
relacionados por

```
N = 2^S
```

Generalizando ainda mais, cada entrada pode ter M bits — o mux
seleciona um *vetor* de M bits e o repete na saída.

| S (bits sel.) | N (entradas) | M (bits/entrada) | tamanho do barramento de entradas |
|---|---|---|---|
| 1 | 2  | qualquer | 2·M |
| 2 | 4  | qualquer | 4·M |
| 3 | 8  | qualquer | 8·M |
| 4 | 16 | qualquer | 16·M |

A construção em VHDL é feita com a estrutura `generic`, que permite
parametrizar a entidade no momento da instanciação. Isso evita ter que
reescrever o código para cada combinação de S e M.

## 2. Estrutura do projeto

```
atividade4/
├── mux_generico.vhd      <- entidade parametrizável (S, M), só código concorrente
├── atividade4.vhd        <- top-level: instancia o mux 4x2 e os displays
├── mux_generico_tb.vhd   <- testbench: simulação com 16 entradas de 8 bits
├── mux_simulador.html    <- simulador didático interativo (abrir no navegador)
├── atividade4.qpf        <- arquivo de projeto Quartus
├── atividade4.qsf        <- pin planner para a DE10-Lite
└── README.md             <- este arquivo
```

> **Estilo de código:** todos os arquivos VHDL desta atividade usam
> exclusivamente **código concorrente** (atribuições com `<=`,
> `with ... select`, `when ... else` e `for ... generate`). Nenhum
> `process`, `if` ou `case` sequencial é utilizado, em linha com o
> conteúdo visto até a Aula 9 da disciplina.

### 2.1 `mux_generico.vhd`

Entidade do mux propriamente dito. Possui dois `generic`:

- `S` — número de bits de seleção (entradas: `N = 2^S`)
- `M` — número de bits por entrada

As `N` entradas vêm empacotadas em um único `std_logic_vector` de
`N·M` bits, com a entrada 0 nos bits menos significativos:

```
entradas( M-1     downto 0       )  -> entrada 0
entradas( 2*M-1   downto M       )  -> entrada 1
                ...
entradas( N*M-1   downto (N-1)*M )  -> entrada N-1
```

A arquitetura é **puramente concorrente** (sem `process`), usando
apenas estruturas vistas em aula: `generic` e `for ... generate`.
Para cada bit `j` da saída (de `0` a `M-1`), o `generate` cria uma
atribuição que liga `saida(j)` ao bit correspondente da fatia
selecionada do barramento de entradas — o índice no barramento é
`sel*M + j`. Cada iteração do `generate` "gera" um mux N:1 de 1 bit,
totalizando M muxes em paralelo.

```vhdl
gen_bits : for j in 0 to M-1 generate
    saida(j) <= entradas(to_integer(unsigned(sel)) * M + j);
end generate;
```

Exemplo (S=2, M=2): se `sel = 1` (selecionou I1), na iteração j=0
fica `saida(0) <= entradas(2)` e na j=1 fica `saida(1) <= entradas(3)`
— exatamente os bits `entradas(3 downto 2)` que correspondem a I1.

### 2.2 `atividade4.vhd` — top-level

Instancia `mux_generico` com `S=2` e `M=2` (4 entradas de 2 bits) e
encaminha cada chave/sinal para os displays de 7 segmentos. A função
`dec_7seg` é o decodificador 2 bits → 7 segmentos (anodo comum,
formato `(DP g f e d c b a)`, mesma convenção da Atividade 3).

O LED-ponteiro one-hot (`LEDR(9..6)`) é gerado por uma atribuição
concorrente `with ... select` — sem `process`:

```vhdl
with sw(9 downto 8) select
    LEDR(9 downto 6) <= "0001" when "00",   -- aponta I0 (LEDR6)
                        "0010" when "01",   -- aponta I1 (LEDR7)
                        "0100" when "10",   -- aponta I2 (LEDR8)
                        "1000" when "11",   -- aponta I3 (LEDR9)
                        "0000" when others;
```

### 2.3 `mux_generico_tb.vhd` — testbench (S=4, M=8)

Atende ao item *"Faça uma simulação com um número alto de entradas e
de bits de cada entrada (sugestão: 16 entradas de 8 bits cada)"*.

Cada entrada `Ii` é inicializada com o valor `0xA0 + i`, gerado por
um `for ... generate`. Em seguida o processo de estímulo varre as 16
seleções (0 a 15), trocando o valor a cada 20 ns. No waveform basta
configurar os sinais `entradas` e `saida` em hexadecimal:

| `sel` | `saida` esperada |
|:---:|:---:|
| 0 | A0 |
| 1 | A1 |
| 2 | A2 |
| 3 | A3 |
| 4 | A4 |
| 5 | A5 |
| 6 | A6 |
| 7 | A7 |
| 8 | A8 |
| 9 | A9 |
| A | AA |
| B | AB |
| C | AC |
| D | AD |
| E | AE |
| F | AF |

## 3. Mapeamento na DE10-Lite (versão 4×2 gravada na placa)

### Chaves (entradas)

| Switch | Função |
|---|---|
| `sw[1..0]` | entrada **I0** (2 bits) |
| `sw[3..2]` | entrada **I1** (2 bits) |
| `sw[5..4]` | entrada **I2** (2 bits) |
| `sw[7..6]` | entrada **I3** (2 bits) |
| `sw[9..8]` | **seleção** (00→I0, 01→I1, 10→I2, 11→I3) |

### Displays (saídas — feature visual)

Os 6 displays de 7 segmentos foram organizados de forma que o usuário
veja, em paralelo, todas as entradas, a seleção e a saída do mux.
Mexer numa chave de uma entrada não selecionada não muda HEX0; mover
`sw[9..8]` faz HEX0 saltar para o valor mostrado no display
correspondente.

```
 ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
 │HEX5 │  │HEX4 │  │HEX3 │  │HEX2 │  │HEX1 │  │HEX0 │
 │ sel │  │ I3  │  │ I2  │  │ I1  │  │ I0  │  │OUT  │
 └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘
   ↑         └────────┬────────────────┘         ↑
   │             entradas                        │
   └─────── seleciona ──────────────────────────┘
```

### LEDs

| LEDs | Função |
|---|---|
| `LEDR[1..0]` | saída do mux em binário |
| `LEDR[6]` | aceso quando `sel = 00` (I0 está sendo roteada) |
| `LEDR[7]` | aceso quando `sel = 01` (I1) |
| `LEDR[8]` | aceso quando `sel = 10` (I2) |
| `LEDR[9]` | aceso quando `sel = 11` (I3) |

Os LEDs `LEDR[9..6]` formam um "ponteiro" one-hot indicando qual
entrada está conectada à saída.

## 4. Como compilar e gravar

1. Abrir o Quartus Prime Lite e abrir `atividade4.qpf`.
2. *Processing → Start Compilation* (ou Ctrl+L).
3. *Tools → Programmer*, selecionar o `.sof` em `output_files/` e
   clicar **Start** com a DE10-Lite conectada.
4. Após a gravação:
   - Configurar `sw[1..0]`, `sw[3..2]`, `sw[5..4]`, `sw[7..6]` com
     valores diferentes (ex.: `01`, `10`, `11`, `01`).
   - Variar `sw[9..8]` e observar HEX0 e o LED-ponteiro acompanharem
     a entrada selecionada.

## 5. Como rodar a simulação

1. *Assignments → Settings → EDA Tool Settings → Simulation*: garantir
   que a ferramenta seja a Questa (já configurada no `.qsf`).
2. *Tools → Run Simulation Tool → RTL Simulation*.
3. No Questa, definir o radix dos sinais `entradas` e `saida` como
   **Hexadecimal** e dar `run -all` (ou `run 400 ns`).
4. Verificar que o valor de `saida` segue a tabela da Seção 2.3.

## 6. Diagrama RTL

Para gerar a imagem do RTL (item exigido no relatório):

1. Compilar o projeto (Ctrl+L).
2. *Tools → Netlist Viewers → RTL Viewer*.
3. *File → Export* para salvar como PDF/PNG.

## 7. Resumo dos itens entregáveis

- [x] Estrutura `generic` (S e M), com N derivado de `2^S`.
- [x] Versão de 4 entradas de 2 bits implementada na placa, com
      entradas nas chaves e saída em LEDs **e** displays de 7 segmentos.
- [x] Testbench com 16 entradas de 8 bits (apresentação em hexadecimal).
- [ ] Imagem da simulação no waveform (gerar após rodar o testbench).
- [ ] Foto do mux na placa (gerar após gravar).
- [ ] Diagrama RTL exportado (gerar após compilação).
