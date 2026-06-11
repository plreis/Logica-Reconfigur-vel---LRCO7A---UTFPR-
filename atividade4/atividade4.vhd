-- ============================================================
-- Atividade 4 - Top-level
--
-- Instancia o multiplexador genérico configurado para
--   S = 2  (=> N = 4 entradas)
--   M = 2  (2 bits por entrada)
--
-- Mapeamento das chaves (DE10-Lite):
--   sw(1 downto 0)  = I0   |  sw(5 downto 4)  = I2
--   sw(3 downto 2)  = I1   |  sw(7 downto 6)  = I3
--   sw(9 downto 8)  = sel  (00,01,10,11 -> seleciona I0..I3)
--
-- Saída visual:
--   HEX0 = saída do mux       |  HEX5 = valor da seleção
--   HEX1..HEX4 = entradas I0..I3
--   LEDR(1..0) = saída do mux em binário
--   LEDR(9..6) = ponteiro one-hot da entrada selecionada
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity atividade4 is
    port (
        sw   : in  std_logic_vector(9 downto 0);
        HEX0 : out std_logic_vector(7 downto 0);
        HEX1 : out std_logic_vector(7 downto 0);
        HEX2 : out std_logic_vector(7 downto 0);
        HEX3 : out std_logic_vector(7 downto 0);
        HEX4 : out std_logic_vector(7 downto 0);
        HEX5 : out std_logic_vector(7 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity atividade4;

architecture rtl of atividade4 is

    -- Decodificador 2 bits -> 7 segmentos (anodo comum, formato
    -- DP g f e d c b a; DP fixo em '1'/apagado).
    function dec_7seg(v : std_logic_vector(1 downto 0))
        return std_logic_vector is
    begin
        case v is
            when "00"   => return "11000000"; -- 0
            when "01"   => return "11111001"; -- 1
            when "10"   => return "10100100"; -- 2
            when "11"   => return "10110000"; -- 3
            when others => return "10000110"; -- E
        end case;
    end function;

    constant S : positive := 2;
    constant M : positive := 2;
    constant N : positive := 2**S;

    signal entradas  : std_logic_vector(M*N - 1 downto 0);
    signal saida_mux : std_logic_vector(M - 1 downto 0);

begin

    entradas <= sw(M*N - 1 downto 0);

    u_mux : entity work.mux_generico
        generic map (
            S => S,
            M => M
        )
        port map (
            entradas => entradas,
            sel      => sw(9 downto 9 - S + 1),
            saida    => saida_mux
        );

    HEX0 <= dec_7seg(saida_mux);          -- saída do mux
    HEX1 <= dec_7seg(sw(1 downto 0));     -- I0
    HEX2 <= dec_7seg(sw(3 downto 2));     -- I1
    HEX3 <= dec_7seg(sw(5 downto 4));     -- I2
    HEX4 <= dec_7seg(sw(7 downto 6));     -- I3
    HEX5 <= dec_7seg(sw(9 downto 8));     -- seleção

    LEDR(1 downto 0) <= saida_mux;
    LEDR(5 downto 2) <= (others => '0');

    with sw(9 downto 8) select
        LEDR(9 downto 6) <= "0001" when "00",   -- aponta I0 (LEDR6)
                            "0010" when "01",   -- aponta I1 (LEDR7)
                            "0100" when "10",   -- aponta I2 (LEDR8)
                            "1000" when "11",   -- aponta I3 (LEDR9)
                            "0000" when others;

end architecture rtl;
