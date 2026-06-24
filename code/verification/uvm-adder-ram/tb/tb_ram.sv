`include "uvm_macros.svh" // UVM 매크로 포함
import uvm_pkg::*;        // UVM 패키지 임포트

// 1. DUT와 Testbench를 연결하는 Interface
interface ram_intf(input logic clk);
    logic we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata; // 출력
    logic valid;
endinterface // ram_intf


// 2. Sequence, Driver, Monitor, Scoreboard 사이에서 주고받는 transaction
class ram_seq_item extends uvm_sequence_item;
    rand logic we;          // Write Enable (1: 쓰기, 0: 읽기)
    rand logic [7:0] addr;  // RAM 주소
    rand logic [7:0] wdata; // 쓰기 데이터
    logic [7:0] rdata;      // 읽기 데이터 (출력값, randomize 대상 아님)

    // 생성자
    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction

    // Factory 및 필드 등록
    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we,    UVM_DEFAULT)
        `uvm_field_int(addr,  UVM_DEFAULT)
        `uvm_field_int(wdata, UVM_DEFAULT)
        `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_object_utils_end
endclass // ram_seq_item


// 3. random transaction을 생성하는 sequence
class ram_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_seq) // Factory 등록

    ram_seq_item r_seq_item;

    function new(string name = "ram_seq");
        super.new(name);
    endfunction

    // sequence의 실제 동작 부분
    virtual task body();
        repeat(50) begin
            logic [7:0] rand_addr;
            logic [7:0] rand_data;

            rand_addr = $urandom_range(0,255);
            rand_data = $urandom_range(0,255);
        
            // 1) Write transaction
            r_seq_item = ram_seq_item::type_id::create("WRITE_ITEM");

            start_item(r_seq_item);
            r_seq_item.we = 1'b1;
            r_seq_item.addr =rand_addr;
            r_seq_item.wdata =rand_data;
            finish_item(r_seq_item);
            
            // 2) READ transaction
            r_seq_item = ram_seq_item::type_id::create("READ_ITEM");

            start_item(r_seq_item);
            r_seq_item.we = 1'b0;
            r_seq_item.addr =rand_addr;
            r_seq_item.wdata =0;
            finish_item(r_seq_item);
        end
    endtask
endclass // ram_seq


// 4. Sequencer에서 transaction을 받아 DUT interface에 클럭 타이밍에 맞춰 신호를 인가하는 Driver
class ram_drv extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_drv) // component factory 등록

    virtual ram_intf ram_if;       // virtual interface 핸들
    ram_seq_item r_seq_item;

    function new(string name = "ram_drv", uvm_component c);
        super.new(name, c);
    endfunction

    // build_phase : 가상 인터페이스 획득
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        r_seq_item = ram_seq_item::type_id::create("SEQ_ITEM", this);
        if (!uvm_config_db#(virtual ram_intf)::get(this, "", "ram_if", ram_if)) begin
            `uvm_fatal(get_name(), "Unable to access ram interface.")
        end
    endfunction

    // run_phase : 클럭 posedge에 맞춰 DUT에 신호 인가 (1클럭에 1트랜잭션씩)
    virtual task run_phase(uvm_phase phase);
        // 초기화
        ram_if.we    <= 0;
        ram_if.addr  <= 0;
        ram_if.wdata <= 0;
        ram_if.valid <= 0;

        forever begin
            // sequencer로부터 transaction 획득
            seq_item_port.get_next_item(r_seq_item);

            // clk의 상승 엣지(posedge)에서 신호 인가
            @(negedge ram_if.clk);
            ram_if.we    <= r_seq_item.we;
            ram_if.addr  <= r_seq_item.addr;
            ram_if.wdata <= r_seq_item.wdata;
            ram_if.valid <= 1'b1;
            @(posedge ram_if.clk);

            ram_if.we    <= 0;
            ram_if.valid <=1'b0;
            // 핸드셰이크 완료 통보 (다음 클럭 엣지에서 바로 다음 트랜잭션이 들어올 수 있도록)
            seq_item_port.item_done();
        end
    endtask
endclass // ram_drv


// 5. DUT interface 신호를 관찰(샘플링)하여 transaction으로 복원하는 Monitor
// 동기식 RAM의 Read Latency(1 clock delay)를 반영하여 신호를 캡처함
class ram_mon extends uvm_monitor;
    `uvm_component_utils(ram_mon) // component factory 등록

    uvm_analysis_port#(ram_seq_item) send; // 수집 데이터를 보낼 포트
    virtual ram_intf ram_if;
    ram_seq_item r_seq_item;

    function new(string name = "ram_mon", uvm_component c);
        super.new(name, c);
        send = new("send", this);
    endfunction

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        r_seq_item = ram_seq_item::type_id::create("SEQ_ITEM", this);
        if (!uvm_config_db#(virtual ram_intf)::get(this, "", "ram_if", ram_if)) begin
            `uvm_fatal(get_name(), "Unable to access ram interface.")
        end
    endfunction

    // run_phase : 버스 신호를 모니터링하여 데이터 수집
    virtual task run_phase(uvm_phase phase);
        logic active_read = 0;
        logic [7:0] read_addr;
        ram_seq_item clone_item;

        forever begin
            // 클럭 상승 엣지에서 신호 캡처
            @(posedge ram_if.clk);
            r_seq_item.we =ram_if.we;

            // 이전 클럭에 읽기(Read) 요청이 있었던 경우, 이번 클럭에서 비로소 유효해지는 rdata를 결합하여 내보냄
            if (active_read) begin
                clone_item = ram_seq_item::type_id::create("clone_item");
                clone_item.we    = 0;
                clone_item.addr  = read_addr;
                clone_item.wdata = 0;
                clone_item.rdata = ram_if.rdata;
                
                `uvm_info("MON", $sformatf("Captured READ: addr=0x%0h, rdata=0x%0h", clone_item.addr, clone_item.rdata), UVM_LOW)
                send.write(clone_item);
                active_read = 0;
            end
            
            // 현재 클럭에 입력된 신호를 확인
            if(ram_if.valid) begin
                if (ram_if.we) begin
                    // Write 동작은 즉시 Scoreboard로 전송 (출력값 검증이 필요 없으므로)
                    clone_item = ram_seq_item::type_id::create("clone_item");
                    clone_item.we    = 1;
                    clone_item.addr  = ram_if.addr;
                    clone_item.wdata = ram_if.wdata;
                    clone_item.rdata = 0;
                    
                    `uvm_info("MON", $sformatf("Captured WRITE: addr=0x%0h, wdata=0x%0h", clone_item.addr, clone_item.wdata), UVM_LOW)
                    send.write(clone_item);
                end else begin
                    // Read 동작인 경우, rdata가 출력되는 다음 클럭 상승 엣지에서 결합하기 위해 상태 기억
                    active_read = 1;
                    read_addr   = ram_if.addr;
                end
            end
        end
    endtask
endclass // ram_mon


// 6. 모니터링 데이터와 내부 레퍼런스 모델(Golden Model)을 비교하는 Scoreboard
class ram_scb extends uvm_scoreboard;
    `uvm_component_utils(ram_scb)
    
    uvm_analysis_imp#(ram_seq_item, ram_scb) recv;

    // 레퍼런스 모델 역할을 할 연상 배열(Associative Array) 메모리 모델 선언
    logic [7:0] ref_mem[logic [7:0]]; 

    function new(string name = "ram_scb", uvm_component c);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    // write : 모니터에서 들어온 transaction 처리 및 검증
    virtual function void write(ram_seq_item data);
        `uvm_info("SCB", "Data received from Monitor", UVM_HIGH)

        if (data.we) begin
            // Write 동작인 경우: 레퍼런스 모델 메모리에 데이터 저장
            ref_mem[data.addr] = data.wdata;
            `uvm_info("SCB", $sformatf("Write Ref Model: addr=0x%0h -> data=0x%0h", data.addr, data.wdata), UVM_LOW)
        end
        else begin
            // Read 동작인 경우: 레퍼런스 모델의 데이터와 실제 DUT의 rdata 비교
            logic [7:0] expected_data;
            
            // 한 번도 쓰지 않은 주소를 읽는 경우 기본값은 0으로 가정 (RTL 구현 상태에 따라 달라짐)
            if (ref_mem.exists(data.addr)) begin
                expected_data = ref_mem[data.addr];
            end else begin
                expected_data = 8'h00; 
            end

            if (data.rdata == expected_data) begin
                `uvm_info("SCB", $sformatf("PASS! Read mismatch CHECK: addr=0x%0h, expected=0x%0h, actual=0x%0h", data.addr, expected_data, data.rdata), UVM_LOW)
            end
            else begin
                `uvm_error("SCB", $sformatf("FAIL! Read mismatch CHECK: addr=0x%0h, expected=0x%0h, actual=0x%0h", data.addr, expected_data, data.rdata))
            end
        end
    endfunction
endclass // ram_scb


// 7. Sequencer, Driver, Monitor를 묶어 관리하는 Agent
class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    ram_mon a_mon;
    ram_drv a_drv;
    uvm_sequencer#(ram_seq_item) a_sqr;

    function new(string name = "ram_agent", uvm_component c);
        super.new(name, c);
    endfunction

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_mon = ram_mon::type_id::create("MON", this);
        a_drv = ram_drv::type_id::create("DRV", this);
        a_sqr = uvm_sequencer#(ram_seq_item)::type_id::create("SQR", this);
    endfunction

    // connect_phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a_drv.seq_item_port.connect(a_sqr.seq_item_export);
    endfunction
endclass // ram_agent


// 8. Agent와 Scoreboard를 포함하는 Env
class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent a_agt;
    ram_scb   a_scb;

    function new(string name = "ram_env", uvm_component c);
        super.new(name, c);
    endfunction

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_agt = ram_agent::type_id::create("AGT", this);
        a_scb = ram_scb::type_id::create("SCB", this);
    endfunction

    // connect_phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a_agt.a_mon.send.connect(a_scb.recv); // Monitor 출력과 Scoreboard 연결
    endfunction
endclass // ram_env


// 9. 시나리오 제어 최상위 Test 클래스
class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_seq a_seq;
    ram_env a_env;

    function new(string name = "ram_test", uvm_component c);
        super.new(name, c);
    endfunction

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_seq = ram_seq::type_id::create("SEQ", this);
        a_env = ram_env::type_id::create("ENV", this);
    endfunction

    // run_phase
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        a_seq.start(a_env.a_agt.a_sqr); // 시퀀스 동작 시작
        
        phase.drop_objection(this);
    endtask
endclass // ram_test


// 10. HW (DUT) 및 UVM 테스트벤치를 가동하는 최상위 Top 모듈
module tb_ram ();

    // 클럭 생성
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz 클럭 주기 (10ns)
    end

    // 1. 물리 인터페이스 인스턴스 선언 (클럭 전달)
    ram_intf ram_if(clk);

    // 2. 테스트할 대상(DUT) 인스턴스화
    ram dut (
        .clk(ram_if.clk),
        .we(ram_if.we),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    // 3. 디버깅용 파형 파일 덤프
    initial begin
        $fsdbDumpvars(0);
        $fsdbDumpfile("wave.fsdb");
    end

    // 4. UVM 가동 및 인터페이스 공유
    initial begin
        // 가상 인터페이스 등록
        uvm_config_db#(virtual ram_intf)::set(null, "*", "ram_if", ram_if);
        
        // 테스트 실행
        run_test("ram_test");
    end

endmodule
