-- ============================================================
-- Atividade 2 - Exercicio 2: Circuito de controle maquina de copias
-- Disciplina: Logica Reconfiguravel - UTFPR Apucarana
-- Descricao: Saida HIGH quando 2 ou mais chaves estao fechadas.
--            SW1 e SW4 nunca fecham ao mesmo tempo (don't care).
--
-- Equacao obtida pelo mapa de Karnaugh:
-- z = SW1.SW2 + SW1.SW3 + SW2.SW3 + SW2.SW4 + SW3.SW4
--
-- Pin Planner (DE10-Lite):
--   chave1 = SW0 -> PIN_C10 (3.3V LVTTL)
--   chave2 = SW1 -> PIN_C11 (3.3V LVTTL)
--   chave3 = SW2 -> PIN_D12 (3.3V LVTTL)
--   chave4 = SW3 -> PIN_C12 (3.3V LVTTL)
--   z      = LEDR0 -> PIN_A8 (3.3V LVTTL)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
-- ============================================================
entity atividade2 is
  port (
    chave1 : in  bit;  -- SW0: chave 1
    chave2 : in  bit;  -- SW1: chave 2
    chave3 : in  bit;  -- SW2: chave 3
    chave4 : in  bit;  -- SW3: chave 4
    z      : out bit   -- LEDR0: saida (HIGH quando 2+ chaves fechadas)
  );
end entity;
-- ============================================================
architecture dataflow of atividade2 is
begin
  -- Equacao simplificada via Karnaugh (todas as combinacoes de 2 chaves,
  -- exceto SW1.SW4 que e don't care pois nunca ocorre)
  z <= (chave1 and chave2) or
       (chave1 and chave3) or
       (chave2 and chave3) or
       (chave2 and chave4) or
       (chave3 and chave4);
end architecture;
