module test;
reg clk;
reg resetn;
reg [31:0] rA, rB;
wire [31:0] wF;
wire        wDone;
reg [1:0] rOp;
event start_sim_evt;
event end_sim_evt;

float_point_add  fp_adder(
  .clk(clk),
  .resetn(resetn),
  .iA(rA),
  .iB(rB),
  .iOp(rOp),
  .oF(wF),
  .oDone(wDone)
);
initial begin 
    basic;
end 
initial begin 
    $fsdbDumpfile("./out/fp_adder.fsdb");
    $fsdbDumpvars(0, test);
end 
task basic ;
fork
    drive_clock;
    reset_unit;
    drive_sim;
    monitor_sim;
join 
endtask 
task monitor_sim;
   begin 
   @(end_sim_evt);
   #10;
   $display("Test End");
   $finish;
   end 
endtask
task reset_unit;
    begin 
        #5;
        resetn = 1;
        #10;
        resetn = 0;
        rA=0;
        rB=0;
        rOp = 0;
        #10;   //Before Reset is done, the Bit should have its real value
        #20;
        resetn = 1;
        ->start_sim_evt;
        $display("Reset is done");
        end
endtask 
task  drive_clock;
    begin 
        clk = 0;
        forever begin 
        #5 clk = ~clk;
        end 
    end 
endtask
task  drive_sim;
    @(start_sim_evt);
    @(posedge clk);
    //        0    1     2   3    4    5    6     7
    //Same exp, overflow, unsigned A,B, Add
    //12.5 + 8.5 = 21
    rA = 32'b0100_0001_0100_1000_0000_0000_0000_0000;
    rB = 32'b0100_0001_0000_1000_0000_0000_0000_0000;
    rOp = 2'b01; //Add is 01
    @(posedge clk);
    rA = 0;
    rB = 0;
    rOp = 2'b00;
    //Different exp A>B, unsigned A,B, Add 
    //@(posedge clk);

    //rA=832, rB=10, 
    //Test the large different float point value
    repeat (5) @(posedge clk);
    rA = 32'b0100_0100_0101_0000_0000_0000_0000_0000;
    rB = 32'b0100_0001_0010_0000_0000_0000_0000_0000;
    rOp = 2'b10;
    @(posedge clk);
    rA = 0;
    rB = 0;
    rOp=2'b00;


    //Different exp, A<B, signed A,B, Add
    //@(posedge clk);
    //rA = 32'b0100_0001_0101_0000_0000_0000_0000_0000;
    //rB = 32'b0100_0010_0101_0000_0000_0000_0000_0000;
    //rA=1.75, rB=-1.3125 
    //rA+rB=1.75-1.3125=0.4375
    repeat (5) @(posedge clk);
    rA = 32'b0011_1111_1110_0000_0000_0000_0000_0000;
    rB = 32'b1011_1111_1010_1000_0000_0000_0000_0000;
    rOp = 2'b01; //Add is 01

    @(posedge clk);
    rA = 0;
    rB = 0;
    rOp=2'b00;
    #100;
    ->end_sim_evt;
endtask 

endmodule 
