//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : May.21.2014
//Description : Float-point signed addtion implementation with Figure 3.17, extening a little to support signed. 
//  Sign  Exponent  Fraction 
//  31    30-23     22-0
//        exp-127
//  Value = (-1)^S*(1+Fraction)*2^(exp-127)
//  1. We need to change the exponent of smaller one to the bigger 
module float_point_add(
clk,
resetn,
iA,
iB,
iOp,
oF, 
oDone
);
input clk;
input resetn;
input iA;
input iB;
input iOp;
output oF;
output oDone;
wire [31:0] iA;
wire [31:0] iB;
wire [1:0]  iOp;
reg  [31:0] oF;
reg         oDone;

//Declartion of connection 
wire        wSelA;
wire        wSelB;
wire        wSelC;
wire        wCarry;
wire        wC_BigALU;
wire [7:0]  wBigExp;
wire [7:0]  wZExpDiff;
wire [1:0]  wShiftLorR;
wire [1:0]  wExpIorD;
wire        wShiftR;
wire        wRH_RoundExp;
wire        wRH_RoundFra;
wire        wRound;
wire [22:0] wSmallFraction;
wire [22:0] wLargeFraction;
wire [22:0] wSRSmallFraction;
wire [23:0] wZ_BHA;
wire [7:0]  wMuxD;
wire [22:0] wMuxE;
wire [23:0] wShf;
wire [7:0]  wExp;
wire [7:0]  wRH_Exp;
wire [23:0] wRH_Fraction;
reg  [31:0] ppA;
reg  [31:0] ppB;
wire        wSign;
wire        wFSign;
wire        wDone;

always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppA  <= 32'b0;
        ppB  <= 32'b0;
    end  else begin 
        ppA  <= iA;
        ppB  <= iB;
    end 
end

mux_2 #(.DATA_WIDTH(8)) muxTwoA(
  .iZeroBranch(ppA[30:23]),
  .iOneBranch(ppB[30:23]),
  .iSel(wSelA),    //B Larger than A
  .oMux(wBigExp)
);

small_alu small_alu_sub(
  .iA(iA[30:23]),
  .iB(iB[30:23]),
  .oZ(wZExpDiff),
  .oCout(wCarry)
);
control fp_control(
  .iExpDiff(wZExpDiff),
  .iRelate(wCarry),
  .iNeedShift(wC_BigALU),     //Carryout from Big ALU
  .iFpSignA(ppA[31]),
  .iFpSignB(ppB[31]),
  .iOp(iOp),
  .oOp(wOp),
  .oSign(wSign),
  .oBLA(wSelA),
  .oSelB(wSelB),
  .oSelC(wSelC),
  .oShiftR(wShiftR),
  .oShiftLorR(wShiftLorR), //2bits signal
  .oExpIorD(wExpIorD),     //2bits signal
  .oRH_RoundExp(wRH_RoundExp),
  .oRH_RoundFra(wRH_RoundFra),
  .oRound(wRound)
);


mux_2 #(.DATA_WIDTH(23)) muxTwoB(
  .iZeroBranch(ppA[22:0]),
  .iOneBranch(ppB[22:0]),
  .iSel(wSelB),
  .oMux(wSmallFraction)
);
mux_2 #(.DATA_WIDTH(23)) muxTwoC(
  .iZeroBranch(ppA[22:0]),
  .iOneBranch(ppB[22:0]),
  .iSel(wSelC),
  .oMux(wLargeFraction)
);
//FIXME, it might cannot be written like this, verilog shift operator should have constant in the RHS. We will use the clk here for shift. 
//It can be synthesizable, but it will cost a lot of resource. 
//wShiftR should be 23 enough. 
//case(wShiftR) :
//     5'b0:
//     5'b1:
//     ..
//     5'b10111: 
assign wSRSmallFraction = wSmallFraction >> wShiftR;

big_half_add big_ha(
  .iA({1'b1,wSRSmallFraction}),
  .iB({1'b1,wLargeFraction}),
  .iOp(wOp),
  .oZ(wZ_BHA),
  .oCout(wC_BigALU)
);
//When it is add operation, the sign is depend on the wSign
assign wFSign = wOp== 2'b01 ? wSign : wSign^wC_BigALU ;


mux_2 #(.DATA_WIDTH(8)) muxTwoD(
  .iZeroBranch(wBigExp),
  .iOneBranch(wRH_Exp),
  .iSel(wRH_RoundExp),
  .oMux(wMuxD)
);

mux_2 #(.DATA_WIDTH(24)) muxTwoE(
  .iZeroBranch(wZ_BHA),
  .iOneBranch(wRH_Fraction),
  .iSel(wRH_RoundFra),
  .oMux(wMuxE)
);

exp_inc_dec exp_id(
  .iExp(wMuxD),
  .iExpIorD(wExpIorD),
  .oExp(wExp)
);

shift_left_right shf_lr(
  .iShf(wMuxE),
  .iShfRR(wC_BigALU),
  .iShfLorR(wShiftLorR),
  .oShf(wShf)
);

rounding_hardware round_hw(
  .clk(clk),
  .resetn(resetn),
  .iExp(wExp),
  .iFraction(wShf),
  .iRound(wRound),
  .oRoundExp(wRH_Exp),
  .oRoundFraction(wRH_Fraction),
  .oDone(wDone)
);
always @(posedge clk or negedge resetn) begin 
    if (~resetn) 
        oF <= 32'b0;
    else begin 
        if (wDone) begin 
           oF    <= {wFSign, wRH_Exp, wRH_Fraction[22:0]};
           oDone <= 1'b1;
        end else begin 
           oF    <= 32'b0;
           oDone <= 1'b0;
        end
    end 
end 
endmodule 

//small_alu only performance the substract. 
module small_alu(
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
always @(iA or iB) begin 
     if(iA >= iB) begin 
         oZ = iA - iB;
         oCout = 1'b0;
     end else begin 
         oZ = iB -iA;
         oCout = 1'b1;
     end
end 

endmodule //small_alu

module control (
iExpDiff,
iRelate,
iNeedShift,
iFpSignA,
iFpSignB,
iOp,
oOp,
oSign,
oBLA,
oSelB,
oSelC,
oShiftR,
oShiftLorR, //2bits signal
oExpIorD,     //2bits signal
oRH_RoundExp,
oRH_RoundFra,
oRound
);
input iExpDiff;
input iRelate;
input iNeedShift;
input iFpSignA;
input iFpSignB;
input iOp;
output oOp;
output oSign;
output oBLA;
output oSelB;
output oSelC;
output oShiftR;
output oShiftLorR;
output oExpIorD;
output oRH_RoundExp;
output oRH_RoundFra;
output oRound;

wire [7:0]  iExpDiff;
wire        iRelate;
wire        iFpSignA;
wire        iFpSignB;
wire [1:0]  iOp;
reg  [1:0]  oOp;
reg         oSign;
reg         oBLA;
reg         oSelB;
reg         oSelC;
reg [5:0]   oShiftR;
reg [1:0]   oShiftLorR;
reg [1:0]   oExpIorD;
reg         oRH_RoundExp;
reg         oRH_RoundFra;
reg         oRound;

always @(*) begin 
     oBLA         = iRelate ? 1'b1 : 1'b0 ;
     oRH_RoundExp = 1'b0;
     oRH_RoundFra = 1'b0;
end 
always @(*) begin 
     case ({iFpSignA, iOp, iFpSignB})
         4'b0010  :  begin 
                         //A+B
                         oSign      = 1'b0; 
                         oOp        = 2'b01;  
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have incr. 
                         oShiftLorR = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have shift right.
                         oRound     = 1'b1;
                     end 
         4'b0011  :  begin 
                         //A+(-B)
                         //if A>B (iRelate=0), sign=1'b0 else sign=1'b1; 
                         oSign      = iRelate ? 1'b1 : 1'b0;   //A+(-B), 
                         oOp        = 2'b10;
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b01 : 2'b00 ; //Sub will only have decr. 
                         oShiftLorR = iNeedShift ? 2'b11 : 2'b00 ; //Sub will cause the complement 
                         oRound     = 1'b1;
                     end 
         4'b1010  :  begin
                         //-A+B = -(A-B)
                         oSign      = iRelate ? 1'b0 : 1'b1; 
                         oOp        = 2'b10;  
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b1 : 1'b0 ;
                         oSelC      = iRelate ? 1'b0 : 1'b1; 
                         oExpIorD   = iNeedShift ? 2'b01 : 2'b00 ; //Sub will only have decr. 
                         oShiftLorR = iNeedShift ? 2'b11 : 2'b00 ; //Sub will cause the complement 
                         oRound     = 1'b1;
                     end 
         4'b1011  :  begin 
                         //-A+(-B) =-(A+B)
                         oSign      = 1'b1; 
                         oOp        = 2'b01;  
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have incr. 
                         oShiftLorR = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have shift right.
                         oRound     = 1'b1;
                     end 
         4'b0100  :  begin 
                         //A-B
                         oSign      = iRelate ? 1'b1: 1'b0; 
                         oOp        = 2'b10;  
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b01 : 2'b00 ; //Sub will only have decr. 
                         oShiftLorR = iNeedShift ? 2'b11 : 2'b00 ; //Sub will cause the complement 
                         oRound     = 1'b1;
                     end 
         4'b0101  :  begin 
                         //A-(-B)
                         oSign      = 1'b0;
                         oOp        = 2'b01; 
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have incr. 
                         oShiftLorR = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have shift right.
                         oRound     = 1'b1;
                     end 
         4'b1100  :  begin 
                         //-A-B = -(A+B)
                         oSign      = 1'b1; 
                         oOp        = 2'b01;  
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b10 : 2'b00 ; //Add will only have incr. 
                         oShiftLorR = iNeedShift ? 2'b11 : 2'b00 ; //Sub will cause the complement 
                         oRound     = 1'b1;
                     end 
         4'b1101  :  begin 
                         //-A-(-B) = -(A-B)
                         //iRelate =0, A>=B, oSelC=0(select A) 
                         oSign      = iRelate ? 1'b0 : 1'b1; 
                         oOp        = 2'b10; 
                         oShiftR    = iExpDiff >23 ? 23: iExpDiff ;  
                         oSelB      = iRelate ? 1'b0 : 1'b1 ;
                         oSelC      = iRelate ? 1'b1 : 1'b0; 
                         oExpIorD   = iNeedShift ? 2'b01 : 2'b00 ; //Sub will only have decr. 
                         oShiftLorR = iNeedShift ? 2'b11 : 2'b00 ; //Sub will cause the complement 
                         oRound     = 1'b1;
                     end 
          //Way1. Need to add the default branch in the case, otherwise, the big_half_add will always be overflow. 
          default  : begin 
                         oSign      = 1'b0;
                         oOp        = 2'b00;
                         oShiftR    = 0;
                         oSelB      = 1'b0;
                         oSelC      = 1'b1;
                         oExpIorD   = 2'b00;
                         oShiftLorR = 2'b00;
                         oRound     = 1'b0;
                     end
     endcase 
end 

endmodule //control 
module exp_inc_dec (
clk,
resetn,
iExp,
iExpIorD,
oExp,
oExpOverflow
);
input clk;
input resetn;
input iExp;
input iExpIorD;
output oExp;
output oExpOverflow;

wire [7:0]  iExp;
wire [1:0]  iExpIorD;
reg  [7:0]  oExp;
reg         oExpOverflow;
always @(iExpIorD or iExp) begin 
     case (iExpIorD)
         2'b10 : //Incr
               {oExpOverflow, oExp} = iExp + 8'b1;
         2'b01 : //Decr
               {oExpOverflow, oExp} = iExp - 8'b1;
         2'b00 : begin  //Keep
                 oExpOverflow = 1'b0;
                 oExp = iExp;
                 end 
     endcase
end 
endmodule 
module shift_left_right (
iShf,
iShfRR,
iShfLorR,
oShf
);
input iShf;
input iShfRR;
input iShfLorR;
output oShf;

wire [23:0] iShf;
wire        iShfRR;
wire [1:0]  iShfLorR;
reg  [23:0] oShf;
always @(iShfLorR or iShf) begin 
    case (iShfLorR) 
       2'b10 : //Shift Right
              oShf = {iShfRR, iShf[23:1]};
       2'b01 : //Shift Left
              oShf = {iShf[22:0], 1'b0};
       2'b00 :
              oShf = iShf;
       2'b11 : 
              oShf = ~iShf +1; //Complement +1
    endcase
end  

endmodule 
module big_half_add (
iA,
iB,
iOp,
oZ,
oCout
);
input iA;
input iB;
output oZ;
input iOp;
output oCout;
wire [23:0] iA;
wire [23:0] iB;
wire [1:0]  iOp;
reg  [23:0] oZ;
reg         oCout;

always @(iA or iB or iOp) begin 
    case (iOp)
        2'b01:  {oCout, oZ} = iA + iB; //Add
        2'b10:  {oCout, oZ} = iB - iA; //Sub
        2'b00:  begin oCout =0; oZ =24'b0; end //Nop Operation
    endcase 
end 
endmodule 
module rounding_hardware (
clk,
resetn,
iExp,
iFraction,
iRound,
oRoundExp,
oRoundFraction,
oDone
);
input clk;
input resetn;
input iExp;
input iFraction;
input iRound;
output oRoundExp;
output oRoundFraction;
output oDone;
wire [7:0]  iExp;
wire [23:0] iFraction;
reg  [7:0]  oRoundExp;
reg  [23:0] oRoundFraction;
reg         oDone;
reg         rMoved;
//Actually, float point add or substraction is no need to rounding, only the multiply or division need rounding. 
//shift left to meet the IEEE750. 
//Need a state machine to determine the Rounding logic.
parameter S_IDLE  = 3'b000;
parameter S_MOVE  = 3'b001;
parameter S_ROUND = 3'b010;
parameter S_DONE  = 3'b100;
reg  [2:0] state;
reg  [2:0] next_state;

always @(posedge clk or negedge resetn) begin 
    if (~resetn) 
        state <= S_IDLE;
    else
        state <= next_state;
end 
always @(*) begin 
    next_state = state;
    case (state) 
        S_IDLE : begin 
                    if (iRound)
                        next_state = iFraction[23] ? S_DONE : S_ROUND;
                 end 
         S_ROUND:begin 
                    if (oRoundFraction[22]==1'b1) //FIXME: need to detect the cycles
                        next_state = S_DONE;
                    else 
                        next_state = S_ROUND; 
                 end 
         S_DONE : begin 
                    next_state = S_IDLE;
                  end 
    endcase
end 

always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
       oRoundExp      <= 8'b0;
       oRoundFraction <= 24'b0;
       oDone          <= 1'b0;
    end else begin 
        case (state) 
            S_IDLE : begin 
                         oRoundExp      <= iExp;
                         oRoundFraction <= iFraction;
                         oDone          <= 1'b0;
                     end  
            S_ROUND: begin 
                         oRoundFraction <= { oRoundFraction[22:0],1'b0} ;
                         oRoundExp      <= oRoundExp - 1;
                         oDone          <= 1'b0;
                     end 
            S_DONE : begin 
                         oDone          <= 1'b1;
                     end
            default :begin 
                         oRoundExp      <= 8'b0;
                         oRoundFraction <= 24'b0;
                         oDone          <= 1'b0;
                     end
        endcase  
    end 
end 
endmodule 
