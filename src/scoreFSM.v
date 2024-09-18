module FSMscore (timeUp, W, reset, add, shrink,enable,systemClock, current);
input timeUp, W, reset,enable,systemClock;
output reg shrink;
output reg [1:0]add;
// make the signal from counter to be the clock  
localparam A = 4'd0,
B = 4'd1,
C = 4'd2,
start = 4'd3,
off = 4'd4,
waitTimeL1 = 4'd5,
waitTimeH1 = 4'd6,
waitTimeL2 = 4'd7,
waitTimeH2 = 4'd8;

output reg [3:0] current;
reg [3:0] next;
reg [2:0] count;
reg countUp;
//next state logic
always @(*)
begin
case(current)
off: next <= enable? start: off;
start:begin 
	if(!enable)
		next <= off;
	else
	next <= waitTimeH1;
	end 
waitTimeL1: 
	begin 
	if(!enable)
		next <= off;
	else
		next <= timeUp? waitTimeL1: waitTimeH1;
	end 
waitTimeH1:
begin 
	if(!enable)
		next <= off;
	else if (timeUp)
	next <= W? A:B;
	else 
	next <= waitTimeH1;
	end 
A: begin 
	if (!enable)
		next <= off;
	else 
		next <= waitTimeL1;
	end 
B: begin 
	if (!enable)
		next <= off;
	else 
		next <= waitTimeL2;
	end 
waitTimeL2: begin 
	if(!enable)
		next <= off;
	else
		next <= timeUp? waitTimeL2: waitTimeH2;
	end 
waitTimeH2: begin 
	if(!enable)
		next <= off;
	else if (timeUp)
		next <= W ? A:C;
	else
		next <= waitTimeH2;
	end 
C: begin 
	if (!enable)
		next <= off;
	else
		next <= waitTimeL2;
	end
default: next <= start;
endcase
end 

//output logic 

always @(*)
begin 
if (reset == 1'b1 || enable == 1'b0) begin
add <=2'd2;
shrink <= 0;
end 

case(current)
start: begin 
	shrink <= 0;
	add <= 2'd2;
	end 

A: begin 
	add <= 2'd1;
	if (count == 3'd4)
		begin
		shrink <= 1;
		end 
	else 
	begin
	shrink <= 0;
	countUp <= 1'b1;
	end
end 

B: begin add<= 0;
if (count == 3'd4)
		begin
		shrink <= 1;
		end 
	else 
	begin
	shrink <= 0;
	countUp <= 1'b1;
	end
shrink<= 0;
end 

C: begin add<= 0;
shrink<= 1;
end 

off: begin 
add<= 2'd2;
shrink<= 0;
end

waitTimeH1: begin 
shrink <= 0;
add <= 2'd2;
end 

waitTimeH2: begin 
shrink <= 0;
add <= 2'd2;
end 

waitTimeL1: begin
shrink <= 0;
add <= 2'd2;
end 

waitTimeL2: begin 
shrink <= 0;
add <= 2'd2;
end

endcase
end 
// switching states
always @(posedge systemClock)
begin 
if (reset)
current <= start;
else
current <= next;
end 
// counter control

always @(posedge systemClock)
begin 
if (reset)
count <= 0;
else if (count == 4'd4)
count <= 0;
else if (countUp)
count <= count+1;
else 
count <=count;
end 

endmodule 

