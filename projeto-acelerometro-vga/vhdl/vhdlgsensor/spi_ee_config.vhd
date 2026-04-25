-- ============================================================================
-- spi_ee_config.vhd
-- Gerenciador de configuração e leitura do acelerômetro ADXL345 via SPI.
-- Realiza sequência de inicialização (11 escritas) e leittura contínua do
-- eixo X (dois bytes). Equivalente ao spi_ee_config.v do projeto Verilog.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spi_param_pkg.all;

entity spi_ee_config is
    port (
        reset_n     : in    std_logic;                    -- iRSTN (ativo baixo)
        spi_clk     : in    std_logic;                    -- iSPI_CLK   (2 MHz)
        spi_clk_out : in    std_logic;                    -- iSPI_CLK_OUT (defasado)
        g_int2      : in    std_logic;                    -- iG_INT2 (interrupção do sensor)
        data_l      : out   std_logic_vector(7 downto 0); -- oDATA_L byte baixo eixo X
        data_h      : out   std_logic_vector(7 downto 0); -- oDATA_H byte alto  eixo X
        spi_sdio    : inout std_logic;                    -- SPI_SDIO bidirecional
        spi_csn     : out   std_logic;                    -- oSPI_CSN chip select
        spi_clk_o   : out   std_logic                     -- oSPI_CLK clock SPI
    );
end entity spi_ee_config;

architecture rtl of spi_ee_config is

    -- -----------------------------------------------------------------------
    -- Componente: controlador SPI de baixo nível
    -- -----------------------------------------------------------------------
    component spi_controller is
        port (
            reset_n     : in    std_logic;
            spi_clk     : in    std_logic;
            spi_clk_out : in    std_logic;
            p2s_data    : in    std_logic_vector(15 downto 0);
            spi_go      : in    std_logic;
            spi_end     : out   std_logic;
            s2p_data    : out   std_logic_vector(7 downto 0);
            spi_sdio    : inout std_logic;
            spi_csn     : out   std_logic;
            spi_clk_o   : out   std_logic
        );
    end component;

    -- -----------------------------------------------------------------------
    -- Sinais internos
    -- -----------------------------------------------------------------------
    signal ini_index       : unsigned(3 downto 0)          := (others => '0');
    signal write_data      : std_logic_vector(13 downto 0) := (others => '0'); -- [13:8]=addr, [7:0]=dado
    signal p2s_data        : std_logic_vector(15 downto 0) := (others => '0');
    signal spi_go_sig      : std_logic                     := '0';
    signal spi_end_sig     : std_logic;
    signal s2p_data_sig    : std_logic_vector(7 downto 0);

    signal low_byte_data   : std_logic_vector(7 downto 0)  := (others => '0');
    signal spi_state       : std_logic                     := SPI_IDLE;

    signal high_byte       : std_logic := '0'; -- indica leitura do byte alto
    signal read_back       : std_logic := '0'; -- indica que é uma leitura de dados
    signal clear_status    : std_logic := '0';
    signal read_ready      : std_logic := '0';

    signal clear_status_d  : std_logic_vector(3 downto 0)  := (others => '0');
    signal high_byte_d     : std_logic := '0';
    signal read_back_d     : std_logic := '0';
    signal read_idle_count : unsigned(14 downto 0)         := (others => '0'); -- IDLE_MSB=14

    signal data_l_reg      : std_logic_vector(7 downto 0)  := (others => '0');
    signal data_h_reg      : std_logic_vector(7 downto 0)  := (others => '0');

begin

    data_l <= data_l_reg;
    data_h <= data_h_reg;

    -- -----------------------------------------------------------------------
    -- Instância do controlador SPI
    -- -----------------------------------------------------------------------
    u_spi_controller : spi_controller
        port map (
            reset_n     => reset_n,
            spi_clk     => spi_clk,
            spi_clk_out => spi_clk_out,
            p2s_data    => p2s_data,
            spi_go      => spi_go_sig,
            spi_end     => spi_end_sig,
            s2p_data    => s2p_data_sig,
            spi_sdio    => spi_sdio,
            spi_csn     => spi_csn,
            spi_clk_o   => spi_clk_o
        );

    -- -----------------------------------------------------------------------
    -- Tabela de inicialização (combinatorial, equivalente ao always@(ini_index))
    -- write_data[13:8] = endereço (6 bits), write_data[7:0] = valor
    -- -----------------------------------------------------------------------
    process(ini_index)
    begin
        case to_integer(ini_index) is
            when 0  => write_data <= THRESH_ACT      & x"20";
            when 1  => write_data <= THRESH_INACT    & x"03";
            when 2  => write_data <= TIME_INACT      & x"01";
            when 3  => write_data <= ACT_INACT_CTL   & x"7F";
            when 4  => write_data <= THRESH_FF       & x"09";
            when 5  => write_data <= TIME_FF         & x"46";
            when 6  => write_data <= BW_RATE         & x"09"; -- ODR: 50 Hz
            when 7  => write_data <= INT_ENABLE      & x"10";
            when 8  => write_data <= INT_MAP         & x"10";
            when 9  => write_data <= DATA_FORMAT     & x"40";
            when others => write_data <= POWER_CONTROL & x"08";
        end case;
    end process;

    -- -----------------------------------------------------------------------
    -- FSM principal: inicialização (escrita) + leitura contínua eixo X
    -- -----------------------------------------------------------------------
    process(spi_clk, reset_n)
    begin
        if reset_n = '0' then
            ini_index       <= (others => '0');
            spi_go_sig      <= '0';
            spi_state       <= SPI_IDLE;
            read_idle_count <= (others => '0');
            high_byte       <= '0';
            read_back       <= '0';
            clear_status    <= '0';
            read_ready      <= '0';
            p2s_data        <= (others => '0');
            low_byte_data   <= (others => '0');
            data_l_reg      <= (others => '0');
            data_h_reg      <= (others => '0');

        elsif rising_edge(spi_clk) then

            -- ==============================================================
            -- Fase de inicialização: envia 11 configurações (modo escrita)
            -- ==============================================================
            if ini_index < INI_NUMBER then
                case spi_state is
                    when SPI_IDLE =>
                        -- Monta palavra: SPI_WRITE (2b) + endereço (6b) + dado (8b)
                        p2s_data  <= SPI_WRITE & write_data;
                        spi_go_sig <= '1';
                        spi_state  <= SPI_TRANSFER;

                    when others => -- SPI_TRANSFER
                        if spi_end_sig = '1' then
                            ini_index  <= ini_index + 1;
                            spi_go_sig <= '0';
                            spi_state  <= SPI_IDLE;
                        end if;
                end case;

            -- ==============================================================
            -- Fase de leitura contínua: eixo X (byte baixo + byte alto)
            -- ==============================================================
            else
                case spi_state is
                    when SPI_IDLE =>
                        read_idle_count <= read_idle_count + 1;

                        -- Determina qual transação iniciar
                        if high_byte = '1' then
                            -- Leitura do byte alto X
                            p2s_data(15 downto 8) <= SPI_READ & X_HB;
                            read_back <= '1';
                        elsif read_ready = '1' then
                            -- Leitura do byte baixo X
                            p2s_data(15 downto 8) <= SPI_READ & X_LB;
                            read_back <= '1';
                        elsif (clear_status_d(3) = '0' and g_int2 = '1')
                              or read_idle_count(IDLE_MSB) = '1' then
                            -- Leitura do registrador de status de interrupção
                            p2s_data(15 downto 8) <= SPI_READ & INT_SOURCE;
                            clear_status <= '1';
                        end if;

                        -- Inicia transferência se alguma condição foi atendida
                        if high_byte = '1' or read_ready = '1'
                           or read_idle_count(IDLE_MSB) = '1'
                           or (clear_status_d(3) = '0' and g_int2 = '1') then
                            spi_go_sig <= '1';
                            spi_state  <= SPI_TRANSFER;
                        end if;

                        -- Atualiza dados lidos no ciclo IDLE seguinte à leitura
                        if read_back_d = '1' then
                            if high_byte_d = '1' then
                                -- Byte alto chegou: atualiza saídas
                                data_h_reg    <= s2p_data_sig;
                                data_l_reg    <= low_byte_data;
                            else
                                -- Byte baixo: guarda temporariamente
                                low_byte_data <= s2p_data_sig;
                            end if;
                        end if;

                    when others => -- SPI_TRANSFER
                        if spi_end_sig = '1' then
                            spi_go_sig <= '0';
                            spi_state  <= SPI_IDLE;

                            if read_back = '1' then
                                -- Leitura de dado: alterna entre byte baixo e alto
                                read_back  <= '0';
                                high_byte  <= not high_byte;
                                read_ready <= '0';
                            else
                                -- Leitura de status: verifica bit de dado pronto (bit 6)
                                clear_status    <= '0';
                                read_ready      <= s2p_data_sig(6);
                                read_idle_count <= (others => '0');
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- -----------------------------------------------------------------------
    -- Registros de atraso para sincronização de sinais de controle
    -- (equivalente ao segundo always@(posedge iSPI_CLK) do Verilog)
    -- -----------------------------------------------------------------------
    process(spi_clk, reset_n)
    begin
        if reset_n = '0' then
            high_byte_d    <= '0';
            read_back_d    <= '0';
            clear_status_d <= (others => '0');
        elsif rising_edge(spi_clk) then
            high_byte_d    <= high_byte;
            read_back_d    <= read_back;
            -- Shift register de 4 estágios para clear_status
            clear_status_d <= clear_status_d(2 downto 0) & clear_status;
        end if;
    end process;

end architecture rtl;
