module ps2Keyboard (ps2clock, ps2data, reset,ifPressed, keyPressed,CLOCK_50);
input ps2clock, ps2data,reset,CLOCK_50;
output [1:0] keyPressed;
output ifPressed;
wire doneShift, ifShift;
wire [7:0] D;
wire [3:0] check;

ps2KeyboardFSM u4 (.clock(ps2clock), .data(ps2data), .reset(reset),.doneShift(doneShift), .ifPressed(ifPressed), .D(D), .ifShift(ifShift),.keyPressed(keyPressed),.CLOCK_50(CLOCK_50),.key2(key2),.key1(key1),.key3(key3));
keyboardShift u5 (.clock(ps2clock), .reset(reset), .data(ps2data),.DATA(D),.ifShift(ifShift),.doneShift(doneShift),.count(check));
// keyboardShift (clock, reset, data,DATA, ifShift, doneShift);
endmodule 
// (clock, reset, data,D, ifShift, doneShift)



module ps2KeyboardFSM (clock, data,reset,doneShift,ifPressed, D,ifShift,keyPressed,CLOCK_50,key2,key1,key3 );
input clock, reset,data, doneShift,CLOCK_50;
input[7:0]D;
output reg [1:0]keyPressed;
output reg ifPressed,ifShift; 
output reg [7:0] key2;
output reg [7:0] key1,key3;
localparam done = 4'd0,
waitclckL1 = 4'd1,
waitDone1 = 4'd2,
getkey1 = 4'd3,
waitclckL2 = 4'd4,
waitDone2 = 4'd5,
getkey2 = 4'd6,
breakey = 4'd7,
waitclckL3 = 4'd8,
waitDone3= 4'd9,
getkey3 = 4'd10,
loadKey1 = 4'd11,
loadKey3 = 4'd12,
waitclckh2 = 4'd13,
waitclckh3 = 4'd14,
waitclckh1 = 4'd15;


reg [3:0]current;
reg [3:0] next;

//next state logic
always@(*)
begin 
case(current)
waitclckh1: next = clock? waitclckL1 : waitclckh1;
waitclckL1: next = clock? waitclckL1 : waitDone1;
waitDone1: next = doneShift? getkey1: waitDone1;
getkey1:next = loadKey1;
loadKey1: 
 begin 
case(key1)
	8'h1C: next = waitclckh2;
	8'h1B: next = waitclckh2;
	8'h23: next = waitclckh2;
	8'h2B: next = waitclckh2;
	default : next = waitclckL1;
endcase
end
waitclckh2: next = clock? waitclckL2 : waitclckh2;
waitclckL2: next = clock? waitclckL2: waitDone2;
waitDone2: next = doneShift? getkey2: waitDone2;
getkey2: next = breakey; 
breakey: begin 
if (key2 == 8'hF0)
next = waitclckh3;
else
next = waitclckh2;
end 
waitclckh3: next = clock ? waitclckL3: waitclckh3;
waitclckL3: next = clock ? waitclckL3: waitDone3;
waitDone3: next = doneShift? getkey3: waitDone3;
getkey3: next = loadKey3;
loadKey3:
 begin
if(key3 == key1)
next = done;
else
next = waitclckL2;
end
done: next = waitclckh1;
default: next = waitclckh1; 
endcase
end

// output logic 
always @(*)
begin
if(reset)
begin 
ifPressed <= 1'b0;
keyPressed <= 0;
key1 <= 0;
key2 <= 0;
key3 <= 0;
end 

ifShift <= 1'b0;
case(current)
waitclckL1: ifPressed <= 0;
waitDone1:begin 
ifShift <= 1'b1;
end 
getkey1: key1 <= D;
waitDone2: ifShift <= 1'b1;
getkey2:begin 
 key2<= D;
 end 
waitDone3: ifShift <= 1'b1; 
getkey3: key3 <= D;
done : begin 
ifPressed <= 1'b1;
// check which key was pressed
case(key3)
8'h1C: keyPressed <= 2'b00;
8'h1B: keyPressed <= 2'b01;
8'h23: keyPressed <= 2'b10;
8'h2B: keyPressed <= 2'b11;
endcase
end
endcase
end 

always@(posedge CLOCK_50)
begin 
if (reset)
current <= waitclckh1;
else
current <= next;
end 

endmodule 


// shift register 
module keyboardShift (clock, reset, data,DATA, ifShift, doneShift,count);
input clock, reset, data, ifShift;
output reg doneShift;
output [7:0]DATA; 
reg [9:0] D; 
output reg [3:0]count;

// COUNTER UP TILL 10
always @(negedge clock,posedge reset)
begin 
if (reset )
count <= 4'b0000;
else if (count == 4'd10)
begin
count <= 4'b0000;
end
else if (ifShift)
begin 
count = count +1'b1;
end 
end 

// SHIFT REGISTER 
always @(negedge clock, posedge reset)
begin 
if (reset) 
D <= 10'b0000000000;
else if (ifShift == 1'b1)
begin 
D <= D >> 1;
D[9] <= data;
end 
end 

// CHECK IF IT IS DONE SHIFTING 
always @(*)
begin 
if (count == 4'd10)
begin 
doneShift = 1'b1;
end 
else 
begin 
doneShift <= 1'b0;
end
end 
assign DATA = D[7:0];

endmodule 
