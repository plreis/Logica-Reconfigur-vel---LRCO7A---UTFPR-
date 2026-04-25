-- ============================================================================
-- video_sync_generator.vhd
-- Gerador de sincronismo VGA 640x480 @ 60 Hz.
-- Produz HS, VS e blank_n baseado em contadores horizontal e vertical.
-- Equivalente ao video_sync_generator.v do projeto Verilog original.
--
-- Temporização:
--   Horizontal (pixels):  total=800, sync=96, back porch=144, visible=640, front=16
--   Vertical   (linhas):  total=525, sync=2,  back porch=34,  visible=480, front=11
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_sync_generator is
    port (
        reset   : in  std_logic; -- reset ativo alto
        vga_clk : in  std_logic; -- pixel clock ~25 MHz
        blank_n : out std_logic; -- '1' durante área visível
        hs      : out std_logic; -- sinal de sincronismo horizontal
        vs      : out std_logic  -- sinal de sincronismo vertical
    );
end entity video_sync_generator;

architecture rtl of video_sync_generator is

    -- Parâmetros de temporização VGA 640x480@60Hz
    constant HORI_LINE    : integer := 800;
    constant HORI_BACK    : integer := 144;
    constant HORI_FRONT   : integer := 16;
    constant VERT_LINE    : integer := 525;
    constant VERT_BACK    : integer := 34;
    constant VERT_FRONT   : integer := 11;
    constant H_SYNC_CYCLE : integer := 96;
    constant V_SYNC_CYCLE : integer := 2;

    signal h_cnt : unsigned(10 downto 0) := (others => '0');
    signal v_cnt : unsigned(9 downto 0)  := (others => '0');

    signal c_hd        : std_logic;
    signal c_vd        : std_logic;
    signal hori_valid  : std_logic;
    signal vert_valid  : std_logic;
    signal c_den       : std_logic;

begin

    -- ------------------------------------------------------------------
    -- Contadores H e V — equivalente ao always@(negedge vga_clk) do Verilog
    -- ------------------------------------------------------------------
    process(vga_clk, reset)
    begin
        if reset = '1' then
            h_cnt <= (others => '0');
            v_cnt <= (others => '0');
        elsif falling_edge(vga_clk) then
            if h_cnt = HORI_LINE - 1 then
                h_cnt <= (others => '0');
                if v_cnt = VERT_LINE - 1 then
                    v_cnt <= (others => '0');
                else
                    v_cnt <= v_cnt + 1;
                end if;
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------
    -- Sinais de sincronismo (combinatorial)
    -- ------------------------------------------------------------------
    c_hd       <= '0' when h_cnt < H_SYNC_CYCLE else '1';
    c_vd       <= '0' when v_cnt < V_SYNC_CYCLE else '1';
    hori_valid <= '1' when (h_cnt < (HORI_LINE - HORI_FRONT)) and
                           (h_cnt >= HORI_BACK) else '0';
    vert_valid <= '1' when (v_cnt < (VERT_LINE - VERT_FRONT)) and
                           (v_cnt >= VERT_BACK) else '0';
    c_den      <= hori_valid and vert_valid;

    -- ------------------------------------------------------------------
    -- Registro das saídas na borda de descida (equivalente ao Verilog)
    -- ------------------------------------------------------------------
    process(vga_clk)
    begin
        if falling_edge(vga_clk) then
            hs      <= c_hd;
            vs      <= c_vd;
            blank_n <= c_den;
        end if;
    end process;

end architecture rtl;
