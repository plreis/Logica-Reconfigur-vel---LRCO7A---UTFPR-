library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package meupacote is
    -- Definição de tipo array de std_logic_vector conforme pedido
    type slv_array is array (natural range <>) of unsigned;
    
    -- Definição de tipo array de integer conforme pedido
    type int_array is array (natural range <>) of integer;

    -- Procedimento para encontrar min e max em um array de inteiros
    procedure detector_min_max (
        signal entrada : in  int_array;
        signal min_val : out integer;
        signal max_val : out integer
    );
end package meupacote;

package body meupacote is
    procedure detector_min_max (
        signal entrada : in  int_array;
        signal min_val : out integer;
        signal max_val : out integer
    ) is
        variable v_min : integer;
        variable v_max : integer;
    begin
        -- Inicializa com o primeiro elemento
        v_min := entrada(entrada'low);
        v_max := entrada(entrada'low);
        
        -- Loop para percorrer o array e comparar valores
        for i in entrada'range loop
            if entrada(i) < v_min then
                v_min := entrada(i);
            end if;
            if entrada(i) > v_max then
                v_max := entrada(i);
            end if;
        end loop;
        
        -- Atribui os resultados das variáveis aos sinais de saída
        min_val <= v_min;
        max_val <= v_max;
    end procedure;
end package body meupacote;