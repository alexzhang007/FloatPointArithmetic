//Author     : Alex Zhang (cgzhangwei@gmail.com)
//Date       : May 27. 2014
//Description: onebit half_adder, parameterized half_adder, and full_adder .
module half_adder (
iA,
iB,
oZ,
oCout
);
input iA;
input iB;
output oZ;
output oCout;
reg oZ;
reg oCout;
always @(iA or iB)
    {oCout, oZ} = iA + iB;
endmodule 

module full_adder (
iA,
iB,
iCin,
oZ,
oCout
);
input iA;
input iB;
input iCin;
output oZ;
output oCout;
reg oZ;
reg oCout;
always @(iA or iB or iCin)
    {oCout, oZ} = iA + iB + iCin;
endmodule 

module half_adder_DW(
iA,
iB,
oZ,
oCout
);
input iA;
input iB;
output oZ;
output oCout;
parameter DW = 15;
wire [DW-1:0] iA;
wire [DW-1:0] iB;
reg  [DW-1:0] oZ;
reg         oCout;

always @(iA or iB)
    {oCout, oZ} = iA + iB;
endmodule 

