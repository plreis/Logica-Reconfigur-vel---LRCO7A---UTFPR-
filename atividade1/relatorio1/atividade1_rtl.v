// Equivalente Verilog apenas para gerar diagrama RTL com yosys
module atividade1(
    input  a, b,
    output z1, z2, z3, z4, z5, z6, z7, z8
);
    assign z1 = ~a;       // NOT a
    assign z2 = ~b;       // NOT b
    assign z3 = a & b;    // AND
    assign z4 = a | b;    // OR
    assign z5 = ~(a & b); // NAND
    assign z6 = ~(a | b); // NOR
    assign z7 = a ^ b;    // XOR
    assign z8 = ~(a ^ b); // XNOR
endmodule
