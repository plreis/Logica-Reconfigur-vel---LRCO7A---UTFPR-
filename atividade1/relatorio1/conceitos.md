# Atividade 1 — Portas Lógicas em VHDL

## Objetivo

Implementar as principais portas lógicas combinacionais em VHDL, com duas entradas (A e B) e uma saída independente para cada operação, todas em uma única arquitetura.

---

## Conceitos VHDL

### Entity
Define a **interface externa** do circuito — os pinos visíveis para o mundo externo. É equivalente ao símbolo de um componente num esquemático.

```vhdl
entity atividade1 is
  port (
    a  : in  bit;   -- entrada A
    b  : in  bit;   -- entrada B
    z1 : out bit;   -- NOT a
    z2 : out bit;   -- NOT b
    -- ...
  );
end entity;
```

### Architecture
Define o **comportamento interno** — o que o circuito faz. Nesta atividade foi usada a descrição no estilo **fluxo de dados** (dataflow), onde cada saída é descrita por sua equação booleana diretamente.

```vhdl
architecture atividade1 of atividade1 is
begin
  z1 <= not a;
  z3 <= a and b;
  -- ...
end architecture;
```

### Atribuição de sinal concorrente (`<=`)
Em VHDL, todas as atribuições dentro de `begin...end` executam **em paralelo**, não sequencialmente como em linguagens de software. Isso reflete o comportamento real do hardware: todas as portas operam ao mesmo tempo. Sempre que uma entrada muda, todas as saídas são recalculadas simultaneamente.

### Tipo `bit`
Aceita apenas `'0'` ou `'1'`. Suficiente para descrever lógica digital básica. Em projetos reais utiliza-se `std_logic`, que também representa alta impedância (`'Z'`), valor indefinido (`'X'`), entre outros.

---

## As 8 Portas Lógicas

### NOT (Inversora)
Inverte o valor da entrada. Como há duas entradas, foram criadas duas saídas NOT.

| a | z1 = NOT a |     | b | z2 = NOT b |
|---|:----------:|-----|---|:----------:|
| 0 |     1      |     | 0 |     1      |
| 1 |     0      |     | 1 |     0      |

```vhdl
z1 <= not a;
z2 <= not b;
```

---

### AND
Saída `1` somente quando **ambas** as entradas são `1`.

| a | b | z3 = AND |
|---|---|:--------:|
| 0 | 0 |    0     |
| 0 | 1 |    0     |
| 1 | 0 |    0     |
| 1 | 1 |    1     |

```vhdl
z3 <= a and b;
```

---

### OR
Saída `1` quando **pelo menos uma** entrada é `1`.

| a | b | z4 = OR |
|---|---|:-------:|
| 0 | 0 |    0    |
| 0 | 1 |    1    |
| 1 | 0 |    1    |
| 1 | 1 |    1    |

```vhdl
z4 <= a or b;
```

---

### NAND
Inverso do AND. Saída `0` somente quando **ambas** as entradas são `1`.

| a | b | z5 = NAND |
|---|---|:---------:|
| 0 | 0 |     1     |
| 0 | 1 |     1     |
| 1 | 0 |     1     |
| 1 | 1 |     0     |

```vhdl
z5 <= a nand b;
```

---

### NOR
Inverso do OR. Saída `1` somente quando **ambas** as entradas são `0`.

| a | b | z6 = NOR |
|---|---|:--------:|
| 0 | 0 |    1     |
| 0 | 1 |    0     |
| 1 | 0 |    0     |
| 1 | 1 |    0     |

```vhdl
z6 <= a nor b;
```

---

### XOR (OU Exclusivo)
Saída `1` quando as entradas são **diferentes**.

| a | b | z7 = XOR |
|---|---|:--------:|
| 0 | 0 |    0     |
| 0 | 1 |    1     |
| 1 | 0 |    1     |
| 1 | 1 |    0     |

```vhdl
z7 <= a xor b;
```

---

### XNOR (OU Exclusivo Negado)
Inverso do XOR. Saída `1` quando as entradas são **iguais**.

| a | b | z8 = XNOR |
|---|---|:---------:|
| 0 | 0 |     1     |
| 0 | 1 |     0     |
| 1 | 0 |     0     |
| 1 | 1 |     1     |

```vhdl
z8 <= a xnor b;
```

---

## Código VHDL Completo

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity atividade1 is
  port (
    a    : in  bit;
    b    : in  bit;
    z1   : out bit;   -- NOT a
    z2   : out bit;   -- NOT b
    z3   : out bit;   -- AND
    z4   : out bit;   -- OR
    z5   : out bit;   -- NAND
    z6   : out bit;   -- NOR
    z7   : out bit;   -- XOR
    z8   : out bit    -- XNOR
  );
end entity;

architecture atividade1 of atividade1 is
begin
  z1 <= not a;
  z2 <= not b;
  z3 <= a and b;
  z4 <= a or b;
  z5 <= a nand b;
  z6 <= a nor b;
  z7 <= a xor b;
  z8 <= a xnor b;
end architecture;
```

---

## Forma de Onda Simulada

O testbench aplica as 4 combinações de A e B, cada uma por 1 ns:

| Tempo | a | b | z1 | z2 | z3 | z4 | z5 | z6 | z7 | z8 |
|-------|---|---|----|----|----|----|----|----|----|----|
| 0 ns  | 0 | 0 |  1 |  1 |  0 |  0 |  1 |  1 |  0 |  1 |
| 1 ns  | 0 | 1 |  1 |  0 |  0 |  1 |  1 |  0 |  1 |  0 |
| 2 ns  | 1 | 0 |  0 |  1 |  0 |  1 |  1 |  0 |  1 |  0 |
| 3 ns  | 1 | 1 |  0 |  0 |  1 |  1 |  0 |  0 |  0 |  1 |

---

## Como simular

```bash
cd atividade1/
make sim        # compila + simula + abre GTKWave
make clean      # remove arquivos gerados
```

Para exportar a imagem da simulação: **GTKWave → File → Grab To File → salva como `.png`**

---

## O que o relatório deve conter

1. **Introdução** — conceitos das portas lógicas e descrição VHDL (use este arquivo)
2. **Código VHDL** — comentado (já está comentado no arquivo `.vhd`)
3. **Imagem da simulação** — capturada via GTKWave → File → Grab To File
4. **Diagrama RTL** — gerado no Quartus após síntese (Tools → Netlist Viewers → RTL Viewer)
