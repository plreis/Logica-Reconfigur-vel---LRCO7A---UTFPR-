-- ============================================================================
-- spi_controller.vhd
-- Controlador SPI de 16 bits para o acelerômetro ADXL345.
-- Transmite (P2S) e recebe (S2P) dados com barra bidirecional tristate (SDIO).
-- Equivalente ao spi_controller.v do projeto Verilog original.
--
-- Protocolo:
--   - Palavra de 16 bits: [15] = R/W, [14:8] = endereço (7 bits), [7:0] = dados
--   - spi_count: contador regressivo de 15 a 0 (15 clocks por transação)
--   - write_addr (spi_count[3]='1'): fase de endereço — SDIO sempre dirigida pelo mestre
--   - Fase de dados em leitura (read_mode='1', write_addr='0'): SDIO é entrada (tristate)
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller is
    port (
        reset_n     : in    std_logic;                     -- iRSTN (ativo baixo)
        spi_clk     : in    std_logic;                     -- iSPI_CLK  (2 MHz)
        spi_clk_out : in    std_logic;                     -- iSPI_CLK_OUT (2 MHz defasado)
        p2s_data    : in    std_logic_vector(15 downto 0); -- iP2S_DATA (dado paralelo → serial)
        spi_go      : in    std_logic;                     -- iSPI_GO   (inicia transferência)
        spi_end     : out   std_logic;                     -- oSPI_END  (transferência concluída)
        s2p_data    : out   std_logic_vector(7 downto 0);  -- oS2P_DATA (dado serial → paralelo)
        spi_sdio    : inout std_logic;                     -- SPI_SDIO  (bidirecional tristate)
        spi_csn     : out   std_logic;                     -- oSPI_CSN  (chip select ativo baixo)
        spi_clk_o   : out   std_logic                      -- oSPI_CLK  (clock SPI para o sensor)
    );
end entity spi_controller;

architecture rtl of spi_controller is

    signal spi_count_en : std_logic                    := '0';
    signal spi_count    : unsigned(3 downto 0)         := x"F";
    signal read_mode    : std_logic;
    signal write_addr   : std_logic;
    signal s2p_reg      : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Sinais derivados combinatoriais
    read_mode  <= p2s_data(15);          -- bit 15 = '1' → modo leitura
    write_addr <= spi_count(3);          -- bits 15:8 são endereço (spi_count >= 8)

    -- Transação encerrada quando contador chega a zero
    spi_end   <= '1' when spi_count = x"0" else '0';

    -- Chip select ativo enquanto spi_go = '1'
    spi_csn   <= not spi_go;

    -- Saída do clock SPI: usa o clock defasado somente enquanto habilitado
    spi_clk_o <= spi_clk_out when spi_count_en = '1' else '1';

    -- Linha bidirecional SDIO: mestre dirige durante endereço ou modo escrita;
    -- coloca em alta impedância durante fase de dados em modo leitura
    spi_sdio <= p2s_data(to_integer(spi_count))
                when (spi_count_en = '1' and (read_mode = '0' or write_addr = '1'))
                else 'Z';

    s2p_data <= s2p_reg;

    -- Processo síncrono: controle do contador e shift de recepção
    process(spi_clk, reset_n)
    begin
        if reset_n = '0' then
            spi_count_en <= '0';
            spi_count    <= x"F";
            s2p_reg      <= (others => '0');
        elsif rising_edge(spi_clk) then

            -- Controle do enable: desliga ao final, liga ao início (spi_go)
            if spi_count = x"0" then
                spi_count_en <= '0';
            elsif spi_go = '1' then
                spi_count_en <= '1';
            end if;

            -- Contador regressivo: recarrega em 15 quando desabilitado
            if spi_count_en = '0' then
                spi_count <= x"F";
            else
                spi_count <= spi_count - 1;
            end if;

            -- Recepção série → paralelo: somente em modo leitura na fase de dados
            if read_mode = '1' and write_addr = '0' then
                s2p_reg <= s2p_reg(6 downto 0) & spi_sdio;
            end if;

        end if;
    end process;

end architecture rtl;
