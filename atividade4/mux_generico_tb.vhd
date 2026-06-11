-- ============================================================
-- Testbench do multiplexador genérico
--
-- Instancia o mux com S=4, M=8 (16 entradas de 8 bits).
-- Cada entrada I_i recebe o valor 0xA0 + i, de modo que a
-- saída em hex deve ser A0, A1, ..., AF conforme sel varre
-- de 0 a 15. (No simulador, configurar entradas e saida em
-- radix hexadecimal.)
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_generico_tb is
end entity mux_generico_tb;

architecture sim of mux_generico_tb is

    constant S : positive := 4;
    constant M : positive := 8;
    constant N : positive := 2**S;

    signal entradas : std_logic_vector(M*N - 1 downto 0);
    signal sel      : std_logic_vector(S - 1 downto 0);
    signal saida    : std_logic_vector(M - 1 downto 0);

begin

    DUT : entity work.mux_generico
        generic map (
            S => S,
            M => M
        )
        port map (
            entradas => entradas,
            sel      => sel,
            saida    => saida
        );

    gen_entradas : for i in 0 to N-1 generate
        entradas((i+1)*M - 1 downto i*M)
            <= std_logic_vector(to_unsigned(16#A0# + i, M));
    end generate;

    estimulo : process
    begin
        for i in 0 to N-1 loop
            sel <= std_logic_vector(to_unsigned(i, S));
            wait for 20 ns;
        end loop;
        wait;
    end process;

end architecture sim;
