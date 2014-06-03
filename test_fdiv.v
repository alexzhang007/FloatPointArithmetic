module test;
reg clk;
reg resetn;
reg  [31:0] rA, rB;
wire [31:0] wF;
wire        wDone;
reg         rValid;
reg [3:0]   rMask;
reg [1:0]   rOp;
event start_sim_evt;
event end_sim_evt;

float_point_divide  fp_div(
  .clk(clk),
  .resetn(resetn),
  .iA(rA),
  .iB(rB),
  .iValid(rValid),
  .iMask(rMask),
  .oDone(wDone),
  .oZ(wF)
);
initial begin 
    basic;
end 
initial begin 
    $fsdbDumpfile("./out/fp_divider.fsdb");
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
        rValid = 0;
        rMask  = 0;
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
    //1.5 / .5 = 3 
    rA = 32'b0011_1111_1100_0000_0000_0000_0000_0000;
    rB = 32'b0011_1111_0000_0000_0000_0000_0000_0000;
    rValid =1'b1;
    //@(posedge clk);
    //rA = 0;
    //rB = 0;
    //rValid = 1'b0;
    ////1.5 / .25 = 6 
    @(posedge clk);
    rA = 0; //32'b0011_1111_1100_0000_0000_0000_0000_0000;
    rB = 0; //32'b0011_1110_1000_0000_0000_0000_0000_0000;
    rValid =1'b0;
    @(posedge clk);
    rA = 0;
    rB = 0;
    rValid = 1'b0;
    //1.5 / .5 = 3 
    @(posedge clk);
    rA = 32'b0011_1111_1100_0000_0000_0000_0000_0000;
    rB = 32'b0011_1111_0000_0000_0000_0000_0000_0000;
    rValid = 1'b1;
    rMask  = 4'b0101;
    @(posedge clk);
    rA = 0;
    rB = 0;
    rValid = 1'b0;
    repeat (100) @(posedge clk);
    ->end_sim_evt;
endtask 

endmodule 
