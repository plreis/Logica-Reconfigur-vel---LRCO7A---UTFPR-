-- ============================================================================
-- accel_vga_top.vhd
-- Top-level: Sistema de controle por inclinação com VGA e LEDs
-- Placa: Terasic DE10-Lite (MAX 10 FPGA - 10M50DAF484C7G)
--
-- Descrição:
--   Entidade de topo que instancia e conecta os módulos:
--     1. spi_control  — Leitura do acelerômetro ADXL345 via SPI 3-wire
--     2. led_driver    — Nível de bolha nos 10 LEDs
--     3. vga_sync      — Gerador de sincronismo VGA 640x480@60Hz
--     4. game_logic    — Objeto controlado por inclinação na tela VGA
--
--   Reset: KEY(0) — ativo baixo (pressionar = reset)
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accel_vga_top is
    port (
        -- Clock de 50 MHz
        MAX10_CLK1_50   : in    std_logic;                      -- PIN_P11

        -- Botões (active low)
        KEY             : in    std_logic_vector(1 downto 0);   -- KEY(0)=PIN_B8, KEY(1)=PIN_A7

        -- LEDs vermelhos
        LEDR            : out   std_logic_vector(9 downto 0);   -- LEDR(0)=PIN_A8 .. LEDR(9)=PIN_B11

        -- Interface VGA (4 bits por canal)
        VGA_R           : out   std_logic_vector(3 downto 0);   -- VGA_R[3:0]
        VGA_G           : out   std_logic_vector(3 downto 0);   -- VGA_G[3:0]
        VGA_B           : out   std_logic_vector(3 downto 0);   -- VGA_B[3:0]
        VGA_HS          : out   std_logic;                      -- PIN_N3
        VGA_VS          : out   std_logic;                      -- PIN_N1

        -- Interface com o acelerômetro ADXL345 (G-Sensor)
        GSENSOR_CS_N    : out   std_logic;                      -- PIN_AB16
        GSENSOR_SCLK    : out   std_logic;                      -- PIN_AB15
        GSENSOR_SDI     : inout std_logic;                      -- PIN_V11
        GSENSOR_SDO     : out   std_logic                       -- PIN_V12
    );
end entity accel_vga_top;

architecture structural of accel_vga_top is

    -- ========================================================================
    -- Declaração dos componentes
    -- ========================================================================

    component spi_control is
        port (
            clk         : in    std_logic;
            reset_n     : in    std_logic;
            spi_clk     : out   std_logic;
            spi_sdi     : inout std_logic;
            spi_cs_n    : out   std_logic;
            spi_sdo     : out   std_logic;
            data_x      : out   std_logic_vector(15 downto 0);
            data_valid  : out   std_logic
        );
    end component;

    component led_driver is
        port (
            clk         : in  std_logic;
            reset_n     : in  std_logic;
            data_x      : in  std_logic_vector(15 downto 0);
            data_valid  : in  std_logic;
            ledr        : out std_logic_vector(9 downto 0)
        );
    end component;

    component vga_sync is
        port (
            clk         : in  std_logic;
            reset_n     : in  std_logic;
            hsync       : out std_logic;
            vsync       : out std_logic;
            video_on    : out std_logic;
            pixel_x     : out std_logic_vector(9 downto 0);
            pixel_y     : out std_logic_vector(9 downto 0);
            pixel_tick  : out std_logic
        );
    end component;

    component game_logic is
        port (
            clk         : in  std_logic;
            reset_n     : in  std_logic;
            data_x      : in  std_logic_vector(15 downto 0);
            data_valid  : in  std_logic;
            video_on    : in  std_logic;
            pixel_x     : in  std_logic_vector(9 downto 0);
            pixel_y     : in  std_logic_vector(9 downto 0);
            pixel_tick  : in  std_logic;
            vsync       : in  std_logic;
            vga_r       : out std_logic_vector(3 downto 0);
            vga_g       : out std_logic_vector(3 downto 0);
            vga_b       : out std_logic_vector(3 downto 0)
        );
    end component;

    -- ========================================================================
    -- Sinais internos de interconexão
    -- ========================================================================

    -- Reset (KEY(0) ativo baixo)
    signal reset_n      : std_logic;

    -- Dados do acelerômetro (saída do spi_control)
    signal accel_x      : std_logic_vector(15 downto 0);
    signal accel_valid  : std_logic;

    -- Sinais do módulo VGA sync
    signal vga_hsync    : std_logic;
    signal vga_vsync    : std_logic;
    signal video_on     : std_logic;
    signal pixel_x      : std_logic_vector(9 downto 0);
    signal pixel_y      : std_logic_vector(9 downto 0);
    signal pixel_tick   : std_logic;

begin

    -- Reset a partir do botão KEY(0)
    reset_n <= KEY(0);

    -- Saídas de sincronismo VGA
    VGA_HS <= vga_hsync;
    VGA_VS <= vga_vsync;

    -- ========================================================================
    -- Instanciação dos módulos
    -- ========================================================================

    -- Módulo 1: Interface SPI com o acelerômetro ADXL345
    u_spi_control : spi_control
        port map (
            clk         => MAX10_CLK1_50,
            reset_n     => reset_n,
            spi_clk     => GSENSOR_SCLK,
            spi_sdi     => GSENSOR_SDI,
            spi_cs_n    => GSENSOR_CS_N,
            spi_sdo     => GSENSOR_SDO,
            data_x      => accel_x,
            data_valid  => accel_valid
        );

    -- Módulo 2: Driver de LEDs (nível de bolha)
    u_led_driver : led_driver
        port map (
            clk         => MAX10_CLK1_50,
            reset_n     => reset_n,
            data_x      => accel_x,
            data_valid  => accel_valid,
            ledr        => LEDR
        );

    -- Módulo 3: Gerador de sincronismo VGA
    u_vga_sync : vga_sync
        port map (
            clk         => MAX10_CLK1_50,
            reset_n     => reset_n,
            hsync       => vga_hsync,
            vsync       => vga_vsync,
            video_on    => video_on,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            pixel_tick  => pixel_tick
        );

    -- Módulo 4: Lógica do jogo (objeto na tela VGA)
    u_game_logic : game_logic
        port map (
            clk         => MAX10_CLK1_50,
            reset_n     => reset_n,
            data_x      => accel_x,
            data_valid  => accel_valid,
            video_on    => video_on,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            pixel_tick  => pixel_tick,
            vsync       => vga_vsync,
            vga_r       => VGA_R,
            vga_g       => VGA_G,
            vga_b       => VGA_B
        );

end architecture structural;
