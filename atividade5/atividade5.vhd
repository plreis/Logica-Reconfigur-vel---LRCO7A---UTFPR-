library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity atividade5 is
    generic (
        F_CLK : integer := 50_000_000 -- Frequência de 50 MHz ( FREQ DA PLACA) 
    );
    port (
        clk      : in  std_logic;                    -- Clock P11
        rst      : in  std_logic;                    -- Botão KEY0 (Ativo em 0) 
        enable   : in  std_logic;                    -- Chave SW0
        speed_sel: in  std_logic;                    -- Chave SW1 (Seleção de velocidade)
        leds     : out std_logic_vector(9 downto 0)  -- LEDs LEDR0 a LEDR9
    );
end entity;

architecture comportamento of atividade5 is
    -- Constantes para limites de contagem (velocidades)
    constant VEL_LENTA : integer := F_CLK / 4; -- ~250ms
    constant VEL_RAPIDA: integer := F_CLK / 10; -- ~100ms
    
    signal contador : integer range 0 to F_CLK := 0;
    signal limite   : integer := VEL_LENTA;
    signal indice   : integer range 0 to 9 := 0;
    signal subindo  : boolean := true; -- Direção do movimento
begin

    -- Processo para definir a velocidade baseada na chave speed_sel
    limite <= VEL_RAPIDA when speed_sel = '1' else VEL_LENTA;

    process(clk, rst)
    begin
        -- Reset assíncrono: limpa contadores e apaga LEDs [10, 17]
        if rst = '0' then 
            contador <= 0;
            indice <= 0;
            subindo <= true;
            leds <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Só processa se o enable estiver ativo (chave SW0 = '1') [6]
            if enable = '1' then
                if contador >= limite then
                    contador <= 0; -- Reinicia timer [18]
                    
                    -- Lógica de movimentação dos LEDs
                    if subindo then
                        if indice = 9 then
                            subindo <= false; -- Inverte para descer
                            indice <= 8;
                        else
                            indice <= indice + 1;
                        end if;
                    else
                        if indice = 0 then
                            subindo <= true; -- Inverte para subir
                            indice <= 1;
                        else
                            indice <= indice - 1;
                        end if;
                    end if;
                else
                    contador <= contador + 1;
                end if;

                -- Atualiza a saída: apenas o LED no índice atual acende [19, 20]
                leds <= (others => '0');
                leds(indice) <= '1';
            end if;
        end if;
    end process;

end architecture;