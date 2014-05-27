//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : 2014-1-2
//Description : 16 bit adder with pipeline
module adder_8bits(
a,
b,
ci,
y,
co 
);
input a;
input b;
input ci;
output y;
output co; 

wire [7:0] a;
wire [7:0] b;
wire [7:0] y

always @(a or b or ci) begin 
    {co, y} = {1'b0, a} + {ci, b};    
end 

endmodule 

module adder_16bits(
a, 
b,
ci,
y,
co
);
input a;
input b;
input ci;
output y;
output co; 
wire [15:0] a;
wire [15:0] b;
wire [15:0] y

wire co_lo;
wire [7:0] y_lo;
wire [7:0] y_hi;
adder_8bibts 
  adder_lo (
    .a(a[7:0]),
    .b(b[7:0]),
    .ci(ci),
    .y(y_lo),
    .co(co_lo)
);

adder_8bits
  adder_hi (
    .a(a[8:15]),
    .b(b[8:15]),
    .ci(co_lo),
    .y(y_hi),
    .co(co)
);

assign y = {y_hi, y_lo}; 

endmodule 
module adder_16bits_pipeline(
clk,
resetn,
a, 
b,
ci,
y,
co
);
input clk;
input resetn;
input a;
input b;
input ci;
output y;
output co; 
wire [15:0] a;
wire [15:0] b;
wire [15:0] y

//interal variable
reg[7:0] a_hi;
reg[7:0] b_hi;
reg[7:0] y_hi;
reg[7:0] y_lo;
reg      co_lo;
reg[1:0] counter;

always @(posedge clk or negedge resetn) 
  if (~resetn) begin 
    a_hi <= 8'h0;
    b_hi <= 8'h0;
    y_hi <= 8'h0;
    y_lo <= 8'h0;
    co_lo <= 1'b0;
    counter <= 0;
  end else begin 
    if (counter ==0) begin 
      a_hi <= a[15:8];
      b_hi <= b[15:8];
      {co_lo, y_lo} <= {1'b0, a[7:0] } + {ci, b[7:0]};
      counter <= 1;
    end else if (counter ==1) begin 
      {co, y_hi} <= {1'b0, a_hi} + {co_lo, b_hi};
      counter    <=2;
    end else if (counter == 2) begin 
      y       <= {y_hi, y_lo};
      counter <= 0;
    end 
  end 


endmodule 
