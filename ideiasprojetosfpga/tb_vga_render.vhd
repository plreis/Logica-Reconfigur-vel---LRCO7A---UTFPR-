library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_vga_render is
end entity;

architecture sim of tb_vga_render is
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz

    signal clk         : std_logic := '0';
    signal reset_n     : std_logic := '0';

    signal data_x      : std_logic_vector(15 downto 0) := (others => '0');
    signal data_valid  : std_logic := '0';

    signal hsync       : std_logic;
    signal vsync       : std_logic;
    signal video_on    : std_logic;
    signal pixel_x     : std_logic_vector(9 downto 0);
    signal pixel_y     : std_logic_vector(9 downto 0);
    signal pixel_tick  : std_logic;

    signal vga_r       : std_logic_vector(3 downto 0);
    signal vga_g       : std_logic_vector(3 downto 0);
    signal vga_b       : std_logic_vector(3 downto 0);

    procedure capture_visible_frame(
        constant file_name : in string;
        signal clk_s       : in std_logic;
        signal pixel_tick_s: in std_logic;
        signal video_on_s  : in std_logic;
        signal px_s        : in std_logic_vector(9 downto 0);
        signal py_s        : in std_logic_vector(9 downto 0);
        signal r_s         : in std_logic_vector(3 downto 0);
        signal g_s         : in std_logic_vector(3 downto 0);
        signal b_s         : in std_logic_vector(3 downto 0)
    ) is
        file f             : text;
        variable status    : file_open_status;
        variable l         : line;
        variable captured  : integer := 0;
        variable rv        : integer;
        variable gv        : integer;
        variable bv        : integer;
        constant TOTAL_PIX : integer := 640 * 480;
    begin
        file_open(status, f, file_name, write_mode);
        assert status = open_ok report "Nao foi possivel abrir arquivo: " & file_name severity failure;

        write(l, string'("P3"));
        writeline(f, l);
        write(l, string'("640 480"));
        writeline(f, l);
        write(l, string'("255"));
        writeline(f, l);

        while captured < TOTAL_PIX loop
            wait until rising_edge(clk_s);
            if pixel_tick_s = '1' and video_on_s = '1' then
                if to_integer(unsigned(px_s)) < 640 and to_integer(unsigned(py_s)) < 480 then
                    rv := to_integer(unsigned(r_s)) * 17;
                    gv := to_integer(unsigned(g_s)) * 17;
                    bv := to_integer(unsigned(b_s)) * 17;

                    write(l, rv);
                    write(l, character'(' '));
                    write(l, gv);
                    write(l, character'(' '));
                    write(l, bv);
                    writeline(f, l);

                    captured := captured + 1;
                end if;
            end if;
        end loop;

        file_close(f);
    end procedure;

begin
    clk <= not clk after CLK_PERIOD / 2;

    u_vga_sync : entity work.vga_sync
        port map (
            clk        => clk,
            reset_n    => reset_n,
            hsync      => hsync,
            vsync      => vsync,
            video_on   => video_on,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            pixel_tick => pixel_tick
        );

    u_game_logic : entity work.game_logic
        port map (
            clk        => clk,
            reset_n    => reset_n,
            data_x     => data_x,
            data_valid => data_valid,
            video_on   => video_on,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            pixel_tick => pixel_tick,
            vsync      => vsync,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b
        );

    stim_and_dump : process
    begin
        -- Reset inicial
        reset_n <= '0';
        data_valid <= '0';
        data_x <= x"0000";
        wait for 1 us;

        reset_n <= '1';
        data_valid <= '1';

        -- Frame 1: centro
        data_x <= x"0000";
        wait for 30 ms;
        capture_visible_frame("frame_center.ppm", clk, pixel_tick, video_on, pixel_x, pixel_y, vga_r, vga_g, vga_b);

        -- Frame 2: direita
        data_x <= x"00A0";
        wait for 30 ms;
        capture_visible_frame("frame_right.ppm", clk, pixel_tick, video_on, pixel_x, pixel_y, vga_r, vga_g, vga_b);

        -- Frame 3: esquerda
        data_x <= x"FF50";
        wait for 30 ms;
        capture_visible_frame("frame_left.ppm", clk, pixel_tick, video_on, pixel_x, pixel_y, vga_r, vga_g, vga_b);

        report "Frames gerados: frame_center.ppm, frame_right.ppm, frame_left.ppm" severity note;
        wait;
    end process;

end architecture;
