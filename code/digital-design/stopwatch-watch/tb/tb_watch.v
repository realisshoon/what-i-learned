`timescale 1ns / 1ps

module tb_watch();

    // 1. 전체 시스템에 들어가는 가상의 외부 입력 (스위치, 버튼 등)
    reg clk;
    reg rst;
    reg sw;
    reg btnL; // 상태 변경 (L)
    reg btnR; // 상태 변경 (R)
    reg btnU; // 시간 증가 (U)
    reg btnD; // 시간 감소 (D)

    // 2. 모듈과 모듈 사이를 연결해주는 내부 선 (Wire)
    wire [1:0] w_state; // Control Unit이 뱉고 Datapath가 먹는 선

    // 3. 밖으로 관찰할 출력(Output) 선들
    wire [6:0] out_msec;
    wire [5:0] out_sec;
    wire [5:0] out_min;
    wire [4:0] out_hour;

    // ========================================================
    // [부품 1] 제어부 (Control Unit) 조립
    // ========================================================
    watch_control_unit U_CU (
        .clk    (clk),
        .rst    (rst),
        .sw     (sw),
        .i_btnL (btnL),
        .i_btnR (btnR),
        .o_state(w_state) // 상태를 w_state라는 선으로 뽑아냅니다!
    );

    // ========================================================
    // [부품 2] 데이터패스 (Datapath) 조립
    // ========================================================
    watch_datapath U_DP (
        .clk         (clk),
        .rst         (rst),
        .i_state     (w_state), // CU에서 뻗어나온 w_state를 여기에 꽂습니다!
        .i_btnU_tick (btnU),    // 가상의 버튼 입력을 꽂음 (테스트용)
        .i_btnD_tick (btnD),
        .o_msec      (out_msec),
        .o_sec       (out_sec),
        .o_min       (out_min),
        .o_hour      (out_hour)
    );

    // 클럭 발생기 (주기 10ns)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sw = 0;

        {btnR,btnL,btnD,btnU} = 4'b0000;
        #20 rst = 0; 
        #200;
    end


    initial begin
        // 1. 정상 시간 흐름 관찰 대기
        #200;

        // 상태 전환 
        #10 btnL = 1; // set sec 
        #10 btnL = 0; 
        #10 btnL = 1;  // set min
        #10 btnL = 0;  
        #10 btnL = 1;  // set hour
        #10 btnL = 0; 
        
        #50;

        #10 btnU = 1; #10 btnU = 0; // +1초
        #50;
        #10 btnU = 1; #10 btnU = 0; // +2초
        
        #100;

        #10 btnL = 1; #10 btnL = 0; // NORMAL
        
        // -> w_state가 다시 00으로 바뀌고, 시간이 다시 흘러야 함

        #300;
        $finish;
    end

endmodule
