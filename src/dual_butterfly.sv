//KHỐI TÍNH TOÁN NTT VÀ INTT
//dual sẽ tính toán song song 2 bộ single
//Công thức NTT: (mode 0) với ngõ vào a, b và hệ số xoay zeta
// - y_0 = a + (b x zeta) (mod q)
// - y_1 = a - (b x zeta) (mod q)
// -> Nhân trước cộng trừ sau (u_post)

//Công thức INTT: (mode 1) với ngõ vào a, b và hệ số xoay nghịch w = zeta^-1;
// - y_0 = (a + b) / 2 (mod q)
// - y_1 = ((a - b) / 2) x w (mod q) = (a - b) x zeta (mod q)
// -> cộng trừ trước (u_pre) -> nhân sau

module dual_butterfly (
    input wire clk,
    input wire rst_n,
    input wire mode,   // 0: NTT (CT), 1: INTT (GS)
    input wire [11:0] in_a0,
    input wire [11:0] in_a1,
    input wire [11:0] in_b0,
    input wire [11:0] in_b1,
    input wire [11:0] in_twiddle0, //Hệ số xoay tùy biến 0 (có thể là w hoặc zeta)
    input wire [11:0] in_twiddle1, //Hệ số xoay tùy biến 1 (có thể là w hoặc zeta)
    output wire [11:0] out_y00,
    output wire [11:0] out_y01,
    output wire [11:0] out_y10,
    output wire [11:0] out_y11
);
    //Khối xử lí trước để lấy pre_sub_res và pre_div2_res cho tác vụ sau
    wire [11:0] pre_add_res0, pre_sub_res0, pre_div2_res0;  
    wire [11:0] pre_add_res1, pre_sub_res1, pre_div2_res1;  
    mod_add_sub_div2 u_pre0 (
        .in_a (in_a0),
        .in_b (in_b0),
        .out_add (pre_add_res0),
        .out_sub (pre_sub_res0),
        .out_div2(pre_div2_res0)
    );

    mod_add_sub_div2 u_pre1 (
        .in_a (in_a1),
        .in_b (in_b1),
        .out_add (pre_add_res1),
        .out_sub (pre_sub_res1),
        .out_div2(pre_div2_res1)
    );

    wire [11:0] mul_op_b0 = mode ? pre_sub_res0 : in_b0; //nếu mode = 1 (INTT) lấy giá trị a - b, nếu mode = 0 lấy giá trị b
    wire [11:0] mul_op_b1 = mode ? pre_sub_res1 : in_b1; 
    wire [11:0] mul_out0;
    wire [11:0] mul_out1;
    mod_multiplier u_mul0 (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(in_twiddle0),
        .in_b(mul_op_b0),
        .out_res(mul_out0) //kết quả: nếu mode = 1 (INTT) -> (a - b) * (w * 2^-1 = zeta) còn nếu mode = 0 -> b * zeta
    );

    mod_multiplier u_mul1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(in_twiddle1),
        .in_b(mul_op_b1),
        .out_res(mul_out1) 
    );

    //2 tầng flipflop mục đích đồng bộ trễ với khối mod_multiplier
    reg [11:0] in_a0_ff1, in_a0_ff2; //2 tầng flipflop cho tín hiệu in_a (in_b và sub không cần 2ff vì đã được đưa thẳng vào mod_multiplier ở trên)
    reg [11:0] div2_0_ff1, div2_0_ff2; //2 tầng flipflop cho đầu ra div2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_a0_ff1 <= 12'd0;
            in_a0_ff2 <= 12'd0;
            div2_0_ff1 <= 12'd0;
            div2_0_ff2 <= 12'd0;
        end else begin
            in_a0_ff1 <= in_a0;
            in_a0_ff2 <= in_a0_ff1;
            div2_0_ff1 <= pre_div2_res0;
            div2_0_ff2 <= div2_0_ff1;
        end
    end

    reg [11:0] in_a1_ff1, in_a1_ff2; 
    reg [11:0] div2_1_ff1, div2_1_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_a1_ff1 <= 12'd0;
            in_a1_ff2 <= 12'd0;
            div2_1_ff1 <= 12'd0;
            div2_1_ff2 <= 12'd0;
        end else begin
            in_a1_ff1 <= in_a1;
            in_a1_ff2 <= in_a1_ff1;
            div2_1_ff1 <= pre_div2_res1;
            div2_1_ff2 <= div2_1_ff1;
        end
    end

    //Khối xử lí sau để lấy post_sub_res và post_add_res
    wire [11:0] post_add_res0, post_sub_res0, post_div2_res0; 
    mod_add_sub_div2 u_post0 (
        .in_a(in_a0_ff2),
        .in_b(mul_out0),
        .out_add(post_add_res0),
        .out_sub(post_sub_res0),
        .out_div2(post_div2_res0)
    );

    wire [11:0] post_add_res1, post_sub_res1, post_div2_res1; 
    mod_add_sub_div2 u_post1 (
        .in_a(in_a1_ff2),
        .in_b(mul_out1),
        .out_add(post_add_res1),
        .out_sub(post_sub_res1),
        .out_div2(post_div2_res1)
    );

    assign out_y00 = mode ? div2_0_ff2 : post_add_res0; //lấy thẳng div2_ff2 mà không lấy post_div2_res vì mod_multiplier đã cấu hình cho đầu ra khối div2 là (a + b) / 2
    assign out_y01 = mode ? mul_out0 : post_sub_res0;

    assign out_y10 = mode ? div2_1_ff2 : post_add_res1;
    assign out_y11 = mode ? mul_out1 : post_sub_res1;
endmodule

    
