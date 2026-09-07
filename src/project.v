`default_nettype none

module tt_um_ntt_top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire [11:0] data_in_bus;
    wire [11:0] data_out_bus;
    wire start;
    wire mode;
    wire done;
    wire ch_sel; 

    wire [11:0] data_out_0;
    wire [11:0] data_out_1;

    // Thanh ghi chốt dữ liệu ngõ vào
    reg [11:0] data_in_0_reg;
    reg [11:0] data_in_1_reg;

    // 1. MAPPING INPUTS
    assign data_in_bus[7:0]  = ui_in[7:0];        
    assign data_in_bus[11:8] = uio_in[3:0];       
    assign start             = uio_in[4];         
    assign mode              = uio_in[5];         
    assign ch_sel            = uio_in[7]; // 0: Kênh 0, 1: Kênh 1

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_0_reg <= 12'd0;
            data_in_1_reg <= 12'd0;
        end else begin
            if (!ch_sel) data_in_0_reg <= data_in_bus;
            else         data_in_1_reg <= data_in_bus;
        end
    end

    // 2. MAPPING OUTPUTS
    assign data_out_bus  = ch_sel ? data_out_1 : data_out_0;

    assign uo_out[7:0]   = data_out_bus[7:0];     
    assign uio_out[3:0]  = data_out_bus[11:8];    
    assign uio_out[4]    = 1'b0;                  
    assign uio_out[5]    = 1'b0;                  
    assign uio_out[6]    = done;                  
    assign uio_out[7]    = 1'b0;                  

    // 3. ĐIỀU KHIỂN HƯỚNG PIN
    assign uio_oe[3:0] = {4{done}}; 
    assign uio_oe[4]   = 1'b0;                    
    assign uio_oe[5]   = 1'b0;                    
    assign uio_oe[6]   = 1'b1;                    
    assign uio_oe[7]   = 1'b0;                    

    wire _unused = &{ena, uio_in[6], 1'b0};

    // 4. INSTANTIATE DUAL TOP
    ntt_top_dual u_ntt_top_dual (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .data_in_0(data_in_0_reg),
        .data_in_1(data_in_1_reg),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .done(done)
    );

endmodule
