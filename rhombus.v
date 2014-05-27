//Author     : Alex Zhang (cgzhangwei@gmail.com)
//Date       : May 20. 2014
//Description: 4x4 multiply cell that is the rhombus like which can be used in 8x8 unsigned multiply with pipeline.
module rhombus_4x4(
clk,
resetn,
iA,
iB,
oZ
);
input clk;
input resetn;
input iA;
input iB;
output oZ;
wire [3:0] iA;//x
wire [3:0] iB;//y
reg  [7:0] oZ; //MSB is the carry out. 
wire [7:0] wZ;
wire wCout00,wCout01,wCout02,wCout03;
wire wZ01,wZ02,wZ03;
wire wCout10,wCout11,wCout12,wCout13;
wire wZ11,wZ12,wZ13;
wire wCout20,wCout21,wCout22;
//First row
half_adder HA(.iA(1'b0),          .iB(iA[0]&iB[0]), .oZ(wZ[0]), .oCout());
half_adder HA00(.iA(iA[1]&iB[0]), .iB(iA[0]&iB[1]), .oZ(wZ[1]), .oCout(wCout00));
full_adder FA01(.iA(iA[2]&iB[0]), .iB(iA[1]&iB[1]), .oZ(wZ01),  .oCout(wCout01), .iCin(wCout00));
full_adder FA02(.iA(iA[3]&iB[0]), .iB(iA[2]&iB[1]), .oZ(wZ02),  .oCout(wCout02), .iCin(wCout01));
half_adder HA03(.iA(wCout02),     .iB(iA[3]&iB[1]), .oZ(wZ03),  .oCout(wCout03));
//Second row
half_adder HA10(.iA(wZ01),        .iB(iA[0]&iB[2]), .oZ(wZ[2]), .oCout(wCout10));
full_adder FA11(.iA(wZ02),        .iB(iA[1]&iB[2]), .oZ(wZ11),  .oCout(wCout11), .iCin(wCout10));
full_adder FA12(.iA(wZ03),        .iB(iA[2]&iB[2]), .oZ(wZ12),  .oCout(wCout12), .iCin(wCout11));
full_adder FA13(.iA(wCout03),     .iB(iA[3]&iB[2]), .oZ(wZ13),  .oCout(wCout13), .iCin(wCout12));
//Third row
half_adder HA20(.iA(wZ11),        .iB(iA[0]&iB[3]), .oZ(wZ[3]), .oCout(wCout20));
full_adder FA21(.iA(wZ12),        .iB(iA[1]&iB[3]), .oZ(wZ[4]), .oCout(wCout21), .iCin(wCout20));
full_adder FA22(.iA(wZ13),        .iB(iA[2]&iB[3]), .oZ(wZ[5]), .oCout(wCout22), .iCin(wCout21));
full_adder FA23(.iA(wCout13),     .iB(iA[3]&iB[3]), .oZ(wZ[6]), .oCout(wZ[7]),   .iCin(wCout22));
always @(posedge clk or negedge resetn) begin
    if (!resetn) 
        oZ <= 8'b0;
    else 
        oZ <= wZ;
end

endmodule 

module rhombus_8x8(
clk,
resetn,
iA,
iB,
oZ
);


input clk;
input resetn;
input iA;
input iB;
output oZ;
wire [7:0] iA;
wire [7:0] iB;

reg [15:0] oZ; //MSB is the carry out. 
wire [7:0] wZ00;
wire [7:0] wZ01;
wire [7:0] wZ10;
wire [7:0] wZ11;
rhombus_4x4 RH4_00(.iA(iA[3:0]), .iB(iB[3:0]), .oZ(wZ00), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_10(.iA(iA[7:4]), .iB(iB[3:0]), .oZ(wZ10), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_01(.iA(iA[3:0]), .iB(iB[7:4]), .oZ(wZ01), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_11(.iA(iA[7:4]), .iB(iB[7:4]), .oZ(wZ11), .clk(clk), .resetn(resetn));
wire [15:0] wAdderZ0;
reg  [15:0] ppAdderZ0;
reg  [15:0] ppConcatZ1;

half_adder_DW #(.DW(16)) adder16_0 (
  .iA({4'b0, wZ01, 4'b0}),
  .iB({4'b0, wZ10, 4'b0}),
  .oZ(wAdderZ0)
);
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppAdderZ0  <= 16'b0;
        ppConcatZ1 <= 16'b0;
    end else begin
        ppAdderZ0  <= wAdderZ0;
        ppConcatZ1 <= {wZ11, wZ00};
        $display("ppConcatZ1= 0x%0x, wZ00=0x%0x", ppConcatZ1, wZ00);
    end
end 

half_adder_DW #(.DW(16)) adder16_2 (
  .iA(ppAdderZ0),
  .iB(ppConcatZ1),
  .oZ(oZ)
);

endmodule 


module rhombus_16x16(
clk,
resetn,
iA,
iB,
oZ
);
input clk;
input resetn;
input iA;
input iB;
output oZ;
wire [15:0] iA;
wire [15:0] iB;

reg [31:0] oZ; //MSB is the carry out. 
wire [15:0] wZ00;
wire [15:0] wZ01;
wire [15:0] wZ10;
wire [15:0] wZ11;

rhombus_8x8 RH8_00(.iA(iA[7:0]),  .iB(iB[7:0]),  .oZ(wZ00), .clk(clk), .resetn(resetn));
rhombus_8x8 RH8_10(.iA(iA[15:8]), .iB(iB[7:0]),  .oZ(wZ10), .clk(clk), .resetn(resetn));
rhombus_8x8 RH8_01(.iA(iA[7:0]),  .iB(iB[15:8]), .oZ(wZ01), .clk(clk), .resetn(resetn));
rhombus_8x8 RH8_11(.iA(iA[15:8]), .iB(iB[15:8]), .oZ(wZ11), .clk(clk), .resetn(resetn));

wire [31:0] wAdderZ0;
reg  [31:0] ppAdderZ0;
reg  [31:0] ppConcatZ1;

half_adder_DW #(.DW(32)) adder32_0 (
  .iA({8'b0, wZ01, 8'b0}),
  .iB({8'b0, wZ10, 8'b0}),
  .oZ(wAdderZ0)
);
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppAdderZ0  <= 32'b0;
        ppConcatZ1 <= 32'b0;
    end else begin
        ppAdderZ0  <= wAdderZ0;
        ppConcatZ1 <= {wZ11, wZ00};
    end
end 

half_adder_DW #(.DW(32)) adder32_2 (
  .iA(ppAdderZ0),
  .iB(ppConcatZ1),
  .oZ(oZ)
);

endmodule 

module rhombus_32x32(
clk,
resetn,
iA,
iB,
oZ
);
input clk;
input resetn;
input iA;
input iB;
output oZ;
wire [31:0] iA;
wire [31:0] iB;

reg [63:0] oZ; //MSB is the carry out. 
wire [31:0] wZ00;
wire [31:0] wZ01;
wire [31:0] wZ10;
wire [31:0] wZ11;

rhombus_16x16 RH16_00(.iA(iA[15:0]),  .iB(iB[15:0]),  .oZ(wZ00), .clk(clk), .resetn(resetn));
rhombus_16x16 RH16_10(.iA(iA[31:16]), .iB(iB[15:0]),  .oZ(wZ10), .clk(clk), .resetn(resetn));
rhombus_16x16 RH16_01(.iA(iA[15:0]),  .iB(iB[31:16]), .oZ(wZ01), .clk(clk), .resetn(resetn));
rhombus_16x16 RH16_11(.iA(iA[31:16]), .iB(iB[31:16]), .oZ(wZ11), .clk(clk), .resetn(resetn));

wire [63:0] wAdderZ0;
reg  [63:0] ppAdderZ0;
reg  [63:0] ppConcatZ1;

half_adder_DW #(.DW(64)) adder64_0 (
  .iA({16'b0, wZ01, 16'b0}),
  .iB({16'b0, wZ10, 16'b0}),
  .oZ(wAdderZ0)
);
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppAdderZ0  <= 64'b0;
        ppConcatZ1 <= 64'b0;
    end else begin
        ppAdderZ0  <= wAdderZ0;
        ppConcatZ1 <= {wZ11, wZ00};
    end
end 

half_adder_DW #(.DW(64)) adder64_2 (
  .iA(ppAdderZ0),
  .iB(ppConcatZ1),
  .oZ(oZ)
);

endmodule 
