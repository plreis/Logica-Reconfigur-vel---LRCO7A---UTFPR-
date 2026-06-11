library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.meupacote.all; -- Importando o pacote

entity atividade6 is
    generic (
        NUM_INPUTS : integer := 4; -- Quantidade genérica de valores
        NUM_BITS   : integer := 2  -- Quantidade genérica de bits (2 p/ caber nos 10 SW da DE10-Lite)
    );
    port (
        -- Interface em std_logic_vector para compatibilidade com o testbench VWF
        e1, e2, e3, e4 : in  std_logic_vector(NUM_BITS-1 downto 0);
        -- Saídas de valor mínimo e máximo
        saida_min      : out std_logic_vector(NUM_BITS-1 downto 0);
        saida_max      : out std_logic_vector(NUM_BITS-1 downto 0)
    );
end entity;

architecture comportamento of atividade6 is
    -- Sinal interno utilizando o tipo definido no package
    signal x : int_array(0 to NUM_INPUTS-1);
    signal m_val, M_val_int : integer;
begin
    -- Mapeamento das portas std_logic_vector para o vetor de inteiros
    x(0) <= to_integer(unsigned(e1));
    x(1) <= to_integer(unsigned(e2));
    x(2) <= to_integer(unsigned(e3));
    x(3) <= to_integer(unsigned(e4));

    -- O process e uma instrucao concorrente da arquitetura.
    -- Dentro dele, a chamada do procedure e sequencial e recalcula min/max quando x muda.
    process(x)
    begin
        detector_min_max(x, m_val, M_val_int);
    end process;

    -- Converte os inteiros para std_logic_vector nas saídas
    saida_min <= std_logic_vector(to_unsigned(m_val, NUM_BITS));
    saida_max <= std_logic_vector(to_unsigned(M_val_int, NUM_BITS));

end architecture;
