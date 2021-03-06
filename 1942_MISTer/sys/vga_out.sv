
module vga_out
(
	input         clk_sys,

	input         io_uio,
	input         io_strobe,
	input   [7:0] io_din,
	

	input         ypbpr_full,
	input  [23:0] din,
	output [23:0] dout,
	output        scaler,
	output        csync
);

reg [7:0] cfg;
wire ypbpr_en = cfg[5];
assign csync  = cfg[3];
assign scaler = cfg[2];

always@(posedge clk_sys) begin
	reg  [7:0] cmd;
	reg        has_cmd;
	reg        old_strobe;

	old_strobe <= io_strobe;

	if(~io_uio) has_cmd <= 0;
	else if(~old_strobe & io_strobe) begin
			if(!has_cmd) begin
				has_cmd <= 1;
				cmd <= io_din;
			end else begin
				if(cmd == 1) cfg <= io_din;
			end
	end
end

wire [5:0] yuv_full[225] = '{
  6'd0,   6'd0,  6'd0,  6'd0,  6'd1,  6'd1,  6'd1,  6'd1,
  6'd2,   6'd2,  6'd2,  6'd3,  6'd3,  6'd3,  6'd3,  6'd4,
  6'd4,   6'd4,  6'd5,  6'd5,  6'd5,  6'd5,  6'd6,  6'd6,
  6'd6,   6'd7,  6'd7,  6'd7,  6'd7,  6'd8,  6'd8,  6'd8,
  6'd9,   6'd9,  6'd9,  6'd9, 6'd10, 6'd10, 6'd10, 6'd11,
  6'd11, 6'd11, 6'd11, 6'd12, 6'd12, 6'd12, 6'd13, 6'd13,
  6'd13, 6'd13, 6'd14, 6'd14, 6'd14, 6'd15, 6'd15, 6'd15,
  6'd15, 6'd16, 6'd16, 6'd16, 6'd17, 6'd17, 6'd17, 6'd17,
  6'd18, 6'd18, 6'd18, 6'd19, 6'd19, 6'd19, 6'd19, 6'd20,
  6'd20, 6'd20, 6'd21, 6'd21, 6'd21, 6'd21, 6'd22, 6'd22,
  6'd22, 6'd23, 6'd23, 6'd23, 6'd23, 6'd24, 6'd24, 6'd24,
  6'd25, 6'd25, 6'd25, 6'd25, 6'd26, 6'd26, 6'd26, 6'd27,
  6'd27, 6'd27, 6'd27, 6'd28, 6'd28, 6'd28, 6'd29, 6'd29,
  6'd29, 6'd29, 6'd30, 6'd30, 6'd30, 6'd31, 6'd31, 6'd31,
  6'd31, 6'd32, 6'd32, 6'd32, 6'd33, 6'd33, 6'd33, 6'd33,
  6'd34, 6'd34, 6'd34, 6'd35, 6'd35, 6'd35, 6'd35, 6'd36,
  6'd36, 6'd36, 6'd36, 6'd37, 6'd37, 6'd37, 6'd38, 6'd38,
  6'd38, 6'd38, 6'd39, 6'd39, 6'd39, 6'd40, 6'd40, 6'd40,
  6'd40, 6'd41, 6'd41, 6'd41, 6'd42, 6'd42, 6'd42, 6'd42,
  6'd43, 6'd43, 6'd43, 6'd44, 6'd44, 6'd44, 6'd44, 6'd45,
  6'd45, 6'd45, 6'd46, 6'd46, 6'd46, 6'd46, 6'd47, 6'd47,
  6'd47, 6'd48, 6'd48, 6'd48, 6'd48, 6'd49, 6'd49, 6'd49,
  6'd50, 6'd50, 6'd50, 6'd50, 6'd51, 6'd51, 6'd51, 6'd52,
  6'd52, 6'd52, 6'd52, 6'd53, 6'd53, 6'd53, 6'd54, 6'd54,
  6'd54, 6'd54, 6'd55, 6'd55, 6'd55, 6'd56, 6'd56, 6'd56,
  6'd56, 6'd57, 6'd57, 6'd57, 6'd58, 6'd58, 6'd58, 6'd58,
  6'd59, 6'd59, 6'd59, 6'd60, 6'd60, 6'd60, 6'd60, 6'd61,
  6'd61, 6'd61, 6'd62, 6'd62, 6'd62, 6'd62, 6'd63, 6'd63,
  6'd63
};

wire [5:0] red   = din[23:18];
wire [5:0] green = din[15:10];
wire [5:0] blue  = din[7:2];

// http://marsee101.blog19.fc2.com/blog-entry-2311.html
// Y  =  16 + 0.257*R + 0.504*G + 0.098*B (Y  =  0.299*R + 0.587*G + 0.114*B)
// Pb = 128 - 0.148*R - 0.291*G + 0.439*B (Pb = -0.169*R - 0.331*G + 0.500*B)
// Pr = 128 + 0.439*R - 0.368*G - 0.071*B (Pr =  0.500*R - 0.419*G - 0.081*B)

wire [18:0]  y_8 = 19'd04096 + ({red, 8'd0} + {red, 3'd0}) + ({green, 9'd0} + {green, 2'd0}) + ({blue, 6'd0} + {blue, 5'd0} + {blue, 2'd0});
wire [18:0] pb_8 = 19'd32768 - ({red, 7'd0} + {red, 4'd0} + {red, 3'd0}) - ({green, 8'd0} + {green, 5'd0} + {green, 3'd0}) + ({blue, 8'd0} + {blue, 7'd0} + {blue, 6'd0});
wire [18:0] pr_8 = 19'd32768 + ({red, 8'd0} + {red, 7'd0} + {red, 6'd0}) - ({green, 8'd0} + {green, 6'd0} + {green, 5'd0} + {green, 4'd0} + {green, 3'd0}) - ({blue, 6'd0} + {blue , 3'd0});

wire [7:0] y  = ( y_8[17:8] < 16) ? 8'd16 : ( y_8[17:8] > 235) ? 8'd235 :  y_8[15:8];
wire [7:0] pb = (pb_8[17:8] < 16) ? 8'd16 : (pb_8[17:8] > 240) ? 8'd240 : pb_8[15:8];
wire [7:0] pr = (pr_8[17:8] < 16) ? 8'd16 : (pr_8[17:8] > 240) ? 8'd240 : pr_8[15:8];

assign dout[23:16] = ypbpr_en ? {(ypbpr_full ? yuv_full[pr-8'd16] : pr[7:2]), 2'b00} : din[23:16];
assign dout[15:8]  = ypbpr_en ? {(ypbpr_full ? yuv_full[y -8'd16] :  y[7:2]), 2'b00} : din[15:8];
assign dout[7:0]   = ypbpr_en ? {(ypbpr_full ? yuv_full[pb-8'd16] : pb[7:2]), 2'b00} : din[7:0];


endmodule
