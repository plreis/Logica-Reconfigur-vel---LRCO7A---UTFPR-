-- ============================================================================
-- game_logic.vhd
-- Lógica do mini-jogo VGA: objeto controlado por inclinação
-- Placa: Terasic DE10-Lite (MAX 10 FPGA)
--
-- Descrição:
--   Mantém a posição de um objeto retangular (barra) na tela VGA.
--   A posição horizontal é atualizada a cada frame (~60 Hz) com velocidade
--   proporcional à inclinação detectada pelo acelerômetro.
--   Gera sinais RGB com base na posição do pixel atual vs. posição do objeto.
--
--   Objeto: retângulo de 40x20 pixels, posição vertical fixa (centro da tela)
--   Fundo: azul escuro; Objeto: verde claro; Borda inferior: linha branca
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game_logic is
    port (
        clk         : in  std_logic;                      -- Clock de 50 MHz
        reset_n     : in  std_logic;                      -- Reset ativo baixo
        -- Dados do acelerômetro
        data_x      : in  std_logic_vector(15 downto 0);  -- Valor do eixo X
        data_valid  : in  std_logic;                      -- Pulso de dado válido
        -- Interface com o módulo VGA
        video_on    : in  std_logic;                      -- '1' na área visível
        pixel_x     : in  std_logic_vector(9 downto 0);   -- Coordenada X do pixel
        pixel_y     : in  std_logic_vector(9 downto 0);   -- Coordenada Y do pixel
        pixel_tick  : in  std_logic;                      -- Tick de 25 MHz
        vsync       : in  std_logic;                      -- Sync vertical (para detecção de frame)
        -- Saídas RGB (4 bits cada)
        vga_r       : out std_logic_vector(3 downto 0);
        vga_g       : out std_logic_vector(3 downto 0);
        vga_b       : out std_logic_vector(3 downto 0)
    );
end entity game_logic;

architecture rtl of game_logic is

    -- ========================================================================
    -- Constantes do objeto e da tela
    -- ========================================================================
    constant SCREEN_W    : integer := 640;   -- Largura da tela
    constant SCREEN_H    : integer := 480;   -- Altura da tela

    constant OBJ_W       : integer := 40;    -- Largura do objeto (pixels)
    constant OBJ_H       : integer := 20;    -- Altura do objeto (pixels)
    constant OBJ_Y       : integer := 230;   -- Posição Y fixa do objeto (centro vertical)

    -- Limites de posição horizontal do objeto
    constant OBJ_X_MIN   : integer := 0;
    constant OBJ_X_MAX   : integer := SCREEN_W - OBJ_W;  -- 600

    -- Posição da "pista" (linha guia horizontal)
    constant TRACK_Y     : integer := OBJ_Y + OBJ_H;     -- Logo abaixo do objeto
    constant TRACK_H     : integer := 4;                  -- Altura da pista

    -- ========================================================================
    -- Sinais internos
    -- ========================================================================
    -- Posição horizontal do objeto (em pixels)
    signal obj_x         : integer range 0 to OBJ_X_MAX := OBJ_X_MAX / 2;  -- Inicia no centro

    -- Velocidade derivada do acelerômetro (com sinal)
    signal velocity      : signed(15 downto 0) := (others => '0');

    -- Detecção de borda do vsync para atualização por frame
    signal vsync_prev    : std_logic := '1';
    signal frame_tick    : std_logic := '0';

    -- Posição do pixel atual como inteiros
    signal px            : integer range 0 to 1023;
    signal py            : integer range 0 to 1023;

    -- Sinais de detecção de região
    signal on_object     : std_logic;  -- Pixel está dentro do objeto
    signal on_track      : std_logic;  -- Pixel está na pista/trilho
    signal on_center     : std_logic;  -- Pixel está na marca central

begin

    -- Converte coordenadas do pixel para inteiros
    px <= to_integer(unsigned(pixel_x));
    py <= to_integer(unsigned(pixel_y));

    -- ========================================================================
    -- Detecção de início de frame (borda de subida do vsync)
    -- Usado para atualizar a posição do objeto a ~60 Hz
    -- ========================================================================
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            vsync_prev <= '1';
            frame_tick <= '0';
        elsif rising_edge(clk) then
            frame_tick <= '0';
            if vsync_prev = '0' and vsync = '1' then
                frame_tick <= '1';  -- Borda de subida do vsync = novo frame
            end if;
            vsync_prev <= vsync;
        end if;
    end process;

    -- ========================================================================
    -- Atualização da velocidade a partir do acelerômetro
    -- Divide o valor do eixo X por 64 para obter velocidade suave
    -- ========================================================================
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            velocity <= (others => '0');
        elsif rising_edge(clk) then
            if data_valid = '1' then
                -- Divisão por 64 via deslocamento aritmético (shift right de 6 bits)
                -- Isso converte a faixa ~±256 para ~±4 pixels/frame
                velocity <= shift_right(signed(data_x), 6);
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Atualização da posição do objeto (a cada frame, ~60 Hz)
    -- ========================================================================
    process(clk, reset_n)
        variable new_pos : integer;
    begin
        if reset_n = '0' then
            obj_x <= OBJ_X_MAX / 2;  -- Posição inicial: centro

        elsif rising_edge(clk) then
            if frame_tick = '1' then
                -- Calcula nova posição
                new_pos := obj_x + to_integer(velocity);

                -- Limita aos extremos da tela
                if new_pos < OBJ_X_MIN then
                    obj_x <= OBJ_X_MIN;
                elsif new_pos > OBJ_X_MAX then
                    obj_x <= OBJ_X_MAX;
                else
                    obj_x <= new_pos;
                end if;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Detecção de regiões na tela
    -- ========================================================================
    -- O pixel atual está dentro do objeto?
    on_object <= '1' when (px >= obj_x) and (px < obj_x + OBJ_W) and
                          (py >= OBJ_Y) and (py < OBJ_Y + OBJ_H) else '0';

    -- O pixel está na pista/trilho (linha horizontal abaixo do objeto)?
    on_track  <= '1' when (py >= TRACK_Y) and (py < TRACK_Y + TRACK_H) else '0';

    -- Marca central da tela (linha vertical fina no centro)
    on_center <= '1' when (px >= (SCREEN_W / 2) - 1) and (px <= (SCREEN_W / 2) + 1) and
                          (py >= OBJ_Y - 10) and (py < TRACK_Y + TRACK_H + 10) else '0';

    -- ========================================================================
    -- Geração de cores RGB
    -- ========================================================================
    process(video_on, on_object, on_track, on_center)
    begin
        if video_on = '0' then
            -- Fora da área visível: sinais RGB devem ser zero
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";

        elsif on_object = '1' then
            -- Objeto: verde brilhante
            vga_r <= "0010";
            vga_g <= "1111";
            vga_b <= "0010";

        elsif on_center = '1' then
            -- Marca central: amarelo
            vga_r <= "1111";
            vga_g <= "1111";
            vga_b <= "0000";

        elsif on_track = '1' then
            -- Pista/trilho: branco
            vga_r <= "1111";
            vga_g <= "1111";
            vga_b <= "1111";

        else
            -- Fundo: azul escuro
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0011";
        end if;
    end process;

end architecture rtl;
