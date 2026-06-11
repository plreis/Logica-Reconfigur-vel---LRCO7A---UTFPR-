Este relatório apresenta a implementação da **Atividade 8**, denominada **corsimcornao**, que consiste em um sistema de controle para LEDs de um acessório de fã (chifres luminosos). O projeto utiliza máquinas de estados para gerenciar diferentes modos de iluminação e velocidades, integrando conceitos de temporização e controle síncrono.

### 1. Introdução

A atividade introduz a aplicação prática de **Máquinas de Estados Finitas (FSM)** para o controle de comportamento complexo em hardware. Os novos conceitos explorados são:

*   **Máquina de Estados de Moore:** Onde as saídas (o padrão dos LEDs) dependem exclusivamente do estado atual da máquina, garantindo transições síncronas e estáveis.
*   **Hierarquia de Estados:** O sistema utiliza uma máquina de estados principal para alternar entre os **4 modos de operação** (Aceso, Intermitente, Alternado e Sequencial) e estados internos dentro de cada modo para gerenciar as animações.
*   **Detecção de Borda (Edge Detection):** Implementada para o botão de mudança de modo, garantindo que um único clique avance apenas um estado, independentemente do tempo de pressão.
*   **Temporização Parametrizável:** O uso de chaves para selecionar entre diferentes limites de contagem permite alterar a velocidade das animações em tempo real.

---

### 2. Código VHDL Comentado

O código abaixo foi desenvolvido para a FPGA **MAX 10** (10M50DAF484C7G) da placa **DE10-Lite**.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity corsimcornao is
    generic (
        F_CLK : integer := 50_000_000 -- Clock nativo de 50 MHz
    );
    port (
        clk        : in  std_logic;                     -- PIN_P11
        rst_n      : in  std_logic;                     -- Botão KEY0 (Reset Assíncrono)
        mode_btn_n : in  std_logic;                     -- Botão KEY1 (Mudar Modo)
        enable     : in  std_logic;                     -- Chave SW0 (Pausar/Habilitar)
        speed_sel  : in  std_logic;                     -- Chave SW1 (Velocidade)
        leds       : out std_logic_vector(3 downto 0)   -- LEDs R1, R2, L1, L2
    );
end entity;

architecture comportamento of corsimcornao is
    -- Definição dos modos principais de operação
    type modo_type is (ACESO, INTERMITENTE, ALTERNADO, SEQUENCIAL);
    signal modo_atual, proximo_modo : modo_type;

    -- Sinais de temporização
    signal timer : integer range 0 to F_CLK := 0;
    signal limite_timer : integer;
    
    -- Sinais para detecção de borda no botão de modo
    signal mode_btn_reg : std_logic;
    
    -- Estado interno para as animações (0 a 3)
    signal sub_estado : integer range 0 to 3 := 0;

begin
    -- Seleção de velocidade: Lenta (~500ms) ou Rápida (~100ms)
    limite_timer <= F_CLK / 2 when speed_sel = '0' else F_CLK / 10;

    -- Registrador de Estados Principal e Detecção de Borda
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            modo_atual <= ACESO;
            mode_btn_reg <= '1';
        elsif rising_edge(clk) then
            mode_btn_reg <= mode_btn_n;
            -- Muda de modo apenas na descida do botão (pressionar), pois KEY é ativa em 0
            if mode_btn_reg = '1' and mode_btn_n = '0' then
                modo_atual <= proximo_modo;
            end if;
        end if;
    end process;

    -- Lógica de transição do modo principal
    process(modo_atual)
    begin
        case modo_atual is
            when ACESO        => proximo_modo <= INTERMITENTE;
            when INTERMITENTE  => proximo_modo <= ALTERNADO;
            when ALTERNADO    => proximo_modo <= SEQUENCIAL;
            when SEQUENCIAL   => proximo_modo <= ACESO;
        end case;
    end process;

    -- Timer e Lógica de Animação (Sub-estados)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timer <= 0;
            sub_estado <= 0;
        elsif rising_edge(clk) then
            if enable = '1' then -- Só conta se estiver habilitado
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

    -- Lógica de Saída (Máquina de Moore)
    -- LEDs: (3)=L2, (2)=L1, (1)=R2, (0)=R1
    process(modo_atual, sub_estado)
    begin
        case modo_atual is
            when ACESO =>
                leds <= "1111"; -- Todos acesos
            
            when INTERMITENTE =>
                -- Alterna dentro de cada chifre (R1/L1 vs R2/L2)
                if sub_estado mod 2 = 0 then leds <= "0101"; -- R1 e L1 on
                else leds <= "1010"; -- R2 e L2 on
                end if;
                
            when ALTERNADO =>
                -- Alterna entre os lados (Chifre R vs Chifre L)
                if sub_estado mod 2 = 0 then leds <= "0011"; -- R1 e R2 on
                else leds <= "1100"; -- L1 e L2 on
                end if;
                
            when SEQUENCIAL =>
                -- Acende um por vez: R1 -> R2 -> L1 -> L2
                case sub_estado is
                    when 0 => leds <= "0001"; -- R1
                    when 1 => leds <= "0010"; -- R2
                    when 2 => leds <= "0100"; -- L1
                    when 3 => leds <= "1000"; -- L2
                    when others => leds <= "0000";
                end case;
        end case;
    end process;

end architecture;
```

---

### 3. Texto Explicativo e Pinagem

1.  **Controle de Modos:** O botão `KEY1` atua como um gatilho para a FSM. Através da detecção de borda, o sistema percorre os quatro modos. O `Reset` (`KEY0`) retorna o sistema ao Modo 1 (Aceso) e limpa os contadores.
2.  **Habilitação e Pausa:** A chave `SW0` (`enable`) controla o incremento do timer. Quando em '0', a animação congela no estado atual, permitindo a funcionalidade de pausa solicitada.
3.  **Velocidade:** A chave `SW1` altera o divisor do clock. A velocidade "Lenta" define um ciclo de meio segundo entre mudanças, enquanto a "Rápida" reduz esse tempo para 100ms.
4.  **Pinagem Sugerida (Arquivo .qsf):**
    *   `clk`: PIN_P11
    *   `rst_n`: PIN_B8 (KEY0)
    *   `mode_btn_n`: PIN_A7 (KEY1)
    *   `enable`: PIN_C10 (SW0)
    *   `speed_sel`: PIN_C11 (SW1)
    *   `leds[0..3]`: PIN_A8, PIN_A9, PIN_A10, PIN_B10 (LEDR0 a LEDR3)

### 4. Diagrama RTL

Ao visualizar o diagrama RTL no Quartus (**Tools > Netlist Viewers > RTL Viewer**), o projetista observará:
*   Um bloco de **registrador de estado** (`modo_atual`) controlado pela lógica do botão.
*   Um **divisor de frequência** (comparador e acumulador) que gera o sinal de habilitação para a animação.
*   Uma rede de **multiplexadores de saída** que seleciona o padrão de bits dos LEDs com base no modo atual e no valor do sub-estado.
