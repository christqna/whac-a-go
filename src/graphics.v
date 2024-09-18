// Part 2 skeleton

module VGA
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		SW,
        	PS2_CLK,
        	PS2_DAT,
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
    	input [1:0] SW;
    	input PS2_CLK;
    	input PS2_DAT;
	wire resetn;
	assign resetn = SW[0];
	wire writeEn;
	reg [8:0] colour;
	reg [7:0] x;
	reg [6:0] y;
	
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
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(~resetn),
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
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.

    wire ifPressed;
    wire [1:0] keyPressed;

	 wire writeBackground, writeFirstMole, writeSecondMole, writeThirdMole, writeLastMole, writeGameOver;
	 assign writeEn = (writeBackground || writeFirstMole || writeSecondMole || writeThirdMole || writeLastMole || writeGameOver);
	 
	 
    wire drawGameBackground;
	 wire drawFirstMole;
	 wire drawSecondMole;
	 wire drawThirdMole;
	 wire drawLastMole;
	 wire drawGameOver;

    assign drawGameBackground = generated;
	 assign drawFirstMole = 0;
	 assign drawSecondMole = 0;
	 assign drawThirdMole = 0;
	 assign drawLastMole = 0;
	 assign drawGameOver = KEY[1];

    wire gameOver;
    assign gameOver = KEY[2];
	 
	 
	 wire done_draw;
	 wire done_draw2;
	 wire done_draw3;
	 wire done_draw4;
	 wire done_draw5;
	 wire done_draw6;

	 
	 wire [8:0] gameBackgroundColour;
	 wire [7:0] gameBackgroundX;
	 wire [6:0] gameBackgroundY;
	 
	 wire [8:0] firstMoleColour;
	 wire [7:0] firstMoleX;
	 wire [6:0] firstMoleY;
		 
	 wire [8:0] secondMoleColour;
	 wire [7:0] secondMoleX;
	 wire [6:0] secondMoleY;
	 
	 		 
	 wire [8:0] thirdMoleColour;
	 wire [7:0] thirdMoleX;
	 wire [6:0] thirdMoleY;
	 
	 		 
	 wire [8:0] lastMoleColour;
	 wire [7:0] lastMoleX;
	 wire [6:0] lastMoleY;
	 
	 		 
	 wire [8:0] gameOverColour;
	 wire [7:0] gameOverX;
	 wire [6:0] gameOverY;
	 
	 wire generated;
	 wire enable;
	 assign enable = SW[1];
	 
	wire shrink;
	assign shrink = 0;
	
	
	always@(*)
	begin
		if(drawGameBackground)
		begin
			colour <= gameBackgroundColour;
			x <= gameBackgroundX;
			y<= gameBackgroundY;
		end
		else if(drawFirstMole)
		begin
			colour <= firstMoleColour;
			x <= firstMoleX;
			y <= firstMoleY;
		end
		else if(generated && drawSecondMole)
		begin
			colour <= secondMoleColour;
			x <= secondMoleX;
			y <= secondMoleY;
		end
		else if(generated && drawThirdMole)
		begin
			colour <= thirdMoleColour;
			x <= thirdMoleX;
			y <= thirdMoleY;
		end
		else if(!drawLastMole)
		begin
			colour <= lastMoleColour;
			x <= lastMoleX;
			y <= lastMoleY;
		end
		else if(!drawGameOver)
		begin
			colour <= gameOverColour;
			x <= gameOverX;
			y <= gameOverY;
		end
	end
	
	 
   backgroundRom(.clock(CLOCK_50), .resetn(gameOver), .drawGameBackground(drawGameBackground), .out_colour(gameBackgroundColour), .x_coor(gameBackgroundX), .y_coor(gameBackgroundY), .writeEn(writeBackground), .done_draw(done_draw));
	firstMoleRom(CLOCK_50, gameOver, drawFirstMole, firstMoleColour, firstMoleX, firstMoleY, writeFirstMole, done_draw2);
	secondMoleRom(CLOCK_50, gameOver, drawSecondMole, secondMoleColour, secondMoleX, secondMoleY, writeSecondMole, done_draw3);
	thirdMoleRom(CLOCK_50, gameOver, drawThirdMole, thirdMoleColour, thirdMoleX, thirdMoleY, writeThirdMole, done_draw4);
	lastMoleRom(CLOCK_50, gameOver, drawLastMole, lastMoleColour, lastMoleX, lastMoleY, writeLastMole, done_draw5);
	gameOverRom(CLOCK_50, gameOver, drawGameOver, gameOverColour, gameOverX, gameOverY, writeGameOver, done_draw6);
   ps2Keyboard(PS2_CLK, PS2_DAT, resetn, ifPressed, keyPressed, CLOCK_50);
	hi( generated, resetn, enable, CLOCK_50, timeUp);
	timeCount(timeUp, CLOCK_50, timer, resetn, enable, shrink, ifPressed, pressedInTime);
	
	
endmodule

module backgroundRom (clock, resetn, drawGameBackground, out_colour, x_coor, y_coor, writeEn, done_draw);
    input clock, resetn, drawGameBackground;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
				done_draw <= 1'b0;
				writeEn <= 1'b0;
        end

        if(drawGameBackground && !done_draw)
        begin
		      writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    gamebackground b0(address, clock, colour);

endmodule

module firstMoleRom (clock, resetn, drawFirstMole, out_colour, x_coor, y_coor, writeEn, done_draw2);
    input clock, resetn, drawFirstMole;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw2;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
			done_draw2 <= 1'b0;
			writeEn <= 1'b0;
        end

        if(drawFirstMole && !done_draw2)
        begin
		    writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw2 <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    firstmole b1(address, clock, colour);

endmodule
    
module secondMoleRom (clock, resetn, drawSecondMole, out_colour, x_coor, y_coor, writeEn, done_draw3);
    input clock, resetn, drawSecondMole;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw3;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
			done_draw3 <= 1'b0;
			writeEn <= 1'b0;
        end

        if(drawSecondMole && !done_draw3)
        begin
		    writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw3 <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    secondmole b2(address, clock, colour);

endmodule
    

module thirdMoleRom (clock, resetn, drawThirdMole, out_colour, x_coor, y_coor, writeEn, done_draw4);
    input clock, resetn, drawThirdMole;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw4;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
			done_draw4 <= 1'b0;
			writeEn <= 1'b0;
        end

        if(drawThirdMole && !done_draw4)
        begin
		    writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw4 <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    thirdmole b3(address, clock, colour);

endmodule
    

module lastMoleRom (clock, resetn, drawLastMole, out_colour, x_coor, y_coor, writeEn, done_draw5);
    input clock, resetn, drawLastMole;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw5;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
			done_draw5 <= 1'b0;
			writeEn <= 1'b0;
        end

        if(!drawLastMole && !done_draw5)
        begin
		    writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw5 <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    lastmole b4(address, clock, colour);

endmodule


module gameOverRom (clock, resetn, drawGameOver, out_colour, x_coor, y_coor, writeEn, done_draw6);
    input clock, resetn, drawGameOver;
    output reg [8:0] out_colour;
    output  [7:0] x_coor;
    output  [6:0] y_coor;
    output reg writeEn, done_draw6;

    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [16:0] address;

    wire [8:0] colour;

    always@(posedge clock)
    begin
        if(!resetn)
        begin   
            x_counter <= 8'b0;
            y_counter <= 7'b0;
            out_colour <= 9'b0;
            address <= 17'b0;
			done_draw6 <= 1'b0;
			writeEn <= 1'b0;
        end

        if(!drawGameOver && !done_draw6)
        begin
		    writeEn <= 1'b1;
            out_colour <= colour;
            address <= address + 1;
            if(x_counter < 159)
                x_counter <= x_counter + 1;
            else if(x_counter == 159 && y_counter < 119)
            begin
                x_counter <= 8'b0;
                y_counter <= y_counter + 1;
            end
            else if(x_counter == 159 && y_counter == 119)
            begin
                writeEn <= 1'b0;
					 done_draw6 <= 1'b1;
            end
        end
    end
    
    assign x_coor = x_counter;
    assign y_coor = y_counter;

    //call the rom here
    gameover b5(address, clock, colour);

endmodule
    



module hi (generated, reset, enable, systemClock, timeUp);
input enable, reset, systemClock, timeUp;
output reg generated;
localparam start = 4'd0,
off = 4'd1,
waitH = 4'd2,
waitL = 4'd3,
pulseOn = 4'd4,
pulseOff = 4'd5;

reg [3:0] current, next;

// next state logic

always @(posedge systemClock)
begin 
case(current)
off: next = enable? start : off;
start: next = enable? waitH : off;
waitH: begin 
if (!enable)
next = off;
else
next = timeUp ? waitL : waitH;
end 
waitL : begin 
if (!enable)
next = off;
else 
next = timeUp ? waitL: pulseOn;
end 
pulseOn : next = enable? pulseOff: off;
pulseOff : next =enable? waitH: off;
endcase
end

//output logic 
always @(*)
begin 
if (reset || !enable)
begin 
generated = 0;
end 
else 
generated <= 0;
case (current)
pulseOn: generated <= 1'd1;
pulseOff: generated <= 1'd1;
endcase
end 
// state transition
always @(systemClock)
begin 
if(reset)
current <= start;
else 
current <= next;
end
endmodule
