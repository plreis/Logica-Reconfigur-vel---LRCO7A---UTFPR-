# 1. Configura o Clock (50MHz = período de 20ns)
force -deposit /accel_vga_top/MAX10_CLK1_50 1 0, 0 {10 ns} -r 20 ns

# 2. Configura botões padrão (não apertados = 1)
force -deposit /accel_vga_top/KEY 2#11

# 3. Dá o pulso de Reset pelo KEY(0) (ativo baixo)
force -deposit /accel_vga_top/KEY 2#10
run 100 ns
force -deposit /accel_vga_top/KEY 2#11
run 100 ns

# 4. Força os sinais internos com freeze para não serem sobrescritos pelo SPI
force -freeze /accel_vga_top/accel_valid 1
force -freeze /accel_vga_top/accel_x 16#0000
run 20 ms

# 5. Simula inclinando a placa para a Direita (valor positivo hexadecimal)
force -freeze /accel_vga_top/accel_x 16#00A0
run 25 ms

# 6. Simula inclinando a placa para a Esquerda (valor negativo em complemento de 2)
force -freeze /accel_vga_top/accel_x 16#FF50
run 25 ms

# 7. Volta para o centro para fechar o ciclo visual
force -freeze /accel_vga_top/accel_x 16#0000
run 20 ms