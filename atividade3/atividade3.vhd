library ieee;
use ieee.std_logic_1164.all;

entity atividade3 is
    port (
        -- 8 chaves: sw(3 downto 0) para SSD0 e sw(7 downto 4) para SSD1
        sw   : in  std_logic_vector(7 downto 0); -- nois quebra o "vetor" dps 
        -- Saídas genéricas para os displays de 7 segmentos
        -- Formato: (DP g f e d c b a) - 8 bits, DP sempre '1' (desligado)
        SSD0 : out std_logic_vector(7 downto 0);
        SSD1 : out std_logic_vector(7 downto 0)
    );
end entity atividade3;

architecture ssds of atividade3 is
begin

    -- Decodificador BCD para 7 segmentos - SSD0
    -- Chaves sw(3 downto 0) controlam o primeiro display
    -- Segmentos acendem com nível '0' (anodo comum)
    -- Bit 7 = DP (ponto decimal, sempre desligado = '1')
    -- Bits 6..0 = g f e d c b a
    with sw(3 downto 0) select -- relaciona as primeiras chaves com o ssd0
        SSD0 <= "11000000" when "0000", -- 0: acende a,b,c,d,e,f
                "11111001" when "0001", -- 1: acende b,c
                "10100100" when "0010", -- 2: acende a,b,d,e,g
                "10110000" when "0011", -- 3: acende a,b,c,d,g
                "10011001" when "0100", -- 4: acende b,c,f,g
                "10010010" when "0101", -- 5: acende a,c,d,f,g
                "10000010" when "0110", -- 6: acende a,c,d,e,f,g
                "11111000" when "0111", -- 7: acende a,b,c
                "10000000" when "1000", -- 8: acende todos
                "10010000" when "1001", -- 9: acende a,b,c,d,f,g
                "10000110" when others; -- E (erro) para valores > 9

    -- Decodificador BCD para 7 segmentos - SSD1
    -- Chaves sw(7 downto 4) controlam o segundo display
    with sw(7 downto 4) select
        SSD1 <= "11000000" when "0000", -- 0
                "11111001" when "0001", -- 1
                "10100100" when "0010", -- 2
                "10110000" when "0011", -- 3
                "10011001" when "0100", -- 4
                "10010010" when "0101", -- 5
                "10000010" when "0110", -- 6
                "11111000" when "0111", -- 7
                "10000000" when "1000", -- 8
                "10010000" when "1001", -- 9
                "10000110" when others; -- E (erro) para valores > 9

end architecture ssds;