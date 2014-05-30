//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : May. 27. 2014
//Description : Float point signed multiply implemetation with Figure 3.18
//              May. 28. 2014
//              Fix Bug1: Fraction multiply result should have 2 MSB to indicate the integer not 1MSB - 
//              Fix Bug2: Fraction part is exponent part is misaligned
module float_point_multiply(
clk,
resetn,
iValid,
iA,
iB,
oDone,
oZ
);

input clk;
input resetn;
input iValid;
input iA;
input iB;
output oZ;
output oDone;
wire [31:0] iA;
wire [31:0] iB;
reg  [31:0] oZ;
reg         oDone;
wire        wSign;
wire [7:0]  wExp;
wire [47:0] wRH_Fraction;
wire [7 :0] wRF_Exp;
wire [22:0] wRF_Frac;
wire        wOverflow;

assign wSign = iA[31]^iB[31];

small_alu_add exp_add(
  .iA(iA[30:23]),
  .iB(iB[30:23]),
  .oZ(wExp),
  .oCout(oExpOverflow)
);
rhombus_24x24 fraction_multiply(
  .clk(clk),
  .resetn(resetn),
  .iA({1'b1, iA[22:0]}),
  .iB({1'b1, iB[22:0]}),
  .oZ(wRH_Fraction) 
);

reg [7:0]  ppExp;
reg [7:0]  pp1Exp;
reg [7:0]  pp2Exp;
reg [7:0]  pp3Exp;
reg        ppSign;
reg        pp1Sign;
reg        pp2Sign;
reg        pp3Sign;
reg        pp4Sign;
reg        ppValid;
reg        pp1Valid;
reg        pp2Valid;
reg        pp3Valid;
reg        pp4Valid;

always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppExp          <= 8'b0;
        pp1Exp         <= 8'b0;
        pp2Exp         <= 8'b0;
        pp3Exp         <= 8'b0;
        ppSign         <= 1'b0;
        pp1Sign        <= 1'b0;
        pp2Sign        <= 1'b0;
        pp3Sign        <= 1'b0;
        pp4Sign        <= 1'b0;
        ppValid        <= 1'b0; 
        pp1Valid       <= 1'b0;
        pp2Valid       <= 1'b0;
        pp3Valid       <= 1'b0;
        pp4Valid       <= 1'b0;
        oDone          <= 1'b0;
    end else begin 
        ppExp          <= wExp;
        pp1Exp         <= ppExp;
        pp2Exp         <= pp1Exp;
        pp3Exp         <= pp2Exp;
        ppSign         <= wSign;
        pp1Sign        <= ppSign;
        pp2Sign        <= pp1Sign;
        pp3Sign        <= pp2Sign;
        pp4Sign        <= pp3Sign;
        ppValid        <= iValid;
        pp1Valid       <= ppValid;
        pp2Valid       <= pp1Valid;
        pp3Valid       <= pp2Valid;
        pp4Valid       <= pp3Valid;
        oDone          <= pp4Valid;
    end 
end 

shift_right rouding_faction(
  .iFrac(wRH_Fraction),
  .iExp(pp3Exp),
  .oFrac(wRF_Frac),
  .oExp(wRF_Exp),
  .oOverflow(wOverflow)
);

always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
         oZ <= 32'b0;
    end else begin 
         oZ    <= {pp4Sign, wRF_Exp, wRF_Frac};
    end 
end 

endmodule //float_point_multiply
module shift_right (
iFrac,
iExp,
oFrac,
oExp,
oOverflow
);
input iFrac;
input iExp;
output oFrac;
output oExp;
output oOverflow;
wire [47:0] iFrac;
wire [7:0]  iExp;
reg  [22:0] oFrac;
reg  [7:0]  oExp;
reg         oOverflow;
always @(iFrac or iExp) begin 
    if (iFrac[47]==1'b1) begin
        oFrac             = iFrac[46:24]; //always ignore the low 24bits.
        {oOverflow, oExp} = iExp + 1;
    end else begin 
        oFrac             = iFrac[45:23];
        oExp              = iExp;
        oOverflow         = 1'b0;
    end
end 

endmodule//shift_right

module small_alu_add (
iA,
iB,
oZ,
oCout
);
input iA;
input iB;
output oZ;
output oCout;
wire [7:0] iA;
wire [7:0] iB;
reg  [7:0] oZ;
reg        oCout;

always @(*) begin 
    {oCout, oZ} = iA -127 + iB;
end 

endmodule 
// Rhombus is
//           02   01   00
//      12   11   10
// 22   21   20
//
module rhombus_12x12(
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
wire [11:0] iA;
wire [11:0] iB;
reg  [23:0] oZ;

wire [7:0] wZ00;
wire [7:0] wZ01;
wire [7:0] wZ02;
wire [7:0] wZ10;
wire [7:0] wZ11;
wire [7:0] wZ12;
wire [7:0] wZ20;
wire [7:0] wZ21;
wire [7:0] wZ22;

reg [23:0] ppConcatZ012;
wire [7:0] wAdderZ02_20;
wire [7:0] wAdderZ01_10;
wire [7:0] wAdderZ12_21;
reg [23:0] ppAdderZ02_20;
reg [23:0] ppConcat19_4;
reg [23:0] pp2Adder24_A;
reg [23:0] pp2ConcatZ012;

wire [23:0] wAdder24_A;

rhombus_4x4 RH4_00 (.iA(iA[3 :0]), .iB(iB[3 :0]), .oZ(wZ00), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_01 (.iA(iA[3 :0]), .iB(iB[7 :4]), .oZ(wZ01), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_02 (.iA(iA[3 :0]), .iB(iB[11:8]), .oZ(wZ02), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_10 (.iA(iA[7 :4]), .iB(iB[3 :0]), .oZ(wZ10), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_11 (.iA(iA[7 :4]), .iB(iB[7 :4]), .oZ(wZ11), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_12 (.iA(iA[7 :4]), .iB(iB[11:8]), .oZ(wZ12), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_20 (.iA(iA[11:8]), .iB(iB[3 :0]), .oZ(wZ20), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_21 (.iA(iA[11:8]), .iB(iB[7 :4]), .oZ(wZ21), .clk(clk), .resetn(resetn));
rhombus_4x4 RH4_22 (.iA(iA[11:8]), .iB(iB[11:8]), .oZ(wZ22), .clk(clk), .resetn(resetn));

//Will be put at [15:8] MSB is 15
half_adder_DW #(.DW(8)) aligned_adder8_02_20(
   .iA(wZ02),
   .iB(wZ20),
   .oZ(wAdderZ02_20)
);
//Will be put at [11:4] MSB is 11
half_adder_DW #(.DW(8)) aligned_adder8_01_10(
   .iA(wZ01),
   .iB(wZ10),
   .oZ(wAdderZ01_10)
);
//Will be put at [19:12] MSB is 19
half_adder_DW #(.DW(8)) aligned_adder8_12_21(
   .iA(wZ12),
   .iB(wZ21),
   .oZ(wAdderZ12_21)
);
//First pipeline, although there is small pipeline in the rhombus
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppConcatZ012 <= 24'b0;
        ppAdderZ02_20<= 24'b0;
        ppConcat19_4 <= 24'b0;
    end else begin 
        ppConcatZ012 <= {wZ22, wZ11,         wZ00};               //[23:0]
        ppAdderZ02_20<= {8'b0, wAdderZ02_20, 8'b0};               //[15:8]
        ppConcat19_4 <= {4'b0, wAdderZ12_21, wAdderZ01_10, 4'b0}; //[19:4]
    end 
end 

half_adder_DW #(.DW(24)) adder24_A (
  .iA(ppAdderZ02_20),
  .iB(ppConcat19_4),
  .oZ(wAdder24_A)
);
//Sencond Pipeline
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        pp2Adder24_A  <= 24'b0;
        pp2ConcatZ012 <= 24'b0;
    end else begin 
        pp2Adder24_A  <= wAdder24_A;
        pp2ConcatZ012 <= ppConcatZ012;
    end 
end 

half_adder_DW #(.DW(24)) adder24_B(
  .iA(pp2Adder24_A),
  .iB(pp2ConcatZ012),
  .oZ(oZ)
);

endmodule  //rhombus_12x12

module rhombus_24x24 (
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
wire [23:0] iA;
wire [23:0] iB;
reg  [47:0] oZ;

wire [23:0] wZ00;
wire [23:0] wZ01;
wire [23:0] wZ10;
wire [23:0] wZ11;

wire [47:0] wAdderZ0;
reg  [47:0] ppAdderZ0;
reg  [47:0] ppConcatZ1;

rhombus_12x12 RH12_00(.iA(iA[11: 0]), .iB(iB[11: 0]), .oZ(wZ00), .clk(clk), .resetn(resetn));
rhombus_12x12 RH12_10(.iA(iA[23:12]), .iB(iB[11: 0]), .oZ(wZ10), .clk(clk), .resetn(resetn));
rhombus_12x12 RH12_01(.iA(iA[11: 0]), .iB(iB[23:12]), .oZ(wZ01), .clk(clk), .resetn(resetn));
rhombus_12x12 RH12_11(.iA(iA[23:12]), .iB(iB[23:12]), .oZ(wZ11), .clk(clk), .resetn(resetn));

half_adder_DW #(.DW(48)) adder48_0 (
  .iA({12'b0, wZ01, 12'b0}),
  .iB({12'b0, wZ10, 12'b0}),
  .oZ(wAdderZ0)
);

always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppAdderZ0  <= 48'b0;
        ppConcatZ1 <= 48'b0;
    end else begin 
        ppConcatZ1 <= {wZ11, wZ00};
        ppAdderZ0  <= wAdderZ0;
    end 
end 

half_adder_DW #(.DW(48)) adder48_2(
  .iA(ppAdderZ0),
  .iB(ppConcatZ1),
  .oZ(oZ)
);

endmodule //rhombus_24x24
