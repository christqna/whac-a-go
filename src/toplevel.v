module toplevel (
    SW, LEDR, HEX0, HEX1, HEX2, HEX4, PS2_CLK, PS2_DAT, CLOCK_50, 
    AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, 
    AUD_DACDAT, FPGA_I2C_SCLK, AUD_ADCDAT
);
    input [1:0] SW;
    output [6:0] HEX0, HEX1, HEX2, HEX4;
    output [1:0] LEDR;
    input PS2_CLK, PS2_DAT, CLOCK_50, AUD_ADCDAT;
    inout AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT;
    output AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK;

    wire [3:0] display0, display2, display4, display1;
    wire [3:0] timer;
    wire [1:0] mole;
    wire enable;
    wire W;
    assign LEDR[0] = timeUp;
    wire add_score, minus_score, timeUp;
    wire [3:0] score, current;
    
    assign display1 = current;
    assign display0 = score;
    assign display2 = timer;
    assign display4 = {2'b00, mole};
    wire startSwitch;
    assign startSwitch = SW[1];

    Test u0 (
        .reset(SW[0]), .W(W), .mole(mole), .timeUp(timeUp), 
        .systemClock(CLOCK_50), .ps2Clck(PS2_CLK), .ps2Data(PS2_DAT), 
        .timer(timer), .enable(enable), .AUD_DACLRCK(AUD_DACLRCK), 
        .AUD_BCLK(AUD_BCLK), .AUD_ADCLRCK(AUD_ADCLRCK), 
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT), .AUD_XCK(AUD_XCK), 
        .AUD_DACDAT(AUD_DACDAT), .FPGA_I2C_SCLK(FPGA_I2C_SCLK), 
        .AUD_ADCDAT(AUD_ADCDAT)
    );

    hex_decoder dis0 (display0, HEX0);
    hex_decoder dis2 (display2, HEX2);
    hex_decoder dis4 (display4, HEX4);
    hex_decoder dis1 (display1, HEX1);

    itgrn intgr (
        .timeUp(timeUp), .systemClock(CLOCK_50), .current_state(current), 
        .reset(SW[0]), .SCORE(score), .startSwitch(startSwitch), 
        .enable(enable), .W(W)
    );
endmodule


module Test (
    AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, 
    AUD_DACDAT, FPGA_I2C_SCLK, reset, systemClock, ps2Clck, ps2Data, 
    enable, timer, AUD_ADCDAT, mole, timeUp, W
);
    input reset, systemClock, ps2Clck, ps2Data, enable;
    output timeUp;
    output [1:0] mole;
    input AUD_ADCDAT;
    output [3:0] timer;
    output AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK;
    inout AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT;

    wire ifPressed;
    wire pressedInTime;
    output W;
    wire [1:0] keyPressed;
    wire shrink;

    timeCount counter (
        .systemClock(systemClock), .reset(reset), .shrink(shrink), 
        .timeUp(timeUp), .timer(timer), .ifPressed(ifPressed), 
        .enable(enable), .pressedInTime(pressedInTime)
    );

    ps2Keyboard keyboard (
        .ps2clock(ps2Clck), .ps2data(ps2Data), .reset(reset), 
        .ifPressed(ifPressed), .keyPressed(keyPressed), 
        .CLOCK_50(systemClock)
    );

    FSMscore fsmS (
        .timeUp(timeUp), .W(W), .reset(reset), .add_score(add_score), 
        .minus_score(minus_score), .shrink(shrink), .enable(enable), 
        .systemClock(systemClock)
    );

    ifScore scr (
        .keyPressed(keyPressed), .mole(mole), .W(W), .reset(reset), 
        .pressedInTime(pressedInTime), .timeUp(timeUp)
    );

    Random R (
        .timeUp(timeUp), .reset(reset), .mole(mole), .enable(enable)
    );

    DE1_SoC_Audio_Example audio (
        .CLOCK_50(systemClock), .AUD_ADCDAT(AUD_ADCDAT), .enable(enable), 
        .W(W), .reset(reset), .timeUp(timeUp), .AUD_BCLK(AUD_BCLK), 
        .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_DACLRCK(AUD_DACLRCK), 
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT), .AUD_XCK(AUD_XCK), 
        .AUD_DACDAT(AUD_DACDAT), .FPGA_I2C_SCLK(FPGA_I2C_SCLK)
    );
endmodule


module hex_decoder(c, display);
    input [3:0] c;
    output [6:0] display;

    assign display[0] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & c[3]) | (c[0] & ~c[1] & c[2] & c[3]);
    assign display[1] = (c[0] & ~c[1] & c[2] & ~c[3]) | (~c[0] & c[1] & c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & c[3]) | (~c[0] & ~c[1] & c[2] & c[3]) | (~c[0] & c[1] & c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
    assign display[2] = (~c[0] & c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & c[3]) | (~c[0] & c[1] & c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
    assign display[3] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & c[3]) | (~c[0] & c[1] & ~c[2] & c[3]) | (c[0] & c[1] & c[2] & c[3]);
    assign display[4] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & c[3]);
    assign display[5] = (c[0] & ~c[1] & ~c[2] & ~c[3]) | (~c[0] & c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (c[0] & ~c[1] & c[2] & c[3]);
    assign display[6] = (~c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & ~c[1] & ~c[2] & ~c[3]) | (c[0] & c[1] & c[2] & ~c[3]) | (~c[0] & ~c[1] & c[2] & c[3
