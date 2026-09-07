// `default_nettype none

// module tt_um_ntt_top (
//     input  wire [7:0] ui_in,    // Dedicated inputs
//     output wire [7:0] uo_out,   // Dedicated outputs
//     input  wire [7:0] uio_in,   // IOs: Input path
//     output wire [7:0] uio_out,  // IOs: Output path
//     output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
//     input  wire       ena,      // always 1 when the design is powered, so you can ignore it
//     input  wire       clk,      // clock
//     input  wire       rst_n     // reset_n - low to reset
// );

//     // Khai báo các dây nối trung gian
//     wire [11:0] data_in;
//     wire [11:0] data_out;
//     wire start;
//     wire mode;
//     wire done;

//     // ==========================================
//     // 1. MAPPING INPUTS
//     // ==========================================
//     assign data_in[7:0]  = ui_in[7:0];        // 8 bit thấp của data_in dùng ngõ vào chuyên dụng
//     assign data_in[11:8] = uio_in[3:0];       // 4 bit cao của data_in dùng ngõ UIO
//     assign start         = uio_in[4];         // Tín hiệu start
//     assign mode          = uio_in[5];         // Tín hiệu mode

//     // ==========================================
//     // 2. MAPPING OUTPUTS
//     // ==========================================
//     assign uo_out[7:0]   = data_out[7:0];     // 8 bit thấp của data_out xuất ra ngõ ra chuyên dụng
    
//     // Gán giá trị cho toàn bộ bus uio_out
//     assign uio_out[3:0]  = data_out[11:8];    // 4 bit cao của data_out
//     assign uio_out[4]    = 1'b0;              // Chân 4 đang làm input (start), gán uio_out = 0
//     assign uio_out[5]    = 1'b0;              // Chân 5 đang làm input (mode), gán uio_out = 0
//     assign uio_out[6]    = done;              // Chân 6 dùng làm cờ báo done
//     assign uio_out[7]    = 1'b0;              // Chân 7 không dùng, gán bằng 0

//     // ==========================================
//     // 3. ĐIỀU KHIỂN HƯỚNG PIN (uio_oe)
//     // 0 = Input, 1 = Output
//     // ==========================================
//     // Cụm uio[3:0] sẽ share pin: 
//     // - Khi done = 0 (đang tính toán): uio_oe = 0 (Làm input để nạp data_in)
//     // - Khi done = 1 (hoàn thành): uio_oe = 1 (Làm output để xuất data_out)
//     assign uio_oe[3:0] = {4{done}}; 
    
//     assign uio_oe[4]   = 1'b0;                // Luôn là ngõ vào (start)
//     assign uio_oe[5]   = 1'b0;                // Luôn là ngõ vào (mode)
//     assign uio_oe[6]   = 1'b1;                // Luôn là ngõ ra (cờ done)
//     assign uio_oe[7]   = 1'b0;                // Không dùng (Set ngõ vào cho an toàn)

//     // Xử lý các tín hiệu không sử dụng để tránh warning khi tổng hợp
//     wire _unused = &{ena, uio_in[7:6], 1'b0};

//     // ==========================================
//     // 4. KHỞI TẠO KHỐI TOP-LEVEL CỦA BẠN
//     // ==========================================
//     ntt_top u_ntt_top (
//         .clk(clk),
//         .rst_n(rst_n),
//         .start(start),
//         .mode(mode),
//         .data_in(data_in),
//         .data_out(data_out),
//         .done(done)
//     );

// endmodule

`default_nettype none

module tt_um_ntt_top (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    wire [11:0] data_in;
    wire [11:0] data_out_0;
    wire [11:0] data_out_1; // Tín hiệu này sẽ bị bỏ trống (dangling)
    wire start;
    wire mode;
    wire done;

    // 1. MAPPING INPUTS
    assign data_in[7:0]  = ui_in[7:0];        
    assign data_in[11:8] = uio_in[3:0];       
    assign start         = uio_in[4];         
    assign mode          = uio_in[5];         

    // 2. MAPPING OUTPUTS (Chỉ xuất kênh 0)
    assign uo_out[7:0]   = data_out_0[7:0];     
    assign uio_out[3:0]  = data_out_0[11:8];    
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

    wire _unused = &{ena, uio_in[7:6], data_out_1, 1'b0};

    // 4. INSTANTIATE DUAL TOP (Kênh 1 nối 0)
    ntt_top_dual u_ntt_top_dual (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .data_in_0(data_in),
        .data_in_1(12'd0), 
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .done(done)
    );

endmodule
