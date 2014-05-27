//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : 2013-12-18
//Description : Saturating adder with 8 bits
module sat_adder(A, B, Y);
input A;
input B;
output Y;

wire [7:0] A;
wire [7:0] B;
wire [7:0] Y;

//internal variable
wire [8:0] sum;
wire cout;

assign sum = {1'b0, a} + {1'b0, b}; 
assign cout = sum[8];

always @(sum or cout) begin 
    if (cout == 1)
        Y= 8'b1111_1111;
    else 
        Y=sum[7:0];
end 

endmodule 

