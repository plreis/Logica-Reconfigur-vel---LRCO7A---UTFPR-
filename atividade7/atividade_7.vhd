library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity atividade_7 is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        pause_n  : in  std_logic;
        time_sel : in  std_logic;
        led_end  : out std_logic;
        hex0     : out std_logic_vector(6 downto 0);
        hex1     : out std_logic_vector(6 downto 0);
        hex2     : out std_logic_vector(6 downto 0);
        hex3     : out std_logic_vector(6 downto 0)
    );
end entity atividade_7;

architecture rtl of atividade_7 is

    constant CLK_FREQ_HZ      : natural := 50_000_000;
    constant ONE_SECOND_MAX   : natural := CLK_FREQ_HZ - 1;
    constant TIME_SHORT_SEC   : natural := 15;
    constant TIME_LONG_SEC    : natural := 60;

    function bcd_to_ssd(bcd : std_logic_vector(3 downto 0))
        return std_logic_vector is
    begin
        case bcd is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when others => return "1111111";
        end case;
    end function;

    function bin_to_bcd(value : natural range 0 to 9999)
        return std_logic_vector is
        variable bcd      : unsigned(15 downto 0) := (others => '0');
        variable bin_work : unsigned(13 downto 0);
    begin
        bin_work := to_unsigned(value, bin_work'length);

        for i in 0 to bin_work'length - 1 loop
            for digit in 0 to 3 loop
                if bcd(digit * 4 + 3 downto digit * 4) > to_unsigned(4, 4) then
                    bcd(digit * 4 + 3 downto digit * 4) :=
                        bcd(digit * 4 + 3 downto digit * 4) + to_unsigned(3, 4);
                end if;
            end loop;

            bcd := bcd sll 1;
            bcd(0) := bin_work(bin_work'high);
            bin_work := bin_work sll 1;
        end loop;

        return std_logic_vector(bcd);
    end function;

    signal second_counter : natural range 0 to ONE_SECOND_MAX := 0;
    signal current_time   : natural range 0 to 9999 := TIME_SHORT_SEC;
    signal reload_pending : std_logic := '1';
    signal bcd_value      : std_logic_vector(15 downto 0);

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            second_counter <= 0;
            current_time   <= TIME_SHORT_SEC;
            reload_pending <= '1';
            led_end        <= '0';
elsif rising_edge(clk) then
    if reload_pending = '1' then
        -- Lógica de recarga (Ocorre apenas após o Reset)
        second_counter <= 0;
        reload_pending <= '0';
        if time_sel = '1' then current_time <= TIME_LONG_SEC;
        else current_time <= TIME_SHORT_SEC;
        end if;
    elsif pause_n = '1' then 
        -- O timer só decrementa se pause_n for '1' (botão solto)
        -- Se pause_n for '0' (pressionado), ele entra aqui e "congela"
        if current_time > 0 then
            if second_counter = ONE_SECOND_MAX then
                second_counter <= 0;
                current_time <= current_time - 1;
            else
                second_counter <= second_counter + 1;
            end if;
        else
            led_end <= '1';
        end if;
    end if;
        end if;
    end process;

    bcd_value <= bin_to_bcd(current_time);

    hex0 <= bcd_to_ssd(bcd_value(3 downto 0));
    hex1 <= bcd_to_ssd(bcd_value(7 downto 4));
    hex2 <= bcd_to_ssd(bcd_value(11 downto 8));
    hex3 <= bcd_to_ssd(bcd_value(15 downto 12));

end architecture rtl;
