-- ============================================================================
-- reset_delay.vhd
-- Gera reset ativo-alto com atraso de ~2^20 ciclos de clock (~21 ms a 50 MHz).
-- Equivalente ao reset_delay.v do projeto Verilog original.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_delay is
    port (
        reset_n : in  std_logic;  -- reset externo ativo baixo (iRSTN)
        clk     : in  std_logic;  -- clock 50 MHz (iCLK)
        rst_out : out std_logic   -- reset ativo alto atrasado (oRST)
    );
end entity reset_delay;

architecture rtl of reset_delay is
    signal cont    : unsigned(20 downto 0) := (others => '0');
    signal rst_reg : std_logic := '1';
begin
    rst_out <= rst_reg;

    -- Contador: mantém rst_out='1' até o bit 20 ser atingido (~21 ms)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            cont    <= (others => '0');
            rst_reg <= '1';
        elsif rising_edge(clk) then
            if cont(20) = '0' then
                cont    <= cont + 1;
                rst_reg <= '1';
            else
                rst_reg <= '0';
            end if;
        end if;
    end process;

end architecture rtl;
