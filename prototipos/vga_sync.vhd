-- ============================================================================
-- vga_sync.vhd
-- Gerador de sincronismo VGA 640x480 @ 60Hz
-- Placa: Terasic DE10-Lite (MAX 10 FPGA)
--
-- Descrição:
--   Gera os sinais de sincronização horizontal e vertical para VGA padrão.
--   Utiliza clock de pixel de 25 MHz (derivado internamente de 50 MHz).
--   Fornece coordenadas do pixel atual e sinal de área visível (video_on).
--
-- Temporização horizontal (em ciclos de pixel clock):
--   Sync pulse (a) = 96, Back porch (b) = 48, Display (c) = 640, Front porch (d) = 16
--   Total = 800 pixels por linha
--
-- Temporização vertical (em linhas):
--   Sync pulse (a) = 2, Back porch (b) = 33, Display (c) = 480, Front porch (d) = 10
--   Total = 525 linhas por frame
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
    port (
        clk         : in  std_logic;                      -- Clock de 50 MHz
        reset_n     : in  std_logic;                      -- Reset ativo baixo
        hsync       : out std_logic;                      -- Sincronismo horizontal (ativo baixo)
        vsync       : out std_logic;                      -- Sincronismo vertical (ativo baixo)
        video_on    : out std_logic;                      -- '1' quando na área visível
        pixel_x     : out std_logic_vector(9 downto 0);   -- Coordenada X do pixel (0-639)
        pixel_y     : out std_logic_vector(9 downto 0);   -- Coordenada Y do pixel (0-479)
        pixel_tick  : out std_logic                       -- Pulso a 25 MHz (tick de pixel)
    );
end entity vga_sync;

architecture rtl of vga_sync is

    -- ========================================================================
    -- Constantes de temporização VGA 640x480 @ 60Hz
    -- ========================================================================
    -- Horizontal
    constant H_SYNC   : integer := 96;    -- Largura do pulso de sync
    constant H_BP     : integer := 48;    -- Back porch
    constant H_DISP   : integer := 640;   -- Área de display
    constant H_FP     : integer := 16;    -- Front porch
    constant H_TOTAL  : integer := 800;   -- Total de pixels por linha

    -- Vertical
    constant V_SYNC   : integer := 2;     -- Largura do pulso de sync
    constant V_BP     : integer := 33;    -- Back porch
    constant V_DISP   : integer := 480;   -- Área de display
    constant V_FP     : integer := 10;    -- Front porch
    constant V_TOTAL  : integer := 525;   -- Total de linhas por frame

    -- ========================================================================
    -- Sinais internos
    -- ========================================================================
    -- Divisor de clock: 50 MHz → 25 MHz
    signal clk_div    : std_logic := '0';  -- Toggle a cada ciclo de 50 MHz

    -- Contadores de posição
    signal h_count    : unsigned(9 downto 0) := (others => '0');  -- Contador horizontal (0-799)
    signal v_count    : unsigned(9 downto 0) := (others => '0');  -- Contador vertical (0-524)

    -- Sinais de sincronismo internos
    signal h_sync_reg : std_logic := '1';
    signal v_sync_reg : std_logic := '1';
    signal video_on_h : std_logic := '0';  -- Dentro da área horizontal visível
    signal video_on_v : std_logic := '0';  -- Dentro da área vertical visível

begin

    -- Saídas
    hsync     <= h_sync_reg;
    vsync     <= v_sync_reg;
    video_on  <= video_on_h and video_on_v;
    pixel_x   <= std_logic_vector(h_count - (H_SYNC + H_BP))
                 when (video_on_h = '1' and video_on_v = '1') else (others => '0');
    pixel_y   <= std_logic_vector(v_count - (V_SYNC + V_BP))
                 when (video_on_h = '1' and video_on_v = '1') else (others => '0');
    pixel_tick <= clk_div;

    -- ========================================================================
    -- Divisor de clock: 50 MHz → 25 MHz (toggle simples)
    -- ========================================================================
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            clk_div <= '0';
        elsif rising_edge(clk) then
            clk_div <= not clk_div;
        end if;
    end process;

    -- ========================================================================
    -- Contadores horizontal e vertical
    -- Avançam apenas no tick de pixel (25 MHz)
    -- ========================================================================
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            h_count <= (others => '0');
            v_count <= (others => '0');

        elsif rising_edge(clk) then
            if clk_div = '1' then  -- Tick de 25 MHz
                -- Contador horizontal
                if h_count = H_TOTAL - 1 then
                    h_count <= (others => '0');
                    -- Contador vertical: avança ao final de cada linha
                    if v_count = V_TOTAL - 1 then
                        v_count <= (others => '0');
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Geração dos sinais de sincronismo (ativos em nível baixo)
    -- ========================================================================
    -- Horizontal sync: ativo durante os primeiros H_SYNC pixels
    h_sync_reg <= '0' when (h_count < H_SYNC) else '1';

    -- Vertical sync: ativo durante as primeiras V_SYNC linhas
    v_sync_reg <= '0' when (v_count < V_SYNC) else '1';

    -- ========================================================================
    -- Detecção da área visível
    -- Área visível horizontal: após sync + back porch, durante H_DISP pixels
    -- Área visível vertical: após sync + back porch, durante V_DISP linhas
    -- ========================================================================
    video_on_h <= '1' when (h_count >= H_SYNC + H_BP) and
                           (h_count < H_SYNC + H_BP + H_DISP) else '0';

    video_on_v <= '1' when (v_count >= V_SYNC + V_BP) and
                           (v_count < V_SYNC + V_BP + V_DISP) else '0';

end architecture rtl;
