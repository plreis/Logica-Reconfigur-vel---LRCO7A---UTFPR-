Este relatório detalha a implementação da **Atividade 7**, um timer regressivo com visualização em displays de 7 segmentos (SSD) e controle de interface, utilizando funções e processos sequenciais avançados.

### 1. Introdução

A atividade explora a integração de diversos conceitos de lógica reconfigurável para criar um sistema funcional completo:

*   **Divisão de Frequência:** Conversão do clock nativo de **50 MHz** (PIN_P11) para uma base de tempo de **1 Hz** (1 segundo), permitindo a contagem humana perceptível.
*   **BCD (Binary-Coded Decimal):** Representação de números decimais onde cada dígito é codificado por 4 bits. Isso é essencial para isolar unidades, dezenas e centenas para os SSDs.
*   **Algoritmo Double Dabble:** Um algoritmo eficiente de deslocamento e soma (shift-and-add-3) para converter números binários/inteiros em BCD, facilitando a exibição em sistemas decimais.
*   **Subprogramas (Functions):** Uso de funções VHDL para encapsular a lógica de decodificação de SSD e conversão BCD, promovendo o reuso de código e modularidade.
*   **Lógica de Controle:** Implementação de reset assíncrono e pausa utilizando os botões da placa (KEY0 e KEY1), que operam em lógica invertida (ativo em '0').

---

### 2. Código VHDL Comentado

O código abaixo foi desenvolvido para a FPGA **MAX 10** da placa **DE10-Lite**.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity atividade_7 is
    port (
        clk        : in  std_logic;                    -- Clock 50MHz (P11)
        rst_n      : in  std_logic;                    -- Botão KEY0 (Reset Assíncrono)
        pause_n    : in  std_logic;                    -- Botão KEY1 (Pausar)
        time_sel   : in  std_logic;                    -- Chave SW0 (Seleção de tempo)
        led_end    : out std_logic;                    -- LED de fim de contagem (LEDR0)
        hex0, hex1, hex2, hex3 : out std_logic_vector(6 downto 0) -- Displays SSD
    );
end entity;

architecture comportamento of atividade_7 is
    -- Função para converter BCD (4 bits) para padrão de 7 segmentos (Ativo em 0)
    function bcd_to_ssd(bcd : std_logic_vector(3 downto 0)) return std_logic_vector is
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
            when others => return "1111111"; -- Apagado
        end case;
    end function;

    -- Função que implementa o algoritmo Double Dabble para 4 dígitos BCD
    function bin_to_bcd(bin : integer range 0 to 9999) return std_logic_vector is
        variable bcd : unsigned(15 downto 0) := (others => '0');
        variable temp_bin : unsigned(13 downto 0);
    begin
        temp_bin := to_unsigned(bin, 14);
        for i in 0 to 13 loop
            -- Se qualquer dígito BCD for >= 5, adiciona 3
            for j in 0 to 3 loop
                if bcd(j*4+3 downto j*4) >= 5 then
                    bcd(j*4+3 downto j*4) := bcd(j*4+3 downto j*4) + 3;
                end if;
            end loop;
            -- Deslocamento à esquerda
            bcd := bcd sll 1;
            bcd(0) := temp_bin(13);
            temp_bin := temp_bin sll 1;
        end loop;
        return std_logic_vector(bcd);
    end function;

    signal seg_counter : integer range 0 to 50_000_000 := 0;
    signal current_time : integer range 0 to 9999 := 0;
    signal running     : boolean := true;
    signal bcd_val     : std_logic_vector(15 downto 0);

begin
    -- Processo do Timer
    process(clk, rst_n)
    begin
        if rst_n = '0' then -- Reset Assíncrono
            seg_counter <= 0;
            if time_sel = '1' then
                current_time <= 60; -- Opção 1: 60 segundos
            else
                current_time <= 15; -- Opção 2: 15 segundos
            end if;
            led_end <= '0';
            
        elsif rising_edge(clk) then
            -- Lógica de pausa (KEY1 pressionado para pausar)
            if pause_n = '1' then 
                if current_time > 0 then
                    if seg_counter >= 50_000_000 then
                        seg_counter <= 0;
                        current_time <= current_time - 1;
                    else
                        seg_counter <= seg_counter + 1;
                    end if;
                    led_end <= '0';
                else
                    led_end <= '1'; -- Acende LED ao chegar em zero
                end if;
            end if;
        end if;
    end process;

    -- Atribuição das saídas BCD e Displays
    bcd_val <= bin_to_bcd(current_time);
    
    hex0 <= bcd_to_ssd(bcd_val(3 downto 0));   -- Unidades
    hex1 <= bcd_to_ssd(bcd_val(7 downto 4));   -- Dezenas
    hex2 <= bcd_to_ssd(bcd_val(11 downto 8));  -- Centenas
    hex3 <= bcd_to_ssd(bcd_val(15 downto 12)); -- Milhares

end architecture;
```

---

### 3. Texto Explicativo e Pinagem

1.  **Reset e Pausa:** O sistema utiliza `rst_n` (KEY0) para reiniciar o timer. Se `time_sel` (SW0) estiver ativado, ele reseta para 60s; caso contrário, 15s. O sinal `pause_n` interrompe o incremento do `seg_counter`, efetivamente travando a contagem de tempo.
2.  **Double Dabble:** Esta função garante que o valor inteiro de segundos (ex: 15) seja quebrado em blocos de 4 bits para cada display (ex: `0001` e `0101`). O algoritmo percorre os bits do binário, adicionando 3 sempre que um dígito BCD atinge 5 ou mais antes do próximo deslocamento.
3.  **Saída SSD:** A função `bcd_to_ssd` converte cada bloco de 4 bits no código de segmentos necessário para a placa DE10-Lite, onde o bit '0' liga o segmento.
4.  **Pinagem Sugerida (QSF):**
    *   `clk`: PIN_P11
    *   `rst_n`: PIN_B8
    *   `pause_n`: PIN_A7
    *   `time_sel`: PIN_C10
    *   `led_end`: PIN_A8
    *   `hex0[0..6]`: PIN_C14, PIN_E15, PIN_C15, PIN_C16, PIN_E16, PIN_D17, PIN_C17.

### 4. Diagrama RTL

O diagrama RTL gerado apresentará:
*   Um **divisor de frequência** (comparador e acumulador) para gerar o pulso de 1 segundo.
*   Uma **unidade de contagem regressiva** com controle de habilitação (proveniente da lógica de pausa).
*   Um bloco combinacional complexo representando a função `bin_to_bcd`.
*   Quatro blocos decodificadores idênticos (`bcd_to_ssd`) conectando a lógica interna aos pinos de saída dos displays.
