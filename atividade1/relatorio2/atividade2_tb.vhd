-- Testbench para atividade2: circuito de controle maquina de copias
-- Testa todas as 16 combinacoes de 4 chaves

entity atividade2_tb is
end entity;

architecture tb of atividade2_tb is
  signal chave1, chave2, chave3, chave4 : bit;
  signal z : bit;
begin

  uut: entity work.atividade2
    port map(
      chave1 => chave1,
      chave2 => chave2,
      chave3 => chave3,
      chave4 => chave4,
      z      => z
    );

  process
  begin
    -- Todas as 16 combinacoes (SW1 SW2 SW3 SW4)
    chave1<='0'; chave2<='0'; chave3<='0'; chave4<='0'; wait for 1 ns; -- 0000 -> 0
    chave1<='0'; chave2<='0'; chave3<='0'; chave4<='1'; wait for 1 ns; -- 0001 -> 0
    chave1<='0'; chave2<='0'; chave3<='1'; chave4<='0'; wait for 1 ns; -- 0010 -> 0
    chave1<='0'; chave2<='0'; chave3<='1'; chave4<='1'; wait for 1 ns; -- 0011 -> 1
    chave1<='0'; chave2<='1'; chave3<='0'; chave4<='0'; wait for 1 ns; -- 0100 -> 0
    chave1<='0'; chave2<='1'; chave3<='0'; chave4<='1'; wait for 1 ns; -- 0101 -> 1
    chave1<='0'; chave2<='1'; chave3<='1'; chave4<='0'; wait for 1 ns; -- 0110 -> 1
    chave1<='0'; chave2<='1'; chave3<='1'; chave4<='1'; wait for 1 ns; -- 0111 -> 1
    chave1<='1'; chave2<='0'; chave3<='0'; chave4<='0'; wait for 1 ns; -- 1000 -> 0
    chave1<='1'; chave2<='0'; chave3<='0'; chave4<='1'; wait for 1 ns; -- 1001 -> X (don't care)
    chave1<='1'; chave2<='0'; chave3<='1'; chave4<='0'; wait for 1 ns; -- 1010 -> 1
    chave1<='1'; chave2<='0'; chave3<='1'; chave4<='1'; wait for 1 ns; -- 1011 -> X (don't care)
    chave1<='1'; chave2<='1'; chave3<='0'; chave4<='0'; wait for 1 ns; -- 1100 -> 1
    chave1<='1'; chave2<='1'; chave3<='0'; chave4<='1'; wait for 1 ns; -- 1101 -> X (don't care)
    chave1<='1'; chave2<='1'; chave3<='1'; chave4<='0'; wait for 1 ns; -- 1110 -> 1
    chave1<='1'; chave2<='1'; chave3<='1'; chave4<='1'; wait for 1 ns; -- 1111 -> X (don't care)
    wait;
  end process;

end architecture;
