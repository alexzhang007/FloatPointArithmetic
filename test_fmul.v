module test;
reg clk;
reg resetn;
reg [31:0] rA, rB;
wire [31:0] wF;
wire        wDone;
reg [1:0] rOp;
event start_sim_evt;
event end_sim_evt;

float_point_multiply  fp_mul(
  .clk(clk),
  .resetn(resetn),
  .iA(rA),
  .iB(rB),
  .oZ(wF)
);
initial begin 
    basic;
end 
initial begin 
    $fsdbDumpfile("./out/fp_multiplier.fsdb");
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
    //12.5 * 8.5 = 106.25
    rA = 32'b0100_0001_0100_1000_0000_0000_0000_0000;
    rB = 32'b0100_0001_0000_1000_0000_0000_0000_0000;
    @(posedge clk);
    //Different exp, signed A,B
    //-50 * 8.5 = -425
    rA = 32'b1100_0010_0100_1000_0000_0000_0000_0000;
    rB = 32'b0100_0001_0000_1000_0000_0000_0000_0000;
    @(posedge clk);
    rA = 0;
    rB = 0;
    #100;
    ->end_sim_evt;
endtask 

endmodule 
