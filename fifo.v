//Author      : Alex Zhang (cgzhangwei@gmail.com)
//Date        : 2013-12-16
//Description : Asynchronous FIFO
module fifo (
wclk,
wrst_n,
rclk,
rrst_n,
wdata,
rdata,
wfull,
rempty,
wr,
rd
);
parameter DSIZE=8, ASIZE=4;
input wclk;
input wrst_n;
input rclk;
input rrst_n;
input wdata;
output rdata;
output wfull;
output rempty;
input wr;
input rd;

wire [DSIZE-1:0] wdata;
wire [DSIZE-1:0] rdata;
reg wfull;
reg rempty;

//Internal variables
//Many variables since it is implemented with gray code
reg [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr, wq1_rptr, rq1_wptr;
reg [ASIZE:0] rbin, wbin;
reg [DSIZE-1:0] mem[0:(1<<ASIZE)-1];
wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE  :0] rgray_next, rbin_next, wgray_next, wbin_next;
wire rempty_in, wfull_in;  

//Update the wptr and rptr
always @(posedge wclk or negedge wrst_n) begin 
    if (~wrst_n) 
        {wbin, wptr} <=0;
    else 
        {wbin, wptr} <= {wbin_next, wgray_next};
end 
assign wbin_next  = wr&~wfull ? (wbin +1) : wbin;
assign wgray_next = (wbin_next>>1)^wbin_next;
assign wfull_in   = wgray_next == {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]};  //FIXME, to make sure the wfull

assign waddr = wbin[ASIZE-1:0];

always @(posedge rclk or negedge rrst_n) begin 
    if (~rrst_n)
        {rbin, rptr} <= 0;
    else 
        {rbin, rptr} <= {rbin_next, rgray_next};
end 
assign rbin_gray = rd&~rempty ? (rbin+1): rbin;
assign rgray_next = (rbin_next>>1)^rbin_next;
assign rempty_in  = (rgray_next == rq2_wptr);

assign waddr = rbin[ASIZE-1 :0];

//Synchronize signals need to 2 cycles to ensure NO glitch. 
//synchronize the rptr to wr domain
always @(posedge wclk or negedge wrst_n) 
    if (~wrst_n) 
        {wq2_rptr, wq1_rptr} <= 0;
    else 
        {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
//synchronize the wptr to rd domain 
always @(posedge rclk or negedge rrst_n) 
    if(~rrst_n)
        {rq2_wptr, rq1_wptr} <= 0;
    else 
        {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};

//update the peripheral signals
always @(posedge wclk or negedge wrst_n)
    if(~wrst_n)
        wfull <= 0;
    else 
        wfull <= wfull_in;

always @(posedge rclk or negedge rrst_n)
    if(~rrst_n)
        rempty <= 0;
    else 
        rempty <= rempty_in; 

//Update the data content
assign rdata = mem[raddr];
always @(posedge wclk )
    mem[waddr] <= wdata;

endmodule
