`include "uvm_macros.svh" // UVM 매크로 사용 
import uvm_pkg::*;        // UVM 클래스 사용


// DUT 와 Testbench를 연결하는 Interfcae 
interface adder_intf;
    logic [7:0] a; // adder 입력 a
    logic [7:0] b; // adder 입력 b
    logic [8:0] y; // adder 출력 y, 8bit + 8bit 라서 carry 포함 9bit
endinterface //adder_intf

// Sequence, Driver, Monitor, Scoreboard 사이에서 주고 받는 transaction
class adder_seq_item extends uvm_sequence_item;
    rand logic [7:0] a; // randomize 대상 입력 a
    rand logic [7:0] b; // randomize 대상 입력 a
    
    
    logic [8:0] y;      // DUT 출력 값 저장용, randomize 대상 아님
    
    // 생성자
    function new(string name = "adder_seq_item");
        super.new(name); // uvm_sequence_item 부모 생성자 호출
    endfunction //new()

    // Factory 등록 + field 등록 
    // Factory 등록 : 
    // field 등록 : UVM 에서 객체의 필드를 인식하고 print(), copy(), pack/unpack 등의 동작을 자동으로 지원해줌
    `uvm_object_utils_begin(adder_seq_item)
        `uvm_field_int(a,UVM_DEFAULT)   // a 필드 등록
        `uvm_field_int(b,UVM_DEFAULT)   // b 필드 등록
        `uvm_field_int(y,UVM_DEFAULT)   // y 필드 등록
    `uvm_object_utils_end
endclass //adder_seq_item extends uvm_sequence_item


// random transaction을 생성하는 sequence 
class adder_seq extends uvm_sequence;
    `uvm_object_utils(adder_seq)    // sequence를 factory에 등록

    adder_seq_item a_seq_item; // driver에게 보낼 transaction handle

    // sequence 생성자 
    function new(string name = "adder_seq");
        super.new(name);    // 부모 생성자 호출
    endfunction //new()

    // sequence의 실제 동작 부분 
    virtual task body();

        // factory를 통해 sequence item 생성
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");       

        // transaction 100개 생성
        repeat(100) begin
            start_item(a_seq_item);             // seqencer-driver 통신 시작
            
            // a, b  랜덤값 생성 실패 시 error (assertion 사용?)
            if (!a_seq_item.randomize())begin
                `uvm_error("SEQ_ITEM","Fail to generate random value!")
            end

            // uvm_info(1,2,3)
            // 1 인자 : uvm의 어떤 부분에서 출력되었는지 구분 (SEQ:sequence)
            // 2 인자 : 실제로 콘솔에 출력하고 싶은 메시지 내용
            // 3 인자 : 메시지의 출력 우선순위를 결정함 
                // UVM_NONE > UVM_LOW > UVM_MEDIUM > UVM_HIGH > UVM_FULL > UVM_DEBUG
                // 가장 낮은 등급 NONE은 무조건 출력하게 되며 높은 등급일 수록 우선순위가 밀리게 됨 
                // 이렇게 등급을 해놓은 이유는 디버깅시에 원하는 등급에 코드만 나올 수 있도록
                // +UVM_VERBOSITY=UVM_HIGH 이와 같은 코드로 지정 가능하며 
                // 모든 구간에 출력을 하게되면 메모리 용량을 많이 사용할 수 있기에 등급으로 나눠놓음 
            `uvm_info("SEQ", "Data send to Driver",UVM_NONE);
            finish_item(a_seq_item); // transaction 생성 완료, driver로 전달 가능 
        end
    endtask
endclass //adder_seq extends uvm_sequence

// sequencer에서 transaction을 받아 DUT interface에 실제 신호로 넣는 Driver
class adder_drv extends uvm_driver #(adder_seq_item);

    `uvm_component_utils(adder_drv)     // component factory 등록 

    virtual adder_intf adder_if;        // 실제 interface를 가리키는 virtual interface
    adder_seq_item a_seq_item;          // sequencer에서 받을 transaction

    // dirver 생성자 
    function new(string name = "adder_drv", uvm_component c);
        super.new(name,c);      // 부모 uvm_driver 생성자 호출
    endfunction //new()

    // build_phase : 컴포넌트 생성 및 설정 값을 받아오는 단계 (TOP-DOWN으로 실행됨)
    virtual function void build_phase(uvm_phase phase);
        // 부모 클래스(uvm_driver)의 build_phase를 호출하여 기본설정 수행
        super.build_phase(phase);       

        // factory를 통해 sequence item(데이터 패킷) 객체를 동적으로 생성
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM",this);

        // uvm_cofig_db를 통해 top에서 공유한 가상 인터페이스를 가져옴
        // get() 함수가 0을 반환하면 인터페이스 연결 오류로 간주
        if(!uvm_config_db#(virtual adder_intf)::get(this,"","adder_if",adder_if))begin
            // 인터페이스를 못 가져오면 테스트 진행이 안 되므로 Fatal 에러를 발생시키고 즉시 시뮬레이션 종료
            `uvm_fatal(get_name(), "Unable to access adder interface.")
        end
    endfunction


    // run_phase : 시뮬레이션 시간 동안 동작하며 실제 DUT에 신호를 흘려보내는 단계
    // task이므로 시간 지연 사용 가능함
    virtual task run_phase(uvm_phase phase);
        $display("Display run phase");
        // 시뮬레이션 끝날 때까지 무한 반복 수행
        forever begin
            // 1. sequencer로부터 새로운 trasaction이 올 때까지 대기하고 받아옴 (Blocking)
            seq_item_port.get_next_item(a_seq_item); 

            // 2. 받아온 transaction의 값을 실제 가상 인터페이스(DUT 입력)에 대입(Non-Blocking)
            adder_if.a <= a_seq_item.a;
            adder_if.b <= a_seq_item.b;
            #10; // 신호가 인가된 상태로 10ns 만큼 유지

            // 3. 해당 transaction 처리가 완료되었음을 Sequencer에게 알림(Handshake 완료)
            seq_item_port.item_done();
        end
    endtask
endclass //adder_drv extends uvm_driver


// DUT interface 신호를 관찰해서 transaction으로 복원하는 Monitor
class adder_mon extends uvm_monitor;
    `uvm_component_utils(adder_mon)     // component factory 등록

    // scoreboard 등으로 데이터를 전송하기 위한 Analysis port 선언
    // Analysis port 란 : 모니터가 수집한 데이터를 외부로 내보내는 통로임
    // scoreboard, coverage, Logger 등을 broadcast 함
    uvm_analysis_port#(adder_seq_item) send;
    virtual adder_intf adder_if;        // 버스를 모니터링할 virtual interface
    adder_seq_item a_seq_item;          // 수집한 신호를 담을 transaction 객체

    // monitor 생성자
    function new(string name = "adder_mon",uvm_component c);
        super.new(name,c);      
        send = new ("send",this);   // 외부 컴포넌트와 통신할 분석 포트객체 생성 
    endfunction

    // build_phase : 컴포넌트 생성 및 인터페이스 연결
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 모니터링 데이터를 채워넣을 transaction 객체 생성
        a_seq_item =adder_seq_item::type_id::create("SEQ_ITEM",this);
        // 가상 인터페이스 획득 및 검사
        if(!uvm_config_db#(virtual adder_intf)::get(this,"","adder_if",adder_if))begin
            `uvm_fatal(get_name(),"Unable to access adder interface");
        end
    endfunction

    // run_phase : 시뮬레이션 중 지속적으로 버스 신호를 감시하고 샘플링하는 단계
    virtual task run_phase(uvm_phase phase);
        forever begin
            #10; // 10ns 간격으로 인터페이스의 신호를 샘플링

            // 1. 인터페이스의 실제 핀 값(a, b, y)을 읽어와 transaction 객체에 저장
            a_seq_item.a = adder_if.a;
            a_seq_item.b = adder_if.b;
            a_seq_item.y = adder_if.y;

            `uvm_info("MON","Send data to Scoreboard",UVM_LOW)

            // scoreboard로 transaction 전달
            send.write(a_seq_item);
        end
    endtask //

endclass

// 예상값과 실제 DUT 결과를 비교하는 Scroeboard 
class adder_scb extends uvm_scoreboard;

    `uvm_component_utils(adder_scb) // component factory 등록 

    // monitor로부터 전송된 데이터를 받기 위한 Analysis Implementation 선언
    // <수신할 데이터 타입, 이 포트가 위치한 클래스 타입>을 인자로 지정
    uvm_analysis_imp#(adder_seq_item,adder_scb) recv;

    // Scoreboard 생성자
    function new(string name = "adder_scb",uvm_component c);
        super.new(name,c);

        // 분석 수신 포트(Analysis Imp) 객체 생성
        recv =new("READ",this);
    endfunction

    // write : analysis port를 통해 데이터가 수신되면 UVM엔진에 의해 자동으로 호출되는 콜백 함수
    // 인자로 monitor가 수집해서 보낸 transaction 객체를 전달받음
    virtual function void write(adder_seq_item data);
        `uvm_info("SCB","Data received from Monitor", UVM_LOW)

        // 데이터 정합성 검증
        // 입력값의 합이 실제 DUT가 출력한 값과 일치하는지 비교 판정
        if(data.a + data.b == data.y) begin
            // 성공 시 PASS 출력($sformatf를 사용하여 정수형 데이터를 문자열로 포멧팅)
            `uvm_info("SCB", $sformatf("PASS!, a: %0d + b:%0d = y:%0d",data.a, data.b,data.y),UVM_LOW)
        end
        else begin
            // 실패 시 경고 및 에러 카운트 증가
            `uvm_error("SCB",$sformatf("FAIL, a: %0d + b:%0d = y:%0d",data.a, data.b,data.y))
        end
        
    endfunction
endclass

// sequnecer, driver, monitor를 하나의 단위로 묶어 관리하는 Agent
class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent) // componet factory 등록

    // 하위 컴포넌트 핸들 선언 
    adder_mon a_mon;            // bus monitor
    adder_drv a_drv;            // bus dirver
    uvm_sequencer#(adder_seq_item) a_sqr;   // 시퀀서

    // agent 생성자
    function new(string name = "adder_agent", uvm_component c);
        super.new(name,c);
    endfunction //new()

    // build_phase : 하위 컴포넌트(mon,drv,seqr)을 각각 생성
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_mon = adder_mon::type_id::create("MON",this);
        a_drv = adder_drv::type_id::create("DRV",this);
        a_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR",this);
    endfunction

    // connect_phase : 생성된 하위 컴포넌트들 간의 연결을 수행하는 단계
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Driver의 수신 포트와 sequencer의 송신 포트를 서로 연결하여 통신 채널 형성
        a_drv.seq_item_port.connect(a_sqr.seq_item_export);
        
    endfunction

endclass //adder_agent extends uvm_agent

// 검증에 필요한 최상위 컴포넌트들을 담고 관리하는 검증 환경
class adder_env extends uvm_env;
    `uvm_component_utils(adder_env) // component factory 등록

    // 하위 검증 컴포넌트 핸들 선언 
    adder_agent a_agt;  // 드라이버, 시퀀서, 모니터를 포함한 agent
    adder_scb a_scb;    // 데이터를 비교 및 검증할 scoreboard

    // Env 생성자
    function new(string name = "adder_env",uvm_component c);
        super.new(name, c);
    endfunction //new()

    // build_phase : 하위컴포넌트인 Agent와 Scoreboard를 각각 생성
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_agt = adder_agent::type_id::create("AGT",this);
        a_scb = adder_scb::type_id::create("SCB",this);
    endfunction

    // connect_phase : agent 내부의 mon와 scb 간의 데이터 통신 채널 연결
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // agent 내부 mon의 송신 포트와 scb의 수신 포트를 연결
        // 이 연결을 통해 mon가 캡처한 데이터가 자동으로 scb로 전송됨
        a_agt.a_mon.send.connect(a_scb.recv);        
    endfunction

endclass //adder_env extends uvm_env


// 시나리오를 정의하고 전체 검증환경을 조율하는 최상위 test 클래스 
class adder_test extends uvm_test;
    `uvm_component_utils(adder_test)    // componet factory 등록
    
    adder_seq a_seq;    // 실행할 입력 시퀀스(시나리오)
    adder_env a_env;    // 검증 환경(environment)


    // test 생성자
    function new(string name = "adder_test", uvm_component c);
        super.new(name,c);
    endfunction

    // build_phase : 시퀀스와 환경을 생성
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_seq = adder_seq::type_id::create("SEQ",this);
        a_env = adder_env::type_id::create("ENV",this);
    endfunction

    // run_phase : 테스트 시나리오를 시작하는 메인 루틴
    virtual task run_phase(uvm_phase phase);
        // 시뮬레이션이 바로 종료되지 않도록 제동을 검
        phase.raise_objection(this);

        // 지정한 sequencer 위에서 sequence를 동작 시킴
        a_seq.start(a_env.a_agt.a_sqr);

        // 시퀀스 동작이 끝나면 제동을 해제하여 시뮬레이션이 종료되도록 허용
        phase.drop_objection(this);
    endtask //run_phase
endclass


// hw(dut)와 uvm을 연결하는 최상위 모듈
module tb_adder ();

    // 1. 신호 연결을 위한 물리 인터페이스 선언
    adder_intf adder_if();

    // 2. 테스트할 대상 인스턴스화 및 인터페이스 선언
adder dut(
    .a(adder_if.a),
    .b(adder_if.b),
    .y(adder_if.y)
);



    // 3. 디버깅용 파형 파일 덤프 설정
initial begin
    $fsdbDumpvars(0);
    $fsdbDumpfile("wave.fsdb");
end

    // 4. uvm 실행 및 하드웨어 인터페이스 공유
initial begin

    // 물리 인터페이스를 가상 인터페이스 형태로 데이터베이스에 등록
    // 이를 통해 uvm 내부 컴포넌트들이 꺼내 쓸 수 있음
    uvm_config_db#(virtual adder_intf)::set(null,"*","adder_if",adder_if);
    
    // 지정된 uvm test 클래스를 메모리에 생성하고 uvm 시뮬레이션을 구동함
    run_test("adder_test");
end

endmodule