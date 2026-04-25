-- ============================================================================
-- DE10_LITE_GSensor_VGA.vhd
-- Top-level do projeto combinado: Acelerômetro + VGA para DE10-Lite.
--
-- Funcionalidade:
--   - Lê eixo X do acelerômetro ADXL345 via SPI
--   - Exibe barra vertical branca no VGA cuja posição reflete a inclinação
--   - LEDs mantêm o comportamento original do projeto GSensor
--
-- Mapeamento de posição:
--   raw = 0    → cursor na coluna 320 (centro, placa nivelada)
--   raw = +511 → cursor na coluna 639 (extremo direito)
--   raw = -512 → cursor na coluna 0   (extremo esquerdo)
--   Fórmula: cursor_x = clamp(320 + (raw × 5) >> 3, 0, 639)
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_LITE_GSensor_VGA is
    port (
        -- CLOCK
        adc_clk_10    : in    std_logic;
        max10_clk1_50 : in    std_logic;
        max10_clk2_50 : in    std_logic;

        -- SDRAM (não utilizado, tied off)
        dram_addr  : out   std_logic_vector(12 downto 0);
        dram_ba    : out   std_logic_vector(1 downto 0);
        dram_cas_n : out   std_logic;
        dram_cke   : out   std_logic;
        dram_clk   : out   std_logic;
        dram_cs_n  : out   std_logic;
        dram_dq    : inout std_logic_vector(15 downto 0);
        dram_ldqm  : out   std_logic;
        dram_ras_n : out   std_logic;
        dram_udqm  : out   std_logic;
        dram_we_n  : out   std_logic;

        -- KEY
        key : in std_logic_vector(1 downto 0);

        -- LED
        ledr : out std_logic_vector(9 downto 0);

        -- SW
        sw : in std_logic_vector(9 downto 0);

        -- VGA
        vga_b  : out std_logic_vector(3 downto 0);
        vga_g  : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_r  : out std_logic_vector(3 downto 0);
        vga_vs : out std_logic;

        -- Acelerômetro
        gsensor_cs_n : out   std_logic;
        gsensor_int  : in    std_logic_vector(2 downto 1);
        gsensor_sclk : out   std_logic;
        gsensor_sdi  : inout std_logic;
        gsensor_sdo  : inout std_logic;

        -- Arduino (não utilizado)
        arduino_io    : inout std_logic_vector(15 downto 0);
        arduino_rst_n : inout std_logic
    );
end entity DE10_LITE_GSensor_VGA;

architecture structural of DE10_LITE_GSensor_VGA is

    -- -----------------------------------------------------------------------
    -- Componentes
    -- -----------------------------------------------------------------------
    component reset_delay is
        port (
            reset_n : in  std_logic;
            clk     : in  std_logic;
            rst_out : out std_logic
        );
    end component;

    component spi_pll is
        port (
            areset : in  std_logic;
            inclk0 : in  std_logic;
            c0     : out std_logic;
            c1     : out std_logic
        );
    end component;

    component spi_ee_config is
        port (
            reset_n     : in    std_logic;
            spi_clk     : in    std_logic;
            spi_clk_out : in    std_logic;
            g_int2      : in    std_logic;
            data_l      : out   std_logic_vector(7 downto 0);
            data_h      : out   std_logic_vector(7 downto 0);
            spi_sdio    : inout std_logic;
            spi_csn     : out   std_logic;
            spi_clk_o   : out   std_logic
        );
    end component;

    component led_driver is
        port (
            reset_n : in  std_logic;
            clk     : in  std_logic;
            dig     : in  std_logic_vector(9 downto 0);
            g_int2  : in  std_logic;
            led     : out std_logic_vector(9 downto 0)
        );
    end component;

    component vga_pll is
        port (
            areset : in  std_logic;
            inclk0 : in  std_logic;
            c0     : out std_logic;
            locked : out std_logic
        );
    end component;

    component vga_controller is
        port (
            reset_n  : in  std_logic;
            vga_clk  : in  std_logic;
            cursor_x : in  std_logic_vector(9 downto 0);
            blank_n  : out std_logic;
            hs       : out std_logic;
            vs       : out std_logic;
            vga_b    : out std_logic_vector(3 downto 0);
            vga_g    : out std_logic_vector(3 downto 0);
            vga_r    : out std_logic_vector(3 downto 0)
        );
    end component;

    -- -----------------------------------------------------------------------
    -- Sinais internos
    -- -----------------------------------------------------------------------
    signal dly_rst      : std_logic;
    signal spi_clk      : std_logic;
    signal spi_clk_out  : std_logic;
    signal data_x       : std_logic_vector(15 downto 0);
    signal vga_ctrl_clk : std_logic;

    -- CDC: sincronizador dois estágios (domínio SPI → domínio VGA)
    signal accel_sync1  : std_logic_vector(9 downto 0) := (others => '0');
    signal accel_sync2  : std_logic_vector(9 downto 0) := (others => '0');

    -- Cálculo da posição do cursor
    signal raw_signed   : signed(10 downto 0);
    signal scaled       : signed(14 downto 0);
    signal offset       : signed(10 downto 0);
    signal cursor_x_pre : signed(10 downto 0);
    signal cursor_x_clamp : std_logic_vector(9 downto 0);
    signal cursor_x_reg   : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(320, 10));

    signal vga_blank_n  : std_logic; -- saída blank_n (não conectada ao top)

begin

    -- SDRAM: desabilitado
    dram_addr  <= (others => '0');
    dram_ba    <= (others => '0');
    dram_cas_n <= '1';
    dram_cke   <= '0';
    dram_clk   <= '0';
    dram_cs_n  <= '1';
    dram_dq    <= (others => 'Z');
    dram_ldqm  <= '1';
    dram_ras_n <= '1';
    dram_udqm  <= '1';
    dram_we_n  <= '1';

    -- -----------------------------------------------------------------------
    -- Subsistema GSensor
    -- -----------------------------------------------------------------------
    u_reset_delay : reset_delay
        port map (
            reset_n => key(0),
            clk     => max10_clk1_50,
            rst_out => dly_rst
        );

    u_spi_pll : spi_pll
        port map (
            areset => dly_rst,
            inclk0 => max10_clk1_50,
            c0     => spi_clk,
            c1     => spi_clk_out
        );

    u_spi_ee_config : spi_ee_config
        port map (
            reset_n     => not dly_rst,
            spi_clk     => spi_clk,
            spi_clk_out => spi_clk_out,
            g_int2      => gsensor_int(1),
            data_l      => data_x(7 downto 0),
            data_h      => data_x(15 downto 8),
            spi_sdio    => gsensor_sdi,
            spi_csn     => gsensor_cs_n,
            spi_clk_o   => gsensor_sclk
        );

    u_led_driver : led_driver
        port map (
            reset_n => not dly_rst,
            clk     => max10_clk1_50,
            dig     => data_x(9 downto 0),
            g_int2  => gsensor_int(1),
            led     => ledr
        );

    -- -----------------------------------------------------------------------
    -- PLL VGA
    -- -----------------------------------------------------------------------
    u_vga_pll : vga_pll
        port map (
            areset => dly_rst,
            inclk0 => max10_clk1_50,
            c0     => vga_ctrl_clk,
            locked => open
        );

    -- -----------------------------------------------------------------------
    -- CDC: sincroniza dado do acelerômetro para o domínio VGA (2 flip-flops)
    -- -----------------------------------------------------------------------
    process(vga_ctrl_clk, dly_rst)
    begin
        if dly_rst = '1' then
            accel_sync1 <= (others => '0');
            accel_sync2 <= (others => '0');
        elsif rising_edge(vga_ctrl_clk) then
            accel_sync1 <= data_x(9 downto 0);
            accel_sync2 <= accel_sync1;
        end if;
    end process;

    -- -----------------------------------------------------------------------
    -- Mapeamento: aceleração signed 10-bit → coluna VGA 0..639
    --   cursor_x = 320 + (raw × 5) >> 3
    -- -----------------------------------------------------------------------
    raw_signed   <= signed(accel_sync2(9) & accel_sync2);   -- extensão de sinal 10→11 bits
    scaled       <= raw_signed * to_signed(5, 4);            -- ×5, resultado 15 bits (11+4)
    offset       <= scaled(13 downto 3);                     -- >> 3 aritmético (11 bits)
    cursor_x_pre <= to_signed(320, 11) + offset;

    cursor_x_clamp <=
        std_logic_vector(to_unsigned(0,   10)) when cursor_x_pre < 0   else
        std_logic_vector(to_unsigned(639, 10)) when cursor_x_pre > 639 else
        std_logic_vector(cursor_x_pre(9 downto 0));

    process(vga_ctrl_clk, dly_rst)
    begin
        if dly_rst = '1' then
            cursor_x_reg <= std_logic_vector(to_unsigned(320, 10));
        elsif rising_edge(vga_ctrl_clk) then
            cursor_x_reg <= cursor_x_clamp;
        end if;
    end process;

    -- -----------------------------------------------------------------------
    -- Controlador VGA
    -- -----------------------------------------------------------------------
    u_vga_controller : vga_controller
        port map (
            reset_n  => key(0),
            vga_clk  => vga_ctrl_clk,
            cursor_x => cursor_x_reg,
            blank_n  => vga_blank_n,
            hs       => vga_hs,
            vs       => vga_vs,
            vga_b    => vga_b,
            vga_g    => vga_g,
            vga_r    => vga_r
        );

end architecture structural;
