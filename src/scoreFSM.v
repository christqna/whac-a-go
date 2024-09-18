module FSMscore (
    input timeUp, W, reset, enable, systemClock,
    output reg shrink,
    output reg [1:0] add,
    output reg [3:0] current
);

localparam A = 4'd0, B = 4'd1, C = 4'd2, start = 4'd3, off = 4'd4,
           waitTimeL1 = 4'd5, waitTimeH1 = 4'd6, waitTimeL2 = 4'd7, waitTimeH2 = 4'd8;

reg [3:0] next;
reg [2:0] count;
reg countUp;

// Next state logic
always @(*) begin
    case (current)
        off: next <= enable ? start : off;
        start: next <= enable ? waitTimeH1 : off;
        waitTimeL1: next <= enable ? (timeUp ? waitTimeL1 : waitTimeH1) : off;
        waitTimeH1: next <= enable ? (timeUp ? (W ? A : B) : waitTimeH1) : off;
        A: next <= enable ? waitTimeL1 : off;
        B: next <= enable ? waitTimeL2 : off;
        waitTimeL2: next <= enable ? (timeUp ? waitTimeL2 : waitTimeH2) : off;
        waitTimeH2: next <= enable ? (timeUp ? (W ? A : C) : waitTimeH2) : off;
        C: next <= enable ? waitTimeL2 : off;
        default: next <= start;
    endcase
end

// Output logic
always @(*) begin
    if (reset || !enable) begin
        add <= 2'd2;
        shrink <= 0;
    end

    case (current)
        start: begin
            shrink <= 0;
            add <= 2'd2;
        end
        A: begin
            add <= 2'd1;
            shrink <= (count == 3'd4) ? 1 : 0;
            countUp <= 1'b1;
        end
        B: begin
            add <= 0;
            shrink <= (count == 3'd4) ? 1 : 0;
            countUp <= 1'b1;
        end
        C: begin
            add <= 0;
            shrink <= 1;
        end
        off, waitTimeH1, waitTimeH2, waitTimeL1, waitTimeL2: begin
            shrink <= 0;
            add <= 2'd2;
        end
    endcase
end

// Switching states
always @(posedge systemClock) begin
    if (reset)
        current <= start;
    else
        current <= next;
end

// Counter control
always @(posedge systemClock) begin
    if (reset)
        count <= 0;
    else if (count == 4'd4)
        count <= 0;
    else if (countUp)
        count <= count + 1;
end

endmodule


module Random (
    input timeUp, reset, enable,
    output [1:0] mole
);

reg [4:0] LFSR;

// Generate random number after time up
always @(negedge timeUp or posedge reset) begin
    if (reset)
        LFSR <= 5'b10001;
    else if (!enable)
        LFSR <= 0;
    else
        LFSR <= {LFSR[3:0], LFSR[4] ^ LFSR[3]};
end

assign mole = LFSR[1:0];

endmodule


module ifScore (
    input keyPressed, mole, reset, pressedInTime, timeUp,
    output reg W
);

// Check score only after key is pressed
always @(posedge timeUp) begin
    if (!pressedInTime)
        W <= 1'b0;
    else if (keyPressed == mole)
        W <= 1'b1;
    else
        W <= 1'b0;
end

endmodule
