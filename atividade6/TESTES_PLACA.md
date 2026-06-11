# Testes de placa - Atividade 6

Mapeamento dos switches:

- `e1 = SW1 SW0`
- `e2 = SW3 SW2`
- `e3 = SW5 SW4`
- `e4 = SW7 SW6`

Mapeamento dos LEDs:

- `saida_min = LEDR1 LEDR0`
- `saida_max = LEDR9 LEDR8`

Na coluna `SW7..SW0`, os pares aparecem na ordem fisica da placa:
`e4 e3 e2 e1`.

| Caso | e1 | e2 | e3 | e4 | SW7..SW0 | min esperado | max esperado | LEDR1..0 | LEDR9..8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Todos zero | 0 (`00`) | 0 (`00`) | 0 (`00`) | 0 (`00`) | `00 00 00 00` | 0 | 0 | `00` | `00` |
| Apenas e1 = 1 | 1 (`01`) | 0 (`00`) | 0 (`00`) | 0 (`00`) | `00 00 00 01` | 0 | 1 | `00` | `01` |
| Crescente | 0 (`00`) | 1 (`01`) | 2 (`10`) | 3 (`11`) | `11 10 01 00` | 0 | 3 | `00` | `11` |
| Decrescente | 3 (`11`) | 2 (`10`) | 1 (`01`) | 0 (`00`) | `00 01 10 11` | 0 | 3 | `00` | `11` |
| Todos iguais a 2 | 2 (`10`) | 2 (`10`) | 2 (`10`) | 2 (`10`) | `10 10 10 10` | 2 | 2 | `10` | `10` |
| Misturado | 3 (`11`) | 0 (`00`) | 2 (`10`) | 1 (`01`) | `01 10 00 11` | 0 | 3 | `00` | `11` |
| Com repeticao | 1 (`01`) | 3 (`11`) | 1 (`01`) | 2 (`10`) | `10 01 11 01` | 1 | 3 | `01` | `11` |
| Minimo repetido | 2 (`10`) | 0 (`00`) | 0 (`00`) | 2 (`10`) | `10 00 00 10` | 0 | 2 | `00` | `10` |

Observacao sobre o VHDL:

O `process` dentro da arquitetura e uma instrucao concorrente. A chamada do
`procedure detector_min_max` fica dentro desse `process`, entao ela e executada
como comando sequencial sempre que algum valor de `x` muda.
