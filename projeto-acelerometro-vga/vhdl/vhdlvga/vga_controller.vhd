-- ============================================================================
-- vga_controller.vhd
-- Controlador VGA 640x480@60Hz com barra vertical branca controlada pelo
-- acelerômetro. cursor_x indica a coluna central da barra (0 a 639).
-- Equivalente ao vga_controller.v modificado do projeto Verilog.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
    port (
        reset_n  : in  std_logic;                    -- iRST_n (ativo baixo)
        vga_clk  : in  std_logic;                    -- iVGA_CLK (~25 MHz)
        cursor_x : in  std_logic_vector(9 downto 0); -- coluna do cursor (0..639)
        blank_n  : out std_logic;                    -- oBLANK_n área visível
        hs       : out std_logic;                    -- oHS sincronismo horizontal
        vs       : out std_logic;                    -- oVS sincronismo vertical
        vga_b    : out std_logic_vector(3 downto 0); -- oVGA_B canal azul
        vga_g    : out std_logic_vector(3 downto 0); -- oVGA_G canal verde
        vga_r    : out std_logic_vector(3 downto 0)  -- oVGA_R canal vermelho
    );
end entity vga_controller;

architecture rtl of vga_controller is

    component video_sync_generator is
        port (
            reset   : in  std_logic;
            vga_clk : in  std_logic;
            blank_n : out std_logic;
            hs      : out std_logic;
            vs      : out std_logic
        );
    end component;

    signal rst        : std_logic;
    signal c_blank_n  : std_logic;
    signal c_hs       : std_logic;
    signal c_vs       : std_logic;

    -- Contador de coluna dentro da área visível (0..639)
    signal col_cnt    : unsigned(9 downto 0) := (others => '0');

    -- Bordas da barra do cursor com saturação
    signal cursor_left  : unsigned(9 downto 0);
    signal cursor_right : unsigned(9 downto 0);

    -- Dado de cor BGR (24 bits: [23:16]=B, [15:8]=G, [7:0]=R)
    signal bgr_data   : std_logic_vector(23 downto 0) := (others => '0');

    -- Pipeline de sincronismo (atrasa 1 ciclo para alinhar com cores)
    signal m_hs       : std_logic := '0';
    signal m_vs       : std_logic := '0';
    signal m_blank_n  : std_logic := '0';

begin

    rst <= not reset_n;

    -- ------------------------------------------------------------------
    -- Gerador de sincronismo VGA (não modificado)
    -- ------------------------------------------------------------------
    u_sync : video_sync_generator
        port map (
            reset   => rst,
            vga_clk => vga_clk,
            blank_n => c_blank_n,
            hs      => c_hs,
            vs      => c_vs
        );

    -- ------------------------------------------------------------------
    -- Bordas da barra: cursor_x ± 2, com saturação em 0 e 639
    -- ------------------------------------------------------------------
    cursor_left  <= unsigned(cursor_x) - 2 when unsigned(cursor_x) > 2
                    else (others => '0');
    cursor_right <= unsigned(cursor_x) + 2 when unsigned(cursor_x) < 637
                    else to_unsigned(639, 10);

    -- ------------------------------------------------------------------
    -- Contador de coluna: 0..639, reinicia a cada nova linha
    -- ------------------------------------------------------------------
    process(vga_clk, reset_n)
    begin
        if reset_n = '0' then
            col_cnt <= (others => '0');
        elsif rising_edge(vga_clk) then
            if c_blank_n = '1' then
                if col_cnt = 639 then
                    col_cnt <= (others => '0');
                else
                    col_cnt <= col_cnt + 1;
                end if;
            else
                col_cnt <= (others => '0');
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------
    -- Geração de cor: barra branca sobre fundo cinza escuro
    -- ------------------------------------------------------------------
    process(vga_clk, reset_n)
    begin
        if reset_n = '0' then
            bgr_data <= (others => '0');
        elsif rising_edge(vga_clk) then
            if c_blank_n = '1' then
                if col_cnt >= cursor_left and col_cnt <= cursor_right then
                    bgr_data <= x"FFFFFF"; -- barra branca
                else
                    bgr_data <= x"202020"; -- fundo cinza escuro
                end if;
            else
                bgr_data <= (others => '0');
            end if;
        end if;
    end process;

    -- Mapeamento BGR → saídas VGA (4 bits mais significativos de cada canal)
    vga_b <= bgr_data(23 downto 20);
    vga_g <= bgr_data(15 downto 12);
    vga_r <= bgr_data(7  downto  4);

    -- ------------------------------------------------------------------
    -- Pipeline de sincronismo: atrasa HS/VS/BLANK um ciclo para alinhar
    -- com os dados de cor (equivalente ao Verilog original)
    -- ------------------------------------------------------------------
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            m_hs      <= c_hs;
            m_vs      <= c_vs;
            m_blank_n <= c_blank_n;
            hs        <= m_hs;
            vs        <= m_vs;
            blank_n   <= m_blank_n;
        end if;
    end process;

end architecture rtl;
