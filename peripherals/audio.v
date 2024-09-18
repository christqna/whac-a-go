module DE1_SoC_Audio_Example (
    // Inputs
    CLOCK_50,
    AUD_ADCDAT,
    enable,
    W, 
    reset,
    timeUp,
    
    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,

    FPGA_I2C_SDAT,

    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input CLOCK_50;
input timeUp;
input enable;
input W;
input reset;
input AUD_ADCDAT;

// Bidirectionals
inout AUD_BCLK;
inout AUD_ADCLRCK;
inout AUD_DACLRCK;
inout FPGA_I2C_SDAT;

// Outputs
output AUD_XCK;
output AUD_DACDAT;
output FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire audio_in_available;
wire [31:0] left_channel_audio_in;
wire [31:0] right_channel_audio_in;
wire read_audio_in;

wire audio_out_allowed;
wire [31:0] left_channel_audio_out;
wire [31:0] right_channel_audio_out;
wire write_audio_out;
wire pulse;
wire doneSound;

wire [3:0] count;

// Internal Registers
reg [18:0] delay_cnt;
reg [18:0] delay;
reg [3:0] current, next;
reg snd;
reg [31:0] sound;
reg startSound;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/
localparam start = 4'd0,
           soundPlay = 4'd1,
           soundOff = 4'd2,
           waitlow = 4'd3;

// Next state logic
always @(*)
begin
    case (current)
        start: begin
            if (enable == 1'b1 && timeUp == 1'b1)
                next = soundPlay;
            else
                next = start;
        end
        soundPlay: begin
            if (!enable)
                next = start;
            else if (doneSound)
                next = waitlow;
            else
                next = soundPlay;
        end
        soundOff: begin
            if (enable == 1'b0)
                next = start;
            else if (timeUp)
                next = soundPlay;
            else
                next = soundOff;
        end
        waitlow: begin
            if (!enable)
                next = start;
            else
                next = timeUp ? waitlow : soundOff;
        end
    endcase
end

// Output logic
always @(*)
begin
    case(current)
        start: begin
            startSound = 1'b0;
        end
        soundPlay: startSound = 1'b1;
        waitlow: startSound = 1'b0;
        soundOff: startSound = 1'b0;
    endcase
end

// State change
always @(posedge CLOCK_50, posedge reset)
begin
    if (reset)
        current <= start;
    else
        current <= next;
end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/
always @(posedge CLOCK_50)
begin
    if (delay_cnt == delay) begin
        delay_cnt <= 0;
        snd <= !snd;
    end else
        delay_cnt <= delay_cnt + 1;
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/
always @(*)
begin
    if (!W) begin
        if(count == 4'd2)
            delay <= 32'd191131;
        else if (count == 4'd1)
            delay <= 32'd151653;
        else if (count == 4'd0)
            delay <= 32'd95547;
    end else begin
        if(count == 4'd0)
            delay <= 32'd191131;
        else if (count == 4'd1)
            delay <= 32'd151653;
        else if (count == 4'd2)
            delay <= 32'd95547;
        else
            delay <= delay;
    end
end

always @(*)
begin
    if (enable == 0 || pulse == 0)
        sound <= 0;
    else
        sound <= snd ? 32'd10000000 : -32'd10000000;
end

assign read_audio_in = audio_in_available & audio_out_allowed;
assign left_channel_audio_out = left_channel_audio_in + sound;
assign right_channel_audio_out = right_channel_audio_in + sound;
assign write_audio_out = audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

rateDivider #(50000000) rdv (
    .systemClock(CLOCK_50),
    .start(startSound),
    .reset(reset),
    .pulse(pulse),
    .doneSound(doneSound),
    .count(count)
);

Audio_Controller Audio_Controller (
    // Inputs
    .CLOCK_50(CLOCK_50),
    .reset(reset),

    .clear_audio_in_memory(),
    .read_audio_in(read_audio_in),

    .clear_audio_out_memory(),
    .left_channel_audio_out(left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out(write_audio_out),

    .AUD_ADCDAT(AUD_ADCDAT),

    // Bidirectionals
    .AUD_BCLK(AUD_BCLK),
    .AUD_ADCLRCK(AUD_ADCLRCK),
    .AUD_DACLRCK(AUD_DACLRCK),

    // Outputs
    .audio_in_available(audio_in_available),
    .left_channel_audio_in(left_channel_audio_in),
    .right_channel_audio_in(right_channel_audio_in),

    .audio_out_allowed(audio_out_allowed),

    .AUD_XCK(AUD_XCK),
    .AUD_DACDAT(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
    .CLOCK_50(CLOCK_50),
    .reset(reset)
);

endmodule

module rateDivider #(parameter CLOCK_FREQUENCY = 50000000)(
    input systemClock,
    input start,
    input reset,
    output pulse,
    output reg doneSound,
    output reg [3:0] count
);

reg [27:0] Q;

always @(posedge systemClock)
begin
    if (reset == 1'b1 || count == 4'd3) begin
        Q <= (CLOCK_FREQUENCY - 1) / 5;
        if (count == 4'd3) begin
            count <= 0;
            doneSound <= 1'b1;
        end else begin
            doneSound <= 1'b0;
            count <= 0;
        end
    end else if (start == 1'b1) begin
        if (count == 0)
            doneSound = 1'b0;
        if (Q == 0) begin
            Q <= (CLOCK_FREQUENCY - 1) / 5;
            count <= count + 1;
        end else
            Q <= Q - 1;
    end else if (start == 1'b0) begin
        Q <= (CLOCK_FREQUENCY - 1) / 5;
        count <= 0;
        doneSound <= 1'b0;
    end
end

assign pulse = (Q < (CLOCK_FREQUENCY / 10)) ? 1 : 0;

endmodule
