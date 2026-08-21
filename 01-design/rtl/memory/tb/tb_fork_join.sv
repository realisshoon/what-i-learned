`timescale 1ns / 1ps

module tb_fork_join();

    initial begin
        $display("========================================");
        $display(" 1. 기본 fork ... join 테스트 (모두 끝날 때까지 대기)");
        $display("========================================");
        $display("%0t : start fork - join", $time);
        fork
            #10 A_thread("join");
            #20 B_thread("join");
            #15 C_thread("join");
        join
        $display("%0t : end fork - join (모든 쓰레드 종료됨)\n", $time);

        #50; // 시간 간격 띄우기

        $display("========================================");
        $display(" 2. 기본 fork ... join_any 테스트 (하나라도 끝나면 넘어감)");
        $display("========================================");
        $display("%0t : start fork - join_any", $time);
        fork
            #10 A_thread("join_any");
            #20 B_thread("join_any");
            #15 C_thread("join_any");
        join_any
        $display("%0t : end fork - join_any (가장 빠른 A_thread 종료 직후 넘어옴)\n", $time);

        #50; // 시간 간격 띄우기

        $display("========================================");
        $display(" 3. 기본 fork ... join_none 테스트 (기다리지 않고 바로 넘어감)");
        $display("========================================");
        $display("%0t : start fork - join_none", $time);
        fork
            #10 A_thread("join_none");
            #20 B_thread("join_none");
            #15 C_thread("join_none");
        join_none
        $display("%0t : end fork - join_none (쓰레드 시작만 시키고 즉시 넘어옴)\n", $time);

        // join_none에서 실행시킨 쓰레드들이 끝날 때까지 충분히 기다려줌
        #30; 


        $display("========================================");
        $display(" 4. 중첩된(Nested) fork 테스트 (왼쪽 사진)");
        $display("========================================");
        #1 $display("%0t : start fork - join", $time);
        fork
            // task A
            #10 A_thread("nested");
            
            // 내부에 또 다른 fork-join 생성
            fork
                // task B
                #20 B_thread("nested 1");
                #50 B_thread("nested 2");
            join

            // task C
            #30 C_thread("nested");
        join_any

        #10 $display("%0t : end fork - join\n", $time);


        #50; // 시간 간격 띄우기


        $display("========================================");
        $display(" 5. disable fork 테스트 (오른쪽 사진)");
        $display("========================================");
        #1 $display("%0t : start fork - join_any (disable 테스트)", $time);
        fork
            // task A
            A_loop_thread();
            // task B (무한루프)
            B_loop_thread();
            // task C (무한루프)
            C_loop_thread();
        join_any

        #10 $display("%0t : end fork - join_any", $time);

        // fork로 파생된 쓰레드 중 끝나지 않은 것들(무한루프 등)을 강제 종료!
        disable fork; 
        $display("%0t : disable fork 실행 (남은 쓰레드 모두 강제 종료됨)", $time);


        $display("========================================");
        $display(" 모든 시뮬레이션 완료");
        $display("========================================");
        $stop; // 시뮬레이션 일시 정지 (사진의 $stop 반영)
    end

    // --- 기본 Task 정의 ---
    task A_thread(string mode);
        $display("%0t : A thread (from %s)", $time, mode);
    endtask 

    task B_thread(string mode);
        $display("%0t : B thread (from %s)", $time, mode);
    endtask 

    task C_thread(string mode);
        $display("%0t : C thread (from %s)", $time, mode);
    endtask 

    // --- 오른쪽 사진 전용 Task 정의 (무한루프 등) ---
    task A_loop_thread();
        // 5번 반복 후 스스로 종료됨 (join_any를 해제하는 역할)
        repeat (5) $display("%0t : A loop thread", $time);
    endtask 

    task B_loop_thread();
        forever begin
            $display("%0t : B loop thread", $time);
            #5;
        end
    endtask 

    task C_loop_thread();
        forever begin
            $display("%0t : C loop thread", $time);
            #10;
        end
    endtask 

endmodule
