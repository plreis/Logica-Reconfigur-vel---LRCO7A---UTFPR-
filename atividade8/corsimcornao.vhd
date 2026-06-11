library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity corsimcornao is
    generic (
        F_CLK : integer := 50_000_000
    );
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        mode_btn_n : in  std_logic;
        enable     : in  std_logic;
        speed_sel  : in  std_logic;
        leds       : out std_logic_vector(3 downto 0)
    );
end entity;

architecture comportamento of corsimcornao is
    type modo_type is (ACESO, INTERMITENTE, ALTERNADO, SEQUENCIAL);

    signal modo_atual  : modo_type;
    signal proximo_modo: modo_type;
    signal timer       : integer range 0 to F_CLK := 0;
    signal limite_timer: integer;
    signal mode_btn_reg: std_logic;
    signal sub_estado  : integer range 0 to 3 := 0;
begin
    limite_timer <= F_CLK / 2 when speed_sel = '0' else F_CLK / 10;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            modo_atual <= ACESO;
            mode_btn_reg <= '1';
        elsif rising_edge(clk) then
            mode_btn_reg <= mode_btn_n;

            if mode_btn_reg = '1' and mode_btn_n = '0' then
                modo_atual <= proximo_modo;
            end if;
        end if;
    end process;

    process(modo_atual)
    begin
        case modo_atual is
            when ACESO        => proximo_modo <= INTERMITENTE;
            when INTERMITENTE => proximo_modo <= ALTERNADO;
            when ALTERNADO    => proximo_modo <= SEQUENCIAL;
            when SEQUENCIAL   => proximo_modo <= ACESO;
        end case;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timer <= 0;
            sub_estado <= 0;
        elsif rising_edge(clk) then
            if enable = '1' then
                if timer >= limite_timer then
                    timer <= 0;

                    if sub_estado = 3 then
                        sub_estado <= 0;
                    else
                        sub_estado <= sub_estado + 1;
                    end if;
                else
                    timer <= timer + 1;
                end if;
            end if;
        end if;
    end process;

    process(modo_atual, sub_estado)
    begin
        case modo_atual is
            when ACESO =>
                leds <= "1111";

            when INTERMITENTE =>
                if sub_estado mod 2 = 0 then
                    leds <= "0101";
                else
                    leds <= "1010";
                end if;

            when ALTERNADO =>
                if sub_estado mod 2 = 0 then
                    leds <= "0011";
                else
                    leds <= "1100";
                end if;

            when SEQUENCIAL =>
                case sub_estado is
                    when 0      => leds <= "0001";
                    when 1      => leds <= "0010";
                    when 2      => leds <= "0100";
                    when 3      => leds <= "1000";
                    when others => leds <= "0000";
                end case;
        end case;
    end process;
end architecture;
