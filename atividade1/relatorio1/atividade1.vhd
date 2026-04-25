-- ============================================================
-- Atividade 1 - Portas Logicas
-- Disciplina: Logica Reconfiguravel - UTFPR Apucarana
-- Descricao: Implementacao de 8 portas logicas com entradas A e B
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
-- ============================================================
entity atividade1 is
  port (
    a    : in  bit;   -- entrada A
    b    : in  bit;   -- entrada B
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
-- ============================================================
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
