// Part 2 skeleton
module moleAnimation
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		SW,
		HEX0,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input [2:0] SW;
	output [6:0] HEX0;
	
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = SW[1:0];
	wire add_minus_score;
	assign add_minus_score = KEY[3];
	wire display;
	assign display = HEX0[6:0];
	wire startButton;
	assign startButton = KEY[0];

	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	wire [5:0] plotCounter;
	wire [7:0] xCounter;
	wire plot, erase, plotEn, update, reset;
	wire [6:0] yCounter;
	wire [25:0] freq;
	wire [3:0] score;
	wire drawMenuScreen;
	wire drawGameScreen;
	wire drawGameOverScreen;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "whacamoleback.mif";
			
		gameState(CLOCK_50, SW[1:0], KEY[0], score, drawn, drawMenuScreen, drawGameScreen, drawGameOverScreen);
		datapath(CLOCK_50, SW[1:0], writeEn, colour, x, y, drawn, drawMenuScreen, drawGameScreen, drawGameOverScreen);
		scoreCounter u2(CLOCK_50, SW[1:0], score, KEY[3]);
		hex_decoder u3(score, HEX0[6:0]); 
		

	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
	
endmodule


module gameState(Clock, Reset, startButton, score, drawn,drawMenuScreen, drawGameScreen, drawGameOverScreen);
    input Clock;
    input Reset;
    input startButton;
    input [3:0] score;

    localparam START_SCREEN = 4'd0,
    START_SCREEN_WAIT = 4'd1,
    GAME_START = 4'd2,
    GAME_OVER = 4'd3,
    GAME_OVER_WAIT = 4'd4;
	 
	 output reg drawMenuScreen;
	 output reg drawGameScreen;
	 output reg drawGameOverScreen;

    reg [3:0] current_state, next_state;

    always @(*)
    begin: state_table
    case (current_state)
        START_SCREEN: next_state = startButton ? START_SCREEN_WAIT : START_SCREEN;
        START_SCREEN_WAIT: next_state = startButton ? START_SCREEN_WAIT : GAME_START;
        GAME_START: next_state = score == 0 ? GAME_OVER : GAME_START;
        GAME_OVER: next_state = startButton ? GAME_OVER_WAIT : GAME_OVER;
        GAME_OVER_WAIT: next_state = startButton ? GAME_OVER_WAIT : START_SCREEN;
        default: next_state = START_SCREEN;
    endcase
	 end

	 always @(*)
	 begin: enable_signals
		drawMenuScreen = 1'b0;
		drawGameScreen = 1'b0;
		drawGameOverScreen = 1'b0;
		case (current_state)
			START_SCREEN: begin
				drawMenuScreen = 1'b1;
			end
			GAME_START: begin
				drawGameScreen = 1'b1;
			end
			GAME_OVER: begin
				drawGameOverScreen = 1'b1;
			end
			
		endcase
		end
		
	 
    always @(posedge Clock)
    begin: state_flipflop
            current_state <= next_state;
    end
         
endmodule


module datapath(clock, reset, plot, colour, x_out, y_out, drawn, drawMenuScreen, drawGameScreen, drawGameOverScreen);
input clock;
input reset;

output reg plot;
output reg[8:0] colour;
output reg [7:0] x_out;
output reg [6:0] y_out;

wire [7:0]xCoor;
wire [6:0]yCoor;
wire [8:0]outColour;

input drawMenuScreen;
input drawGameScreen;
input drawGameOverScreen;
wire drawn;

displayDataPath(clock, reset, xCoor, yCoor, outColour, drawMenuScreen, drawGameScreen, drawGameOverScreen);

	always @(*)
	begin
		if(reset)
		begin
			plot <= 0;
			colour <= 1'b0;
			x_out <= 1'b0;
			y_out <= 1'b0;
		end
		else if(drawMenuScreen || drawGameScreen || drawGameOverScreen)
		begin
			x_out <= xCoor;
			y_out <= yCoor;
			colour <= outColour;
			plot <= 1'b1;
		end
	end
	
endmodule





module displayDataPath(clock, reset, xCoor, yCoor, outColour, drawn, drawMenuScreen, drawGameScreen, drawGameOverScreen);
input clock;
input reset;
output reg [7:0] xCoor;
output reg [6:0] yCoor;
output reg [8:0] outColour;
output reg drawn;
input drawMenuScreen;
input drawGameScreen;
input drawGameOverScreen;
reg [8:0] xCounter, yCounter;
wire [16:0] backgroundAddress;
wire [10:0] menuColor, gameColor, gameOverColor;
assign backgroundAddress = xCoor + (yCoor*160);

menu b0(backgroundAddress, clock, menuColor);
gamebackground b1(backgroundAddress, clock, gameColor);
gameover b2(backgroundAddress, clock, gameOverColor);

	always @(posedge clock)
	begin
		if(reset)
		begin
			xCoor <= 8'b0;
			yCoor <= 7'b0;
			outColour <= 9'b0;
			drawn <= 1'b0;
		end
		else if(drawMenuScreen || drawGameScreen || drawGameOverScreen)
		begin
			if((120 * 160 -1) <= xCoor + (yCoor*160))
			begin
				xCoor <= 8'b0;
				yCoor <= 7'b0;
				drawn <= 1'b1;
			end

			else if((120 * 160 -1) > xCoor + (yCoor*160))
			begin
				drawn <= 1'b0;
				if(xCoor < 9'd159)
				begin
					xCoor <= xCoor + 1;
				end
				else if(yCoor < 9'd119 && xCoor == 9'd159)
				begin
					xCoor <= 8'b0;
					yCoor <= yCoor + 1;
				end
			end

			if(drawMenuScreen)
				outColour <= menuColor;
			else if(drawGameScreen)
				outColour <= gameColor;
			else if(drawGameOverScreen)
				outColour <= gameOverColor;

		end
	end
endmodule


				
module scoreCounter(clock, reset, score, add_minus_score);
    input clock, reset, add_minus_score;
    output reg [3:0] score;

    always @(posedge clock)
    begin
        if (reset)
           score <= 0;
        else if (add_minus_score)
           score <= score + 1;
    end

endmodule


module hex_decoder(c,display);
input [3:0] c;
output [6:0] display;

assign display[0] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & c[3]) | (c[0] & ~c[1] & c[2] & c[3]);
assign display[1] = (c[0] & ~c[1] & c[2] & ~c[3]) | (~c[0] & c[1] & c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & c[3]) | (~c[0] & ~c[1] & c[2] & c[3]) | (~c[0] & c[1] & c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
assign display[2] = (~c[0] & c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & c[3]) | (~c[0] & c[1] & c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
assign display[3] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & c[3]) | (~c[0] & c[1] & ~c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
assign display[4] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & c[3]);
assign display[5] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & c[2] & c[3]);
assign display[6] = (~c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & c[3]);

endmodule
