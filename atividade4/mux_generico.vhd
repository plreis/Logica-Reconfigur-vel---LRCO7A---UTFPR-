-- ============================================================
-- Multiplexador genérico parametrizável
--
-- Generics:
--   S = bits de seleção  (N entradas, com N = 2^S)
--   M = bits por entrada
--
-- As N entradas vêm empacotadas num único std_logic_vector,
-- com a entrada 0 nos bits menos significativos:
--   entradas( (i+1)*M - 1 downto i*M )  -> entrada I_i
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_generico is
    generic (
        S : positive := 2;
        M : positive := 2
    );
    port (
        entradas : in  std_logic_vector(M*(2**S)-1 downto 0);
        sel      : in  std_logic_vector(S-1 downto 0);
        saida    : out std_logic_vector(M-1 downto 0)
    );
end entity mux_generico;

architecture comportamental of mux_generico is
begin

    -- Para cada bit j da saída, liga ao bit (sel*M + j) do
    -- barramento de entradas. O for...generate cria M atribuições
    -- concorrentes; cada uma sintetiza como um mux N:1 de 1 bit.
    gen_bits : for j in 0 to M-1 generate
        saida(j) <= entradas(to_integer(unsigned(sel)) * M + j);
    end generate;

end architecture comportamental;
