library ieee ;
use ieee . std_logic_1164 .all ;

entity atividade2 is
port (
chave1 : in bit ; -- SW0 : chave 1
chave2 : in bit ; -- SW1 : chave 2
chave3 : in bit ; -- SW2 : chave 3
chave4 : in bit ; -- SW3 : chave 4
z : out bit -- LEDR0 : saida
) ;
end entity ;

architecture dataflow of atividade2 is
begin
-- Equacao simplificada via Karnaugh
-- ( todas as combinacoes de 2 chaves , exceto
-- SW1 . SW4 que e don ’t care )
z <= ( chave1 and chave2 ) or
( chave1 and chave3 ) or
( chave2 and chave3 ) or
( chave2 and chave4 ) or
( chave3 and chave4 );
end architecture ;