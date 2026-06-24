VCS_OPTS = -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+all -kdb -lca
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/10ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_SRC_FILES = ./rtl/adder.sv ./tb/tb_adder.sv
VCS_OUTPUT = -o simv

SIMV_OPTS = +UVM_TESTNAME=adder_test
SIMV_OPTS += +UVM_VERBOSITY=UVM_MEDIUM
SIMV_OPTS += +ntb_random_seed=1234


.PHONY: compile simv clean

compile:
	vcs $(VCS_OPTS) -o $(VCS_SRC_FILES)
	@echo "vcs 컴파일 중"
sim:
	./simv $(SIMV_OPTS)
	@echo "vcs 시뮬레이션 중"

clean:
	rm -rf simv* csrc *.log *.key *.h
	@echo "clean 중"
