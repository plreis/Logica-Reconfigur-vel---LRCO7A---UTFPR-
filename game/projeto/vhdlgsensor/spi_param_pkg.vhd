-- ============================================================================
-- spi_param_pkg.vhd
-- Pacote de constantes equivalente ao spi_param.h do Verilog original.
-- Define parâmetros de comunicação SPI com o acelerômetro ADXL345.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

package spi_param_pkg is

    -- Comprimentos de dados
    constant IDLE_MSB   : integer := 14;   -- índice MSB do contador de espera (15 bits)
    constant SI_DataL   : integer := 15;   -- tamanho da palavra SPI TX (16 bits: 15 downto 0)
    constant SO_DataL   : integer := 7;    -- tamanho da palavra SPI RX (8 bits:  7 downto 0)

    -- Modos de operação (2 bits MSB da palavra SPI)
    constant SPI_WRITE_MODE : std_logic_vector(1 downto 0) := "00";
    constant SPI_READ_MODE  : std_logic_vector(1 downto 0) := "10";

    -- Número de registros inicializados na sequência de boot
    constant INI_NUMBER : integer := 11;

    -- Estados da FSM SPI
    constant SPI_IDLE     : std_logic := '0';
    constant SPI_TRANSFER : std_logic := '1';

    -- Endereços de registros de ESCRITA do ADXL345 (6 bits)
    constant BW_RATE         : std_logic_vector(5 downto 0) := "101100"; -- 0x2C
    constant POWER_CONTROL   : std_logic_vector(5 downto 0) := "101101"; -- 0x2D
    constant DATA_FORMAT     : std_logic_vector(5 downto 0) := "110001"; -- 0x31
    constant INT_ENABLE      : std_logic_vector(5 downto 0) := "101110"; -- 0x2E
    constant INT_MAP         : std_logic_vector(5 downto 0) := "101111"; -- 0x2F
    constant THRESH_ACT      : std_logic_vector(5 downto 0) := "100100"; -- 0x24
    constant THRESH_INACT    : std_logic_vector(5 downto 0) := "100101"; -- 0x25
    constant TIME_INACT      : std_logic_vector(5 downto 0) := "100110"; -- 0x26
    constant ACT_INACT_CTL   : std_logic_vector(5 downto 0) := "100111"; -- 0x27
    constant THRESH_FF       : std_logic_vector(5 downto 0) := "101000"; -- 0x28
    constant TIME_FF         : std_logic_vector(5 downto 0) := "101001"; -- 0x29

    -- Endereços de registros de LEITURA do ADXL345 (6 bits)
    constant INT_SOURCE : std_logic_vector(5 downto 0) := "110000"; -- 0x30 status de interrupção
    constant X_LB       : std_logic_vector(5 downto 0) := "110010"; -- 0x32 eixo X byte baixo
    constant X_HB       : std_logic_vector(5 downto 0) := "110011"; -- 0x33 eixo X byte alto
    constant Y_LB       : std_logic_vector(5 downto 0) := "110100"; -- 0x34 eixo Y byte baixo
    constant Y_HB       : std_logic_vector(5 downto 0) := "110101"; -- 0x35 eixo Y byte alto
    constant Z_LB       : std_logic_vector(5 downto 0) := "110110"; -- 0x36 eixo Z byte baixo
    constant Z_HB       : std_logic_vector(5 downto 0) := "110111"; -- 0x37 eixo Z byte alto

end package spi_param_pkg;
