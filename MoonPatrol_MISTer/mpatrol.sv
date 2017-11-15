`timescale 1 ns / 1 ps
`default_nettype none

module emu
(
	input         CLK_50M,
	input         RESET,
	inout  [37:0] HPS_BUS,
	output        CLK_VIDEO,
	output        CE_PIXEL,
	output [ 7:0] VIDEO_ARX,
	output [ 7:0] VIDEO_ARY,
	output [ 7:0] VGA_R,
	output [ 7:0] VGA_G,
	output [ 7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        LED_USER,  // 1 - ON, 0 - OFF.
	output [ 1:0] LED_POWER,
	output [ 1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	input         TAPE_IN,
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output [ 7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output [ 7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output [ 1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE
);
//Deactivate unused DDR and SDRAM
assign {DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE, DDRAM_CLK} = 0;
assign {SDRAM_CLK, SDRAM_CKE, SDRAM_A, SDRAM_BA, SDRAM_DQ, SDRAM_DQML, SDRAM_DQMH, SDRAM_nCS, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nWE} = 0;

assign VIDEO_ARX = status[4] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[4] ? 8'd9  : 8'd3;


assign AUDIO_S 	= 1;
assign LED_DISK  	= 0;
assign LED_POWER 	= 0;
//assign LED_USER  	= 0;

//assign VGA_DE  	= 1;

wire [31:0] status;

`include "build_id.v"
localparam CONF_STR = 
{
// Change Game in platform_variant_pkg
	"MPatrol;;",
	"T1,Insert Coin	(ESC);",
	"T2,Start Player 	 (1) ;",
	"T3,Start Player 	 (2) ;",
	"O4,Aspect ratio,4:3,16:9;",
	"T5,Reset;",
	"V,v1.02 by PACE Dev, Mister port by Gehstock Build ",`BUILD_DATE
};

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys					(CLK_50M			),
	.HPS_BUS					(HPS_BUS			),
	.conf_str				(CONF_STR		),
	.ps2_kbd_clk			(ps2_kbd_clk	),
	.ps2_kbd_data			(ps2_kbd_data	),
	.ps2_kbd_led_use		(0					),
	.ps2_kbd_led_status	(0					),	
	.joystick_0 			(joystick_0		),
	.joystick_1 			(joystick_1		),
	.buttons		 			(buttons			),
	.status					(status			)
);



wire clk, pixel_clock, locked;
assign CLK_VIDEO = pixel_clock;
assign CE_PIXEL  = 1;

wire rst_n;
defparam my_reset.RST_CNT_SIZE = 16;
resetter my_reset
	(
	.clk					(pixel_clock	),
	.rst_in_n			( ~RESET & locked ),
	.rst_out_n			(rst_n			)
	);


wire [7:0] joystick_0, JOY_0;
wire [7:0] joystick_1, JOY_1;
wire 		  ps2_kbd_clk, ps2_kbd_data;
wire [1:0] buttons;


target_top mpatrol
(
	.CLK_50M				(CLK_50M 		),
	.LED  				(LED_USER		),
	.AUDIO_L				(AUDIO_L			),
	.AUDIO_R				(AUDIO_R			),
	.VGA_R				(VGA_R			),
	.VGA_G				(VGA_G			),
	.VGA_B				(VGA_B			),
	.VGA_VS				(VGA_VS			),
	.VGA_HS				(VGA_HS			),
	.VGA_DE				(VGA_DE			),
	.pixel_clock		(pixel_clock	),
	.ps2clk				(ps2_kbd_clk	),
	.ps2data				(ps2_kbd_data	),
	.joystick1			(joystick_0		),
	.joystick2			(joystick_1		),
	.status		 		(status			),
	.buttons				(buttons			),
	.reset				(rst_n			)
	);


endmodule
