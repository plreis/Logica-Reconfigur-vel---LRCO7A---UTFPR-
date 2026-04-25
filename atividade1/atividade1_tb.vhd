-- Testbench para atividade1: todas as portas logicas
-- Aplica as 4 combinacoes possiveis de A e B

entity atividade1_tb is
end entity;

architecture tb of atividade1_tb is
  signal a                          : bit;
  signal b                          : bit;
  signal z1, z2, z3, z4, z5, z6, z7, z8 : bit;
begin

  -- Instancia o componente a ser testado (DUT)
  uut: entity work.atividade1
    port map(
      a  => a,
      b  => b,
      z1 => z1,  -- NOT a
      z2 => z2,  -- NOT b
      z3 => z3,  -- AND
      z4 => z4,  -- OR
      z5 => z5,  -- NAND
      z6 => z6,  -- NOR
      z7 => z7,  -- XOR
      z8 => z8   -- XNOR
    );

  -- Processo de estimulo: testa todas as combinacoes de entrada
  process
  begin
    a <= '0'; b <= '0'; wait for 1 ns;  -- combinacao 00
    a <= '0'; b <= '1'; wait for 1 ns;  -- combinacao 01
    a <= '1'; b <= '0'; wait for 1 ns;  -- combinacao 10
    a <= '1'; b <= '1'; wait for 1 ns;  -- combinacao 11
    wait;
  end process;

end architecture;
