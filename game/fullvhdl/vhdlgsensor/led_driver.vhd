-- ============================================================================
-- led_driver.vhd
-- Converte dados de 10 bits do acelerômetro em padrão de LEDs.
-- O padrão indica magnitude e direção da inclinação no eixo X.
-- Equivalente ao led_driver.v do projeto Verilog original.
--
-- Lógica:
--   - iG_INT2='1': usa resolução de ±2g (10 bits: iDIG[9:5])
--   - iG_INT2='0': usa resolução de ±g  (9 bits, lógica de saturação)
--   - int2_count: temporizador ativado na borda de subida de G_INT2
--     - int2_count[23]='1': exibe padrão de inclinação
--     - int2_count[23]='0': pisca todos os LEDs (indicador de atividade)
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_driver is
    port (
        reset_n : in  std_logic;                    -- iRSTN (ativo baixo)
        clk     : in  std_logic;                    -- iCLK  (50 MHz)
        dig     : in  std_logic_vector(9 downto 0); -- iDIG  dados acelerômetro
        g_int2  : in  std_logic;                    -- iG_INT2 interrupção
        led     : out std_logic_vector(9 downto 0)  -- oLED saída dos LEDs
    );
end entity led_driver;

architecture rtl of led_driver is

    signal select_data    : std_logic_vector(4 downto 0);
    signal signed_bit     : std_logic;
    signal abs_high       : std_logic_vector(3 downto 0);
    signal int2_d         : std_logic_vector(1 downto 0) := "00";
    signal int2_count     : unsigned(23 downto 0)        := x"800000";
    signal int2_count_en  : std_logic                    := '0';

begin

    -- ------------------------------------------------------------------
    -- Seleção de dado conforme resolução (combinatorial)
    -- g_int2='1': ±2g → usa bits [9:5]
    -- g_int2='0': ±g  → 9-bit com saturação nos extremos
    -- ------------------------------------------------------------------
    process(g_int2, dig)
        variable sel_v : std_logic_vector(4 downto 0);
    begin
        if g_int2 = '1' then
            sel_v := dig(9 downto 5);
        else
            -- Saturação na resolução de ±g (9 bits)
            if dig(9) = '1' then                -- negativo
                if dig(8) = '1' then
                    sel_v := dig(8 downto 4);
                else
                    sel_v := "10000";           -- satura em -1g
                end if;
            else                                -- positivo
                if dig(8) = '1' then
                    sel_v := "01111";           -- satura em +1g
                else
                    sel_v := dig(8 downto 4);
                end if;
            end if;
        end if;
        select_data <= sel_v;
    end process;

    -- Bit de sinal e valor absoluto (complemento de um)
    signed_bit <= select_data(4);
    abs_high   <= (not select_data(3 downto 0)) when signed_bit = '1'
                  else select_data(3 downto 0);

    -- ------------------------------------------------------------------
    -- Decodificador de LEDs (combinatorial)
    -- int2_count[23]='1': padrão de posição
    -- int2_count[23]='0': pisca todos (indicador de atividade)
    -- ------------------------------------------------------------------
    process(int2_count, abs_high, signed_bit)
    begin
        if int2_count(23) = '1' then
            case abs_high is
                when "0000" => led <= "00" & x"30";
                when "0001" =>
                    if signed_bit = '1' then led <= "00" & x"20";
                    else                     led <= "00" & x"10"; end if;
                when "0010" =>
                    if signed_bit = '1' then led <= "00" & x"60";
                    else                     led <= "00" & x"18"; end if;
                when "0011" =>
                    if signed_bit = '1' then led <= "00" & x"40";
                    else                     led <= "00" & x"08"; end if;
                when "0100" =>
                    if signed_bit = '1' then led <= "00" & x"C0";
                    else                     led <= "00" & x"0C"; end if;
                when "0101" =>
                    if signed_bit = '1' then led <= "00" & x"80";
                    else                     led <= "00" & x"04"; end if;
                when "0110" =>
                    if signed_bit = '1' then led <= "01" & x"80";
                    else                     led <= "00" & x"06"; end if;
                when "0111" =>
                    if signed_bit = '1' then led <= "01" & x"00";
                    else                     led <= "00" & x"02"; end if;
                when "1000" =>
                    if signed_bit = '1' then led <= "11" & x"00";
                    else                     led <= "00" & x"03"; end if;
                when others =>
                    if signed_bit = '1' then led <= "10" & x"00";
                    else                     led <= "00" & x"01"; end if;
            end case;
        else
            -- Indicador de atividade: pisca conforme bit 20
            if int2_count(20) = '1' then
                led <= (others => '0');
            else
                led <= (others => '1');
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------
    -- Temporizador de atividade (síncrono, 50 MHz)
    -- Ativa na borda de subida de g_int2, conta até saturar em bit 23
    -- ------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            int2_count_en <= '0';
            int2_count    <= x"800000";
            int2_d        <= "00";
        elsif rising_edge(clk) then
            -- Pipeline de dois estágios para detectar borda de subida
            int2_d <= int2_d(0) & g_int2;

            if int2_d(1) = '0' and int2_d(0) = '1' then
                -- Borda de subida detectada: reinicia contador
                int2_count_en <= '1';
                int2_count    <= (others => '0');
            elsif int2_count(23) = '1' then
                int2_count_en <= '0';
            else
                int2_count <= int2_count + 1;
            end if;
        end if;
    end process;

end architecture rtl;
