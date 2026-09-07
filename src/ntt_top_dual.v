// KHỐI TOP-LEVEL

module ntt_top_dual (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire mode,
    input wire [11:0] data_in_0,
    input wire [11:0] data_in_1,
    output wire [11:0] data_out_0,
    output wire [11:0] data_out_1,
    output wire done //cờ báo hoàn thành 7 tầng biến đổi
);
    wire [2:0] current_stage;
    wire [1:0] ctrl_d;
    wire [6:0] twiddle_addr;
    wire [11:0] twiddle_data0;
    wire [11:0] twiddle_data1;

    wire [11:0] out_y00, out_y01; //dữ liệu ngõ ra từ khối dual-butterfly
    wire [11:0] out_y10, out_y11;
    wire [11:0] reorder_out0; //dữ liệu trích xuất sau nmi rồi vòng lại vào single-butterfly
    wire [11:0] reorder_out1; 

    //Khối fsm và rom hệ số xoay
    ntt_fsm_rom_dual u_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .current_stage(current_stage),
        .ctrl_d(ctrl_d),
        .twiddle_addr(twiddle_addr),
        .twiddle_data0(twiddle_data0),
        .twiddle_data1(twiddle_data1),
        .done(done)
    );

    //Khối single-butterfly
    dual_butterfly u_butterfly (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .in_a0(reorder_out0), //sau khi qua nmi 7 tầng sẽ vòng lại in_a của single-butterfly để tính toán lại từ đầu
        .in_a1(reorder_out1), 
        .in_b0(data_in_0),
        .in_b1(data_in_1),
        .in_twiddle0(twiddle_data0),
        .in_twiddle1(twiddle_data1),
        .out_y00(out_y00),
        .out_y01(out_y01),
        .out_y10(out_y10),
        .out_y11(out_y11)
    );

    //Khối NMI
    nmi_reorder_dual u_reorder (
        .clk(clk),
        .rst_n(rst_n),
        .en(!done), // en kích hoạt khi hệ thống đang chạy để tiết kiệm năng lượng
        .ctrl_d(ctrl_d),
        //kênh 0
        .data_in_0(out_y00),
        .fb_in_0(out_y01),
        .data_out_0(reorder_out0),

        //kênh 1
        .data_in_1(out_y10),
        .fb_in_1(out_y11),
        .data_out_1(reorder_out1)
    );

    assign data_out_0 = out_y01;
    assign data_out_1 = out_y11;

endmodule
