// ============================================================================
// vga_controller.v (modificado)
// Gera sinal VGA 640x480@60Hz com barra vertical branca controlada pelo
// acelerômetro. cursor_x indica a coluna central da barra (0..639).
// ============================================================================

module vga_controller (
	iRST_n,
	iVGA_CLK,
	cursor_x,
	oBLANK_n,
	oHS,
	oVS,
	oVGA_B,
	oVGA_G,
	oVGA_R
);

input        iRST_n;
input        iVGA_CLK;
input  [9:0] cursor_x;      // coluna central da barra, 0..639
output reg   oBLANK_n;
output reg   oHS;
output reg   oVS;
output [3:0] oVGA_B;
output [3:0] oVGA_G;
output [3:0] oVGA_R;

wire cBLANK_n, cHS, cVS, rst;
reg [23:0] bgr_data;

// Contador de coluna dentro da área visível (0..639 por linha)
reg [9:0] col_cnt;

// Bordas da barra do cursor com saturação para evitar underflow/overflow
wire [9:0] cursor_left  = (cursor_x > 10'd2)   ? cursor_x - 10'd2 : 10'd0;
wire [9:0] cursor_right = (cursor_x < 10'd637)  ? cursor_x + 10'd2 : 10'd639;

assign rst = ~iRST_n;

// Gerador de sincronismo VGA (não modificado)
video_sync_generator LTM_ins (
	.vga_clk(iVGA_CLK),
	.reset(rst),
	.blank_n(cBLANK_n),
	.HS(cHS),
	.VS(cVS)
);

// ----------------------------------------------------------------
// Contador de coluna: reinicia a cada nova linha visível
// ----------------------------------------------------------------
always @(posedge iVGA_CLK or negedge iRST_n) begin
	if (!iRST_n)
		col_cnt <= 10'd0;
	else if (cBLANK_n) begin
		if (col_cnt == 10'd639)
			col_cnt <= 10'd0;
		else
			col_cnt <= col_cnt + 10'd1;
	end else
		col_cnt <= 10'd0;
end

// ----------------------------------------------------------------
// Geração de cor: barra branca sobre fundo cinza escuro
// ----------------------------------------------------------------
always @(posedge iVGA_CLK or negedge iRST_n) begin
	if (!iRST_n)
		bgr_data <= 24'h000000;
	else begin
		if (cBLANK_n) begin
			if (col_cnt >= cursor_left && col_cnt <= cursor_right)
				bgr_data <= 24'hFFFFFF;  // barra branca (cursor)
			else
				bgr_data <= 24'h202020;  // fundo cinza escuro
		end else
			bgr_data <= 24'h000000;
	end
end

// Mapeamento BGR → saídas VGA (4 bits mais significativos de cada canal)
assign oVGA_B = bgr_data[23:20];
assign oVGA_G = bgr_data[15:12];
assign oVGA_R = bgr_data[7:4];

// ----------------------------------------------------------------
// Pipeline de sincronismo: atrasa HS/VS/BLANK um ciclo para alinhar
// com os dados de cor (não modificado do original)
// ----------------------------------------------------------------
reg mHS, mVS, mBLANK_n;
always @(posedge iVGA_CLK) begin
	mHS      <= cHS;
	mVS      <= cVS;
	mBLANK_n <= cBLANK_n;
	oHS      <= mHS;
	oVS      <= mVS;
	oBLANK_n <= mBLANK_n;
end

endmodule
