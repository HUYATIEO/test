//KHỐI FSM ĐIỀU KHIỂN VÀ GIẢI MÃ ĐỊA CHỈ HỆ SỐ XOAY
//Quản lý trạng thái xử lý 7 tầng biến đổi của NTT/INTT (Stage 1 -> Stage 7).
// - Đếm 64 bước xử lý cho mỗi tầng (Tổng: 7 tầng * 64 bước = 448 chu kỳ clock).
// - Điều khiển cấu hình trễ cho khối NMI Reorder qua tín hiệu ctrl_d:
// + Stage 1: ctrl_d = 2'b00 (Trễ 4D)
// + Stage 2: ctrl_d = 2'b01 (Trễ 2D)
// + Stage 3 -> 7: ctrl_d = 2'b10 (Trễ 1D)

module ntt_fsm_rom_dual (
    input wire clk,
    input wire rst_n, 
    input wire start, //xung kích hoạt bắt đầu tính toán NTT/INTT 
    output reg [2:0] current_stage, //tầng biến đổi hiện tại (1 -> 7)
    output reg [1:0] ctrl_d, //cấu hình trễ đầu ra (1d, 2d, 4d)
    output wire [6:0] twiddle_addr, //địa chỉ truy cập rom (0-127)
    output wire [11:0] twiddle_data0, //giá trị hệ số xoay 0 từ rom
    output wire [11:0] twiddle_data1, //giá trị hệ số xoay 1 từ rom
    output reg done //báo hoàn thành 7 tầng tính toán
);
    localparam [1:0] S_IDLE = 2'b00;
    localparam [1:0] S_RUN = 2'b01;
    localparam [1:0] S_DONE = 2'b10;

    reg [1:0] state; 
    reg [5:0] step_cnt; //bộ đếm 64 bước xử lí trong 1 tầng

    //thêm sau bộ tạo hệ số xoay
    reg [11:0] twiddle_rom [0:127];
    initial begin
        $readmemh("twiddle_factors.hex", twiddle_rom);
    end
    
    reg [6:0] base_addr; //base_adder = 2^(current_stage - 1)
    reg [6:0] group_index; //group_index = step_cnt >> (8 - current_stage)

    always @(*) begin 
        case (current_stage)
            3'd1: begin base_addr = 7'd1; group_index = 7'd0; end
            3'd2: begin base_addr = 7'd2; group_index = {6'b0, step_cnt[5]}; end
            3'd3: begin base_addr = 7'd4; group_index = {5'b0, step_cnt[5:4]}; end
            3'd4: begin base_addr = 7'd8; group_index = {4'b0, step_cnt[5:3]}; end
            3'd5: begin base_addr = 7'd16; group_index = {3'b0, step_cnt[5:2]}; end
            3'd6: begin base_addr = 7'd32; group_index = {2'b0, step_cnt[5:1]}; end
            3'd7: begin base_addr = 7'd64; group_index = {1'b0, step_cnt[5:0]}; end
            default: begin base_addr = 7'd0; group_index = 7'd0; end
        endcase
    end

    assign twiddle_addr = (state == S_RUN) ? (base_addr + group_index) : 7'd0; //địa chỉ bằng base_addr + group_index
    assign twiddle_data0 = twiddle_rom[twiddle_addr]; //tra cứu từ rom qua địa chỉ 
    assign twiddle_data1 = twiddle_rom[twiddle_addr]; //tra cứu từ rom qua địa chỉ 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            step_cnt <= 6'd0;
            current_stage <= 3'd1;
            done <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    step_cnt <= 6'd0;
                    current_stage <= 3'd1;
                    if (start) state <= S_RUN;
                end

                S_RUN: begin
                    if (step_cnt == 6'd63) begin //từ 128 -> 64 bước
                        step_cnt <= 6'd0;
                        if (current_stage == 3'd7) begin
                            state <= S_DONE;
                            done <= 1'b1;
                        end else begin
                            current_stage <= current_stage + 1'b1;
                        end
                    end else begin
                        step_cnt <= step_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    //cấu hình trễ từ trạng thái tầng hiện tại
    always @(*) begin
        case (current_stage) 
            3'd1: ctrl_d = 2'b00; //4D
            3'd2: ctrl_d = 2'b01; //2D
            default: ctrl_d = 2'b10;  //từ tâng 3-7 là 1D  
        endcase
    end
endmodule
