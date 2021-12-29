`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2021 10:31:07 AM
// Design Name: 
// Module Name: epg
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


module epg
    #(parameter
        dataWidth   =   8
    )
    (
        input               clock,
        input               reset,
        input               start,
        input   [47 : 0]    dMAC,
        input   [47 : 0]    sMAC,
        input   [15 : 0]    length,
        input   [ 7 : 0]    dataIn,
        input   [31 : 0]    FCS,
        output              rd_en,
        output              packet,
        output              packetValid
    );
    
    //  FSM state encoding
    localparam  s0  =   3'd0;
    localparam  s1  =   3'd1;
    localparam  s2  =   3'd2;
    localparam  s3  =   3'd3;
    localparam  s4  =   3'd4;   
    localparam  s5  =   3'd5;
    localparam  s6  =   3'd6;   
    
    //  Registers
    reg [2 : 0] state_reg,              state_next;
    reg         output_reg,             output_next;
    reg         preambleBit_reg,        preambleBit_next;
    reg [5 : 0] CounterA_reg,           CounterA_next;
    reg [2 : 0] CounterB_reg,           CounterB_next;
    reg [6 : 0] CounterC_reg,           CounterC_next;
    reg         packetValid_reg,        packetValid_next;
    reg         rd_en_reg,              rd_en_next;
    reg [7 : 0] dataIn_reg,             dataIn_next;
                
    //  Present state logic
    always@(posedge clock)
    begin
        if(~reset)
        begin
            state_reg               <=  s0;
            output_reg              <=  1'b0;
            preambleBit_reg         <=  1'b1;    
            CounterA_reg            <=  7'd0;   
            CounterB_reg            <=  3'd7;
            CounterC_reg            <=  7'd0; 
            packetValid_reg         <=  1'b0; 
            rd_en_reg               <=  1'b0;
            dataIn_reg              <=  8'd0;
        end
        else
        begin
            state_reg               <=  state_next;
            output_reg              <=  output_next;
            preambleBit_reg         <=  preambleBit_next;  
            CounterA_reg            <=  CounterA_next;  
            CounterB_reg            <=  CounterB_next;
            CounterC_reg            <=  CounterC_next;
            packetValid_reg         <=  packetValid_next;  
            rd_en_reg               <=  rd_en_next;
            dataIn_reg              <=  dataIn_next;          
        end
    end    
    
    //  Next state logic
    always@*
    begin
        state_next                  =   state_reg;
        output_next                 =   output_reg;
        preambleBit_next            =   preambleBit_reg;
        CounterA_next               =   CounterA_reg;
        CounterB_next               =   CounterB_reg;
        CounterC_next               =   CounterC_reg;
        packetValid_next            =   packetValid_reg;
        rd_en_next                  =   rd_en_reg;
        dataIn_next                 =   dataIn_reg;
        
        case(state_reg)
            s0  :   begin
                        if(start)
                        begin
                            packetValid_next    =   1'b1;
                            output_next         =   preambleBit_reg;
                            state_next          =   s1;
                        end 
                    end
                    
            
            s1  :   begin:  Preamble_and_SFD                      
                        output_next         =   ~preambleBit_reg;
                                                
                        if(CounterA_reg == 6'd62)
                        begin
                            output_next             =   1'b1;
                            preambleBit_next        =   1'b1;
                            CounterA_next           =   6'd47;
                            state_next              =   s2;
                        end
                        else
                        begin
                            preambleBit_next        =   ~preambleBit_reg;
                            CounterA_next           =   CounterA_reg + 1'b1;
                        end
                    end
                    
            s2  :   begin:  Destination_MAC
                        output_next = dMAC[CounterA_reg];
                        
                        if(CounterA_reg == 6'd0)
                        begin
                            CounterA_next           =   6'd47;
                            state_next              =   s3;
                        end
                        else
                            CounterA_next           =   CounterA_reg - 1'b1;                                                          
                    end
                    
            s3  :   begin:  Source_MAC
                        output_next = sMAC[CounterA_reg];
                        
                       if(CounterA_reg == 6'd0)
                        begin
                            CounterA_next           =   6'd15;
                            state_next              =   s4;
                        end
                        else
                            CounterA_next           =   CounterA_reg - 1'b1;    
                    end
                    
            s4  :   begin:  Length
                        output_next = length[CounterA_reg];
                        
                        if(CounterA_reg == 6'd0)
                        begin
                            CounterA_next           =   6'd0;
                            rd_en_next              =   1'b0;
                            state_next              =   s5;
                        end
                        else
                        begin
                            CounterA_next           =   CounterA_reg - 1'b1;
                            
                            if(CounterA_reg == 6'd2)
                                rd_en_next          =   1'b1;
                        end     
                    end
                    
            s5  :   begin:  Data
           
                            if(CounterB_reg ==  3'd7)
                            begin
                                output_next     =   dataIn[CounterB_reg];
                                dataIn_next     =   dataIn;
                                CounterB_next   =   CounterB_reg - 1'b1;
                            end
                            else
                            begin
                                output_next     =   dataIn_reg[CounterB_reg];
                                CounterB_next   =   CounterB_reg - 1'b1;
                                
                                if(CounterB_reg ==  3'd2)
                                begin
                                    if({9'd0, CounterC_reg} <= length)
                                    begin
                                        rd_en_next          =   1'b1;
                                        CounterC_next       =   CounterC_reg + 1'b1;                                               
                                    end
                                end
                                
                                if(CounterB_reg ==  3'd0)
                                begin
                                    rd_en_next          =   1'b0;
                                    CounterB_next       =   3'd7;
                                    
                                    if({9'd0, CounterC_reg} == length)
                                    begin
                                        CounterA_next   =   6'd31;
                                        state_next  =   s6;
                                    end                                        
                                end
                                                                 
                            end                                                                                                                                                                                                            
                    end
                    
            s6  :   begin:  Frame_check_sequence
                        output_next = FCS[CounterA_reg];
                        
                        if(CounterA_reg == 6'd0)
                        begin
                            packetValid_next    =   1'b0;
                            state_next              =   s0;
                        end                            
                        else
                            CounterA_next           =   CounterA_reg - 1'b1;
                    end                  
        endcase       
    end
    
    //  Output logic
    assign  packet      =   output_reg;
    assign  packetValid =   packetValid_reg;
    assign  rd_en       =   rd_en_reg;
    
endmodule

//////////////////////////////////////////////////////////////////////////////////