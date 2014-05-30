//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : May. 29. 2014
//Description : Float point signed division implemetation with Taylor Series: a/b
//              Bug : The significand of 23 bits needs to be further improved.
module float_point_divide(
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
output oDone;
output oZ;
wire [31:0] iA;
wire [31:0] iB;
reg  [31:0] oZ;
reg         oDone;
reg  [31:0] ppA;
reg  [31:0] ppB;
wire [31:0] wA_X_LUT;
wire        wSelA;
wire [31:0] wMuxAOut;
wire [31:0] wTaylor;
wire [31:0] wComplement;
wire        wSelB;
wire [31:0] wMuxBOut;
wire [31:0] wMuxCOut;
wire        wSelC;
wire [31:0] wB_X_LUT;
wire        wValidFP_A;
wire        wValidFP_B;
wire        wDoneFP_A;
wire        wDoneFP_B;
wire        wDone;


always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        ppA <= 32'b0;
        ppB <= 32'b0;
    end else begin 
        ppA <= {iA[31]^iB[31], iA[30:23]-iB[30:23]-8'd127, iA[22:0] }; //FIXME, need the ExpSub module to record the overflow.
        ppB <= {1'b0, 8'b0111_1111, 1'b1, iB[22:1]};                   //0.5<= iA <1.0
    end 
end 

mux_2 #(.DATA_WIDTH(32)) muxTwoA(
  .iZeroBranch(ppA),
  .iOneBranch(wA_X_LUT),
  .iSel(wSelA),
  .oMux(wMuxAOut)
);

mux_2 #(.DATA_WIDTH(32)) muxTwoB(
  .iZeroBranch(wTaylor),
  .iOneBranch(wComplement),
  .iSel(wSelB),
  .oMux(wMuxBOut)
);

mux_2 #(.DATA_WIDTH(32)) muxTwoC(
  .iZeroBranch(wTaylor),
  .iOneBranch(wComplement),
  .iSel(wSelC),
  .oMux(wMuxCOut)
);

lut_1PlusX_1AddXX_1AddXXXX ROM(
  .iB1_8(ppB[21:13]),
  .oTaylor(wTaylor)
);

complement comp_2(
  .iCompExp(wB_X_LUT[31:23]),
  .iCompFrac(wB_X_LUT[22:0]),
  .oComplement(wComplement)
);
float_point_multiply FP_A(
  .clk(clk),
  .resetn(resetn),
  .iA(wMuxAOut),
  .iB(wMuxBOut),
  .iValid(wValidFP_A),
  .oDone(wDoneFP_A),
  .oZ(wA_X_LUT)
);

float_point_multiply FP_B(
  .clk(clk),
  .resetn(resetn),
  .iA(ppB),
  .iB(wMuxCOut),
  .iValid(wValidFP_B),
  .oDone(wDoneFB_B),
  .oZ(wB_X_LUT)
);

control FP_control (
  .clk(clk),
  .resetn(resetn),
  .iValid(iValid),
  .iDoneFP_A(wDoneFP_A),
  .iDoneFP_B(wDoneFP_B),
  .oSelA(wSelA),
  .oSelB(wSelB),
  .oSelC(wSelC),
  .oValidFP_A(wValidFP_A),
  .oValidFP_B(wValidFP_B),
  .oDone(wDone)
);


always @(posedge clk or negedge resetn) begin 
    if(~resetn) begin 
        oZ <= 32'b0;
    end else begin
        if (wDone) 
           oZ <= wA_X_LUT;
        else 
           oZ <= 32'b0;
    end 
end 

endmodule //float_point_divide

module control (
clk,
resetn,
iValid,
iDoneFP_A,
iDoneFP_B,
oSelA,
oSelB,
oSelC,
oValidFP_A,
oValidFP_B,
oDone
);
input clk;
input resetn;
input iValid;
input iDoneFP_A;
input iDoneFP_B;
output oSelA;
output oSelB;
output oSelC;
output oValidFP_A;
output oValidFP_B;
output oDone;

reg  oSelA;
reg  oSelB;
reg  oSelC;
reg  oValidFP_A;
reg  oValidFP_B;
reg  oDone;

reg [2:0]  state;
reg [2:0]  next_state;
reg [3:0]  counter;

parameter S_IDLE   = 3'b000;
parameter S_PP_ONE = 3'b001;
parameter S_PP_TWO = 3'b010;
parameter S_PP_THR = 3'b011;
parameter S_DONE   = 3'b100;
parameter TIMER    = 4;

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
                     if (iValid )
                         next_state = S_PP_ONE;
                     else if (iDoneFP_A & iDoneFP_B && counter ==4'b1)
                         next_state = S_PP_TWO;
                     else if (iDoneFP_A & iDoneFP_B && counter ==4'b10)
                         next_state = S_PP_THR;
                     else if (iDoneFP_A & iDoneFP_B && counter ==4'b11)
                         next_state = S_DONE;
                 end 
         S_PP_ONE: begin 
                      next_state = S_IDLE;
                   end 
         S_PP_TWO: begin 
                      next_state = S_IDLE;
                   end 
         S_PP_THR: begin 
                      next_state = S_IDLE;
                   end 
         S_DONE  : begin
                      next_state = S_IDLE;
                   end
        default : next_state <= S_IDLE;
    endcase 
end 
always @(posedge clk or negedge resetn) begin 
    if (~resetn) begin 
        oSelA      <= 1'b0;
        oSelB      <= 1'b0;
        oSelC      <= 1'b0;
        oValidFP_A <= 1'b0;
        oValidFP_B <= 1'b0;
        oDone      <= 1'b0;
        counter    <= 4'b0;
    end else begin 
        if (iValid )
             counter <=4'b0;
        else if (iDoneFP_A & iDoneFP_B)
             counter <= counter+4'b1; 
        case (state) 
            S_IDLE : begin 
                         oSelA      <= 1'b0;
                         oSelB      <= 1'b0;
                         oSelC      <= 1'b0;
                         oValidFP_A <= 1'b0;
                         oValidFP_B <= 1'b0;
                         oDone      <= 1'b0;
                     end 
            S_PP_ONE: begin 
                         oSelA      <= 1'b0;
                         oSelB      <= 1'b0;
                         oSelC      <= 1'b0;
                         oValidFP_A <= 1'b1;
                         oValidFP_B <= 1'b1;
                         oDone      <= 1'b0;
                      end
            S_PP_TWO: begin 
                         oSelA      <= 1'b1;
                         oSelB      <= 1'b1;
                         oSelC      <= 1'b1;
                         oValidFP_A <= 1'b1;
                         oValidFP_B <= 1'b1;
                         oDone      <= 1'b0;
                      end
            S_PP_THR: begin 
                         oSelA      <= 1'b1;
                         oSelB      <= 1'b1;
                         oSelC      <= 1'b0;
                         oValidFP_A <= 1'b1;
                         oValidFP_B <= 1'b0;
                         oDone      <= 1'b0;
                      end
            S_DONE :  begin 
                         oSelA      <= 1'b0;
                         oSelB      <= 1'b0;
                         oSelC      <= 1'b0;
                         oValidFP_A <= 1'b0;
                         oValidFP_B <= 1'b0;
                         oDone      <= 1'b1;
                      end
        endcase
    end 

end  

endmodule 

module complement(
iCompExp,
iCompFrac,
oComplement
);
input  iCompExp;
input  iCompFrac;
output oComplement;
wire [8:0]  iCompExp;
wire [22:0] iCompFrac;
reg  [31:0] oComplement;

always @(iCompExp or iCompFrac) begin 
    oComplement =  {iCompExp, ~iCompFrac+23'b1};
end 
endmodule //complement

// The LUT is generated via float_point_binary3.c
module lut_1PlusX_1AddXX_1AddXXXX(
iB1_8,
oTaylor
);
input iB1_8;
output oTaylor;
wire [7:0] iB1_8;
reg  [31:0] oTaylor;
always @(iB1_8) begin 
    case (iB1_8)
        8'd000 :  oTaylor = 32'b00111111111111110000000000000000;
        8'd001 :  oTaylor = 32'b00111111111111100000100111011011;
        8'd002 :  oTaylor = 32'b00111111111111010001010101100111;
        8'd003 :  oTaylor = 32'b00111111111111000010001010100010;
        8'd004 :  oTaylor = 32'b00111111111110110011000110001000;
        8'd005 :  oTaylor = 32'b00111111111110100100001000010011;
        8'd006 :  oTaylor = 32'b00111111111110010101010001000011;
        8'd007 :  oTaylor = 32'b00111111111110000110100000010100;
        8'd008 :  oTaylor = 32'b00111111111101110111110101111111;
        8'd009 :  oTaylor = 32'b00111111111101101001010010000100;
        8'd010 :  oTaylor = 32'b00111111111101011010110100011101;
        8'd011 :  oTaylor = 32'b00111111111101001100011101000111;
        8'd012 :  oTaylor = 32'b00111111111100111110001100000001;
        8'd013 :  oTaylor = 32'b00111111111100110000000001000100;
        8'd014 :  oTaylor = 32'b00111111111100100001111100001110;
        8'd015 :  oTaylor = 32'b00111111111100010011111101011100;
        8'd016 :  oTaylor = 32'b00111111111100000110000100101011;
        8'd017 :  oTaylor = 32'b00111111111011111000010001110110;
        8'd018 :  oTaylor = 32'b00111111111011101010100100111100;
        8'd019 :  oTaylor = 32'b00111111111011011100111101111000;
        8'd020 :  oTaylor = 32'b00111111111011001111011100100111;
        8'd021 :  oTaylor = 32'b00111111111011000010000001000101;
        8'd022 :  oTaylor = 32'b00111111111010110100101011010010;
        8'd023 :  oTaylor = 32'b00111111111010100111011011000111;
        8'd024 :  oTaylor = 32'b00111111111010011010010000100011;
        8'd025 :  oTaylor = 32'b00111111111010001101001011100100;
        8'd026 :  oTaylor = 32'b00111111111010000000001100000101;
        8'd027 :  oTaylor = 32'b00111111111001110011010010000001;
        8'd028 :  oTaylor = 32'b00111111111001100110011101011010;
        8'd029 :  oTaylor = 32'b00111111111001011001101110001011;
        8'd030 :  oTaylor = 32'b00111111111001001101000100001110;
        8'd031 :  oTaylor = 32'b00111111111001000000011111100100;
        8'd032 :  oTaylor = 32'b00111111111000110100000000001000;
        8'd033 :  oTaylor = 32'b00111111111000100111100101111001;
        8'd034 :  oTaylor = 32'b00111111111000011011010000110010;
        8'd035 :  oTaylor = 32'b00111111111000001111000000110001;
        8'd036 :  oTaylor = 32'b00111111111000000010110101110100;
        8'd037 :  oTaylor = 32'b00111111110111110110101111110111;
        8'd038 :  oTaylor = 32'b00111111110111101010101110111001;
        8'd039 :  oTaylor = 32'b00111111110111011110110010110110;
        8'd040 :  oTaylor = 32'b00111111110111010010111011101001;
        8'd041 :  oTaylor = 32'b00111111110111000111001001010100;
        8'd042 :  oTaylor = 32'b00111111110110111011011011110010;
        8'd043 :  oTaylor = 32'b00111111110110101111110011000000;
        8'd044 :  oTaylor = 32'b00111111110110100100001110111101;
        8'd045 :  oTaylor = 32'b00111111110110011000101111100100;
        8'd046 :  oTaylor = 32'b00111111110110001101010100110100;
        8'd047 :  oTaylor = 32'b00111111110110000001111110101010;
        8'd048 :  oTaylor = 32'b00111111110101110110101101000100;
        8'd049 :  oTaylor = 32'b00111111110101101011100000000000;
        8'd050 :  oTaylor = 32'b00111111110101100000010111011011;
        8'd051 :  oTaylor = 32'b00111111110101010101010011010000;
        8'd052 :  oTaylor = 32'b00111111110101001010010011100011;
        8'd053 :  oTaylor = 32'b00111111110100111111011000001011;
        8'd054 :  oTaylor = 32'b00111111110100110100100001001000;
        8'd055 :  oTaylor = 32'b00111111110100101001101110011001;
        8'd056 :  oTaylor = 32'b00111111110100011110111111111001;
        8'd057 :  oTaylor = 32'b00111111110100010100010101101001;
        8'd058 :  oTaylor = 32'b00111111110100001001101111100110;
        8'd059 :  oTaylor = 32'b00111111110011111111001101101100;
        8'd060 :  oTaylor = 32'b00111111110011110100101111111000;
        8'd061 :  oTaylor = 32'b00111111110011101010010110001100;
        8'd062 :  oTaylor = 32'b00111111110011100000000000100000;
        8'd063 :  oTaylor = 32'b00111111110011010101101110110110;
        8'd064 :  oTaylor = 32'b00111111110011001011100001001100;
        8'd065 :  oTaylor = 32'b00111111110011000001010111011110;
        8'd066 :  oTaylor = 32'b00111111110010110111010001101011;
        8'd067 :  oTaylor = 32'b00111111110010101101001111101111;
        8'd068 :  oTaylor = 32'b00111111110010100011010001101011;
        8'd069 :  oTaylor = 32'b00111111110010011001010111011011;
        8'd070 :  oTaylor = 32'b00111111110010001111100000111101;
        8'd071 :  oTaylor = 32'b00111111110010000101101110010001;
        8'd072 :  oTaylor = 32'b00111111110001111011111111010001;
        8'd073 :  oTaylor = 32'b00111111110001110010010011111110;
        8'd074 :  oTaylor = 32'b00111111110001101000101100010110;
        8'd075 :  oTaylor = 32'b00111111110001011111001000010111;
        8'd076 :  oTaylor = 32'b00111111110001010101100111111110;
        8'd077 :  oTaylor = 32'b00111111110001001100001011001010;
        8'd078 :  oTaylor = 32'b00111111110001000010110001110110;
        8'd079 :  oTaylor = 32'b00111111110000111001011100000111;
        8'd080 :  oTaylor = 32'b00111111110000110000001001110101;
        8'd081 :  oTaylor = 32'b00111111110000100110111011000001;
        8'd082 :  oTaylor = 32'b00111111110000011101101111100111;
        8'd083 :  oTaylor = 32'b00111111110000010100100111100111;
        8'd084 :  oTaylor = 32'b00111111110000001011100011000000;
        8'd085 :  oTaylor = 32'b00111111110000000010100001101111;
        8'd086 :  oTaylor = 32'b00111111101111111001100011110000;
        8'd087 :  oTaylor = 32'b00111111101111110000101001000111;
        8'd088 :  oTaylor = 32'b00111111101111100111110001101100;
        8'd089 :  oTaylor = 32'b00111111101111011110111101100010;
        8'd090 :  oTaylor = 32'b00111111101111010110001100100101;
        8'd091 :  oTaylor = 32'b00111111101111001101011110110100;
        8'd092 :  oTaylor = 32'b00111111101111000100110100001100;
        8'd093 :  oTaylor = 32'b00111111101110111100001100101110;
        8'd094 :  oTaylor = 32'b00111111101110110011101000010110;
        8'd095 :  oTaylor = 32'b00111111101110101011000111000100;
        8'd096 :  oTaylor = 32'b00111111101110100010101000110110;
        8'd097 :  oTaylor = 32'b00111111101110011010001101101010;
        8'd098 :  oTaylor = 32'b00111111101110010001110101011110;
        8'd099 :  oTaylor = 32'b00111111101110001001100000010010;
        8'd100 :  oTaylor = 32'b00111111101110000001001110000011;
        8'd101 :  oTaylor = 32'b00111111101101111000111110110000;
        8'd102 :  oTaylor = 32'b00111111101101110000110010010111;
        8'd103 :  oTaylor = 32'b00111111101101101000101000111001;
        8'd104 :  oTaylor = 32'b00111111101101100000100010010000;
        8'd105 :  oTaylor = 32'b00111111101101011000011110100000;
        8'd106 :  oTaylor = 32'b00111111101101010000011101100011;
        8'd107 :  oTaylor = 32'b00111111101101001000011111011010;
        8'd108 :  oTaylor = 32'b00111111101101000000100100000010;
        8'd109 :  oTaylor = 32'b00111111101100111000101011011011;
        8'd110 :  oTaylor = 32'b00111111101100110000110101100001;
        8'd111 :  oTaylor = 32'b00111111101100101001000010010111;
        8'd112 :  oTaylor = 32'b00111111101100100001010001111010;
        8'd113 :  oTaylor = 32'b00111111101100011001100100000111;
        8'd114 :  oTaylor = 32'b00111111101100010001111000111110;
        8'd115 :  oTaylor = 32'b00111111101100001010010000011100;
        8'd116 :  oTaylor = 32'b00111111101100000010101010100011;
        8'd117 :  oTaylor = 32'b00111111101011111011000111001110;
        8'd118 :  oTaylor = 32'b00111111101011110011100110011110;
        8'd119 :  oTaylor = 32'b00111111101011101100001000010001;
        8'd120 :  oTaylor = 32'b00111111101011100100101100100110;
        8'd121 :  oTaylor = 32'b00111111101011011101010011011100;
        8'd122 :  oTaylor = 32'b00111111101011010101111100110010;
        8'd123 :  oTaylor = 32'b00111111101011001110101000100101;
        8'd124 :  oTaylor = 32'b00111111101011000111010110110101;
        8'd125 :  oTaylor = 32'b00111111101011000000000111100010;
        8'd126 :  oTaylor = 32'b00111111101010111000111010100110;
        8'd127 :  oTaylor = 32'b00111111101010110001110000001000;
        8'd128 :  oTaylor = 32'b00111111101010101010101000000000;
        8'd129 :  oTaylor = 32'b00111111101010100011100010001111;
        8'd130 :  oTaylor = 32'b00111111101010011100011110110110;
        8'd131 :  oTaylor = 32'b00111111101010010101011101101110;
        8'd132 :  oTaylor = 32'b00111111101010001110011110111100;
        8'd133 :  oTaylor = 32'b00111111101010000111100010011100;
        8'd134 :  oTaylor = 32'b00111111101010000000101000001110;
        8'd135 :  oTaylor = 32'b00111111101001111001110000010001;
        8'd136 :  oTaylor = 32'b00111111101001110010111010100001;
        8'd137 :  oTaylor = 32'b00111111101001101100000111000000;
        8'd138 :  oTaylor = 32'b00111111101001100101010101101110;
        8'd139 :  oTaylor = 32'b00111111101001011110100110100111;
        8'd140 :  oTaylor = 32'b00111111101001010111111001101010;
        8'd141 :  oTaylor = 32'b00111111101001010001001110110111;
        8'd142 :  oTaylor = 32'b00111111101001001010100110001101;
        8'd143 :  oTaylor = 32'b00111111101001000011111111101100;
        8'd144 :  oTaylor = 32'b00111111101000111101011011010010;
        8'd145 :  oTaylor = 32'b00111111101000110110111000111101;
        8'd146 :  oTaylor = 32'b00111111101000110000011000101110;
        8'd147 :  oTaylor = 32'b00111111101000101001111010100010;
        8'd148 :  oTaylor = 32'b00111111101000100011011110011010;
        8'd149 :  oTaylor = 32'b00111111101000011101000100010011;
        8'd150 :  oTaylor = 32'b00111111101000010110101100001101;
        8'd151 :  oTaylor = 32'b00111111101000010000010110001001;
        8'd152 :  oTaylor = 32'b00111111101000001010000010000001;
        8'd153 :  oTaylor = 32'b00111111101000000011101111111010;
        8'd154 :  oTaylor = 32'b00111111100111111101011111110000;
        8'd155 :  oTaylor = 32'b00111111100111110111010001100011;
        8'd156 :  oTaylor = 32'b00111111100111110001000101010000;
        8'd157 :  oTaylor = 32'b00111111100111101010111010111001;
        8'd158 :  oTaylor = 32'b00111111100111100100110010011001;
        8'd159 :  oTaylor = 32'b00111111100111011110101011110110;
        8'd160 :  oTaylor = 32'b00111111100111011000100111001001;
        8'd161 :  oTaylor = 32'b00111111100111010010100100010100;
        8'd162 :  oTaylor = 32'b00111111100111001100100011010101;
        8'd163 :  oTaylor = 32'b00111111100111000110100100001010;
        8'd164 :  oTaylor = 32'b00111111100111000000100110110101;
        8'd165 :  oTaylor = 32'b00111111100110111010101011010100;
        8'd166 :  oTaylor = 32'b00111111100110110100110001100110;
        8'd167 :  oTaylor = 32'b00111111100110101110111001101011;
        8'd168 :  oTaylor = 32'b00111111100110101001000011100000;
        8'd169 :  oTaylor = 32'b00111111100110100011001111000101;
        8'd170 :  oTaylor = 32'b00111111100110011101011100011101;
        8'd171 :  oTaylor = 32'b00111111100110010111101011100010;
        8'd172 :  oTaylor = 32'b00111111100110010001111100010110;
        8'd173 :  oTaylor = 32'b00111111100110001100001110110110;
        8'd174 :  oTaylor = 32'b00111111100110000110100011000011;
        8'd175 :  oTaylor = 32'b00111111100110000000111000111110;
        8'd176 :  oTaylor = 32'b00111111100101111011010000100010;
        8'd177 :  oTaylor = 32'b00111111100101110101101001110010;
        8'd178 :  oTaylor = 32'b00111111100101110000000100101011;
        8'd179 :  oTaylor = 32'b00111111100101101010100001001101;
        8'd180 :  oTaylor = 32'b00111111100101100100111111011001;
        8'd181 :  oTaylor = 32'b00111111100101011111011111001010;
        8'd182 :  oTaylor = 32'b00111111100101011010000000100010;
        8'd183 :  oTaylor = 32'b00111111100101010100100011100100;
        8'd184 :  oTaylor = 32'b00111111100101001111001000000111;
        8'd185 :  oTaylor = 32'b00111111100101001001101110010001;
        8'd186 :  oTaylor = 32'b00111111100101000100010110000000;
        8'd187 :  oTaylor = 32'b00111111100100111110111111010001;
        8'd188 :  oTaylor = 32'b00111111100100111001101010000101;
        8'd189 :  oTaylor = 32'b00111111100100110100010110011100;
        8'd190 :  oTaylor = 32'b00111111100100101111000100010010;
        8'd191 :  oTaylor = 32'b00111111100100101001110011101011;
        8'd192 :  oTaylor = 32'b00111111100100100100100100100100;
        8'd193 :  oTaylor = 32'b00111111100100011111010110111100;
        8'd194 :  oTaylor = 32'b00111111100100011010001010110100;
        8'd195 :  oTaylor = 32'b00111111100100010101000000001000;
        8'd196 :  oTaylor = 32'b00111111100100001111110110111100;
        8'd197 :  oTaylor = 32'b00111111100100001010101111001011;
        8'd198 :  oTaylor = 32'b00111111100100000101101000110111;
        8'd199 :  oTaylor = 32'b00111111100100000000100100000001;
        8'd200 :  oTaylor = 32'b00111111100011111011100000100011;
        8'd201 :  oTaylor = 32'b00111111100011110110011110100001;
        8'd202 :  oTaylor = 32'b00111111100011110001011101111010;
        8'd203 :  oTaylor = 32'b00111111100011101100011110101011;
        8'd204 :  oTaylor = 32'b00111111100011100111100000110110;
        8'd205 :  oTaylor = 32'b00111111100011100010100100011000;
        8'd206 :  oTaylor = 32'b00111111100011011101101001010001;
        8'd207 :  oTaylor = 32'b00111111100011011000101111100011;
        8'd208 :  oTaylor = 32'b00111111100011010011110111001011;
        8'd209 :  oTaylor = 32'b00111111100011001111000000001001;
        8'd210 :  oTaylor = 32'b00111111100011001010001010011101;
        8'd211 :  oTaylor = 32'b00111111100011000101010110000100;
        8'd212 :  oTaylor = 32'b00111111100011000000100011000001;
        8'd213 :  oTaylor = 32'b00111111100010111011110001010000;
        8'd214 :  oTaylor = 32'b00111111100010110111000000110100;
        8'd215 :  oTaylor = 32'b00111111100010110010010001101011;
        8'd216 :  oTaylor = 32'b00111111100010101101100011110010;
        8'd217 :  oTaylor = 32'b00111111100010101000110111001100;
        8'd218 :  oTaylor = 32'b00111111100010100100001011111001;
        8'd219 :  oTaylor = 32'b00111111100010011111100001110101;
        8'd220 :  oTaylor = 32'b00111111100010011010111001000000;
        8'd221 :  oTaylor = 32'b00111111100010010110010001011100;
        8'd222 :  oTaylor = 32'b00111111100010010001101011000111;
        8'd223 :  oTaylor = 32'b00111111100010001101000110000001;
        8'd224 :  oTaylor = 32'b00111111100010001000100010001001;
        8'd225 :  oTaylor = 32'b00111111100010000011111111011110;
        8'd226 :  oTaylor = 32'b00111111100001111111011110000001;
        8'd227 :  oTaylor = 32'b00111111100001111010111101101111;
        8'd228 :  oTaylor = 32'b00111111100001110110011110101011;
        8'd229 :  oTaylor = 32'b00111111100001110010000000110011;
        8'd230 :  oTaylor = 32'b00111111100001101101100100000101;
        8'd231 :  oTaylor = 32'b00111111100001101001001000100011;
        8'd232 :  oTaylor = 32'b00111111100001100100101110001010;
        8'd233 :  oTaylor = 32'b00111111100001100000010100111100;
        8'd234 :  oTaylor = 32'b00111111100001011011111100111000;
        8'd235 :  oTaylor = 32'b00111111100001010111100101111100;
        8'd236 :  oTaylor = 32'b00111111100001010011010000001001;
        8'd237 :  oTaylor = 32'b00111111100001001110111011011110;
        8'd238 :  oTaylor = 32'b00111111100001001010100111111001;
        8'd239 :  oTaylor = 32'b00111111100001000110010101011101;
        8'd240 :  oTaylor = 32'b00111111100001000010000100001000;
        8'd241 :  oTaylor = 32'b00111111100000111101110011111001;
        8'd242 :  oTaylor = 32'b00111111100000111001100100110001;
        8'd243 :  oTaylor = 32'b00111111100000110101010110101100;
        8'd244 :  oTaylor = 32'b00111111100000110001001001101111;
        8'd245 :  oTaylor = 32'b00111111100000101100111101110101;
        8'd246 :  oTaylor = 32'b00111111100000101000110010111111;
        8'd247 :  oTaylor = 32'b00111111100000100100101001001111;
        8'd248 :  oTaylor = 32'b00111111100000100000100000100000;
        8'd249 :  oTaylor = 32'b00111111100000011100011000110101;
        8'd250 :  oTaylor = 32'b00111111100000011000010010001110;
        8'd251 :  oTaylor = 32'b00111111100000010100001100101000;
        8'd252 :  oTaylor = 32'b00111111100000010000001000000100;
        8'd253 :  oTaylor = 32'b00111111100000001100000100100010;
        8'd254 :  oTaylor = 32'b00111111100000001000000010000000;
        8'd255 :  oTaylor = 32'b00111111100000000100000000100000;
        default : oTaylor = 32'b00111111111111110000000000000000; //X=-.5
    endcase
end 

endmodule //lut_1PlusX_1AddXX_1AddXXXX


