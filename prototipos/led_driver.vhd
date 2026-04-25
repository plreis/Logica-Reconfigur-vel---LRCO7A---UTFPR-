-- ============================================================================
-- led_driver.vhd
-- Driver de LEDs para exibição de nível de bolha (bubble level)
-- Placa: Terasic DE10-Lite (MAX 10 FPGA)
--
-- Descrição:
--   Recebe o valor do eixo X do acelerômetro (16 bits, complemento de 2)
--   e mapeia para um único LED aceso entre LEDR(0) e LEDR(9), simulando
--   um nível de bolha. Placa reta = LED central; inclinada = LED lateral.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_driver is
    port (
        clk         : in  std_logic;                      -- Clock de 50 MHz
        reset_n     : in  std_logic;                      -- Reset ativo baixo
        data_x      : in  std_logic_vector(15 downto 0);  -- Valor do eixo X (complemento de 2)
        data_valid  : in  std_logic;                      -- Pulso de dado válido
        ledr        : out std_logic_vector(9 downto 0)    -- Saída para os 10 LEDs
    );
end entity led_driver;

architecture rtl of led_driver is

    -- Sinal interno para armazenar a posição do LED
    signal led_pos   : integer range 0 to 9 := 4;
    signal led_reg   : std_logic_vector(9 downto 0) := "0000010000";  -- LED 4 (centro)

    -- Valor do acelerômetro como inteiro com sinal
    signal accel_val : signed(15 downto 0);

begin

    -- Saída dos LEDs
    ledr <= led_reg;

    -- ========================================================================
    -- Processo de mapeamento: valor do acelerômetro → posição do LED
    --
    -- O ADXL345 em ±2g retorna ~256 por g (sensibilidade de 256 LSB/g).
    -- Faixa prática de inclinação lateral: -300 a +300
    -- Dividimos em 10 faixas de ~60 unidades cada.
    -- ========================================================================
    process(clk, reset_n)
        variable val : signed(15 downto 0);
    begin
        if reset_n = '0' then
            led_pos <= 4;
            led_reg <= "0000010000";

        elsif rising_edge(clk) then
            if data_valid = '1' then
                val := signed(data_x);

                -- Mapeamento de faixas do acelerômetro para posição do LED
                -- Valores negativos = inclinação à esquerda (LEDs 0-3)
                -- Valores positivos = inclinação à direita (LEDs 6-9)
                -- Valores próximos de zero = centro (LEDs 4-5)
                if    val < -225 then led_pos <= 0;
                elsif val < -175 then led_pos <= 1;
                elsif val < -125 then led_pos <= 2;
                elsif val < -60  then led_pos <= 3;
                elsif val < -10  then led_pos <= 4;
                elsif val <  10  then led_pos <= 4;  -- Zona morta central
                elsif val <  60  then led_pos <= 5;
                elsif val <  125 then led_pos <= 6;
                elsif val <  175 then led_pos <= 7;
                elsif val <  225 then led_pos <= 8;
                else                  led_pos <= 9;
                end if;
            end if;

            -- Gera o padrão de LEDs com um único bit aceso na posição calculada
            case led_pos is
                when 0 => led_reg <= "0000000001";
                when 1 => led_reg <= "0000000010";
                when 2 => led_reg <= "0000000100";
                when 3 => led_reg <= "0000001000";
                when 4 => led_reg <= "0000010000";
                when 5 => led_reg <= "0000100000";
                when 6 => led_reg <= "0001000000";
                when 7 => led_reg <= "0010000000";
                when 8 => led_reg <= "0100000000";
                when 9 => led_reg <= "1000000000";
                when others => led_reg <= "0000010000";  -- Don't care: centro
            end case;
        end if;
    end process;

end architecture rtl;
