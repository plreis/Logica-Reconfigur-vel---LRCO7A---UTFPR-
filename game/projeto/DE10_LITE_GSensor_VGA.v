// ============================================================================
// DE10_LITE_GSensor_VGA.v
// Projeto combinado: Acelerômetro (ADXL345) + VGA para DE10-Lite
//
// Funcionalidade:
//   - Lê eixo X do acelerômetro via SPI (mesmo comportamento do projeto GSensor)
//   - Exibe barra vertical branca no monitor VGA cuja posição horizontal
//     reflete a inclinação da placa
//   - LEDs continuam funcionando normalmente conforme projeto original GSensor
// ============================================================================

module DE10_LITE_GSensor_VGA (

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SDRAM (não utilizado, tied off) //////////
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// VGA //////////
	output		     [3:0]		VGA_B,
	output		     [3:0]		VGA_G,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		          		VGA_VS,

	//////////// Accelerometer //////////
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO,

	//////////// Arduino (não utilizado) //////////
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N
);

//=======================================================
//  Wires e Registradores
//=======================================================
wire        dly_rst;
wire        spi_clk, spi_clk_out;
wire [15:0] data_x;
wire        VGA_CTRL_CLK;

// CDC: sincronizador de dois estágios (domínio SPI → domínio VGA)
reg  [9:0]  accel_sync1, accel_sync2;

// Cálculo da posição do cursor em coordenadas de tela
wire signed [10:0] raw_signed;
wire signed [13:0] scaled;
wire signed [10:0] offset;
wire signed [10:0] cursor_x_pre;
wire        [9:0]  cursor_x_clamped;
reg         [9:0]  cursor_x_reg;

//=======================================================
//  SDRAM: tie off (não utilizado)
//=======================================================
assign DRAM_ADDR  = 13'b0;
assign DRAM_BA    = 2'b0;
assign DRAM_CAS_N = 1'b1;
assign DRAM_CKE   = 1'b0;
assign DRAM_CLK   = 1'b0;
assign DRAM_CS_N  = 1'b1;
assign DRAM_DQ    = 16'bz;
assign DRAM_LDQM  = 1'b1;
assign DRAM_RAS_N = 1'b1;
assign DRAM_UDQM  = 1'b1;
assign DRAM_WE_N  = 1'b1;

//=======================================================
//  Subsistema GSensor (idêntico ao projeto original)
//=======================================================

// Reset com delay para estabilização do PLL
reset_delay u_reset_delay (
	.iRSTN(KEY[0]),
	.iCLK(MAX10_CLK1_50),
	.oRST(dly_rst)
);

// PLL SPI: gera clock 2MHz para comunicação com acelerômetro
spi_pll u_spi_pll (
	.areset(dly_rst),
	.inclk0(MAX10_CLK1_50),
	.c0(spi_clk),       // 2MHz
	.c1(spi_clk_out)    // 2MHz defasado
);

// Leitura do acelerômetro via SPI
// data_x[9:0]: valor signed 10 bits do eixo X (complemento de dois)
spi_ee_config u_spi_ee_config (
	.iRSTN(!dly_rst),
	.iSPI_CLK(spi_clk),
	.iSPI_CLK_OUT(spi_clk_out),
	.iG_INT2(GSENSOR_INT[1]),
	.oDATA_L(data_x[7:0]),
	.oDATA_H(data_x[15:8]),
	.SPI_SDIO(GSENSOR_SDI),
	.oSPI_CSN(GSENSOR_CS_N),
	.oSPI_CLK(GSENSOR_SCLK)
);

// Driver de LEDs (comportamento original preservado)
led_driver u_led_driver (
	.iRSTN(!dly_rst),
	.iCLK(MAX10_CLK1_50),
	.iDIG(data_x[9:0]),
	.iG_INT2(GSENSOR_INT[1]),
	.oLED(LEDR)
);

//=======================================================
//  PLL VGA: gera clock ~25MHz para pixel clock
//=======================================================
vga_pll u_vga_pll (
	.areset(dly_rst),
	.inclk0(MAX10_CLK1_50),
	.c0(VGA_CTRL_CLK),
	.locked()
);

//=======================================================
//  CDC: sincroniza data_x do domínio SPI para domínio VGA
//  Dois flip-flops evitam metaestabilidade
//=======================================================
always @(posedge VGA_CTRL_CLK or posedge dly_rst) begin
	if (dly_rst) begin
		accel_sync1 <= 10'd0;
		accel_sync2 <= 10'd0;
	end else begin
		accel_sync1 <= data_x[9:0];
		accel_sync2 <= accel_sync1;
	end
end

//=======================================================
//  Mapeamento: aceleração signed 10-bit → coluna VGA 0..639
//
//  Fórmula: cursor_x = 320 + (raw * 320 / 512)
//                    = 320 + (raw * 5 / 8)
//
//  Verificação:
//    raw =    0 → cursor = 320 (centro, placa nivelada)
//    raw = +511 → cursor = 639 (extremo direito)
//    raw = -512 → cursor =   0 (extremo esquerdo)
//=======================================================
assign raw_signed   = {{1{accel_sync2[9]}}, accel_sync2}; // extensão de sinal p/ 11 bits
assign scaled       = raw_signed * $signed(5'd5);          // multiplica por 5 (resultado 14 bits)
assign offset       = scaled >>> 3;                        // divide por 8 (shift aritmético)
assign cursor_x_pre = $signed(11'd320) + offset;

// Clamping para garantir que fique dentro de [0, 639]
assign cursor_x_clamped =
	(cursor_x_pre < $signed(11'd0))   ? 10'd0   :
	(cursor_x_pre > $signed(11'd639)) ? 10'd639 :
	cursor_x_pre[9:0];

// Registra cursor_x no domínio VGA
always @(posedge VGA_CTRL_CLK or posedge dly_rst) begin
	if (dly_rst)
		cursor_x_reg <= 10'd320; // inicia no centro
	else
		cursor_x_reg <= cursor_x_clamped;
end

//=======================================================
//  Controlador VGA
//=======================================================
vga_controller vga_ins (
	.iRST_n(KEY[0]),
	.iVGA_CLK(VGA_CTRL_CLK),
	.cursor_x(cursor_x_reg),
	.oHS(VGA_HS),
	.oVS(VGA_VS),
	.oVGA_B(VGA_B),
	.oVGA_G(VGA_G),
	.oVGA_R(VGA_R)
);

endmodule
