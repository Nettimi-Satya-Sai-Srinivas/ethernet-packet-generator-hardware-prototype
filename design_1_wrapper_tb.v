`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2021 04:18:17 PM
// Design Name: 
// Module Name: design_1_wrapper_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module design_1_wrapper_tb
    #(parameter
        //  Testbench parameters
        numSamples  =   64
     )
    ();
    
    //  Inputs
    reg           clock;
    reg           reset;
    reg [7:0]     din;
    reg           wr_en;
    
    reg           start;
    reg [47:0]    dMAC;
    reg [47:0]    sMAC;       
    reg [15:0]    length;
    reg [31:0]    FCS;
    
    //  Outputs
    wire          empty;
    wire          full;
    
    wire          packet;
    wire          packetValid;
    
    //  Testbench variables
    integer index;
    
    //  Testbench register file
    reg [7 : 0] tbrf [0 : (numSamples - 1)];
    
    //  DUT Instantiation
    design_1_wrapper
        DUT(
            .FCS            (FCS),
            .clock          (clock),
            .dMAC           (dMAC),
            .din            (din),
            .empty          (empty),
            .full           (full),
            .length         (length),
            .packet         (packet),
            .packetValid    (packetValid),
            .reset          (reset),
            .sMAC           (sMAC),
            .start          (start),
            .wr_en          (wr_en)
           );
           
    //  DUT input initial conditions
    initial
    begin
        clock   =   0;
        reset   =   0;
        din     =   0;
        wr_en   =   0;
        start   =   0;
        dMAC    =   0;
        sMAC    =   0;
        length  =   0;
    end
    
    //  Open text file in read mode and load its contents into the testbench register file
    initial
        $readmemb("E:/Drive_E1/Others/ethernetPacketGenerator/ethernetPacketGenerator.srcs/sim_1/new/dataIn.txt", tbrf);
    
    //  Clock
    always  #5  clock   =   ~clock;
    
    //  Test
    initial
    begin
        #10 reset   =   1'b1;
        #10 reset   =   1'b0;
        
        #10;
        //  Send data to FIFO
        for(index = 0; index < numSamples; index = index + 1)
        begin
            @(posedge clock)    wr_en   =   1'b1;    
            @(posedge clock)    din     =   tbrf[index];
            #10;                        
        end
        wr_en   =   1'b0;  
        
        #10     dMAC    =   48'hA0_8C_FD_7E_8F_F3;
                sMAC    =   48'h76_DF_BF_88_3A_A9;
                length  =   16'd64;
                FCS     =   32'h31_57_CB_27;
                
        #10 start   =   1'b1;
        #10 start   =   1'b0;
        
    end
    
endmodule

//////////////////////////////////////////////////////////////////////////////////