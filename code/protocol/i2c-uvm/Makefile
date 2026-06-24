OUT_DIR  = out
WAVE_DIR = $(OUT_DIR)/wave
LOG_DIR  = $(OUT_DIR)/log
COV_DIR  = $(OUT_DIR)/cov

VCS_OPTS = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca

VCS_INCDIR = +incdir+tb +incdir+rtl

VCS_SRC_FILES = \
	./rtl/i2c_master.sv \
	./rtl/i2c_slave.sv \
	./rtl/i2c_master_slave_top.sv \
	./tb/i2c_if.sv \
	./tb/i2c_pkg.sv \
	./tb/tb_i2c.sv

VCS_OUTPUT = -o simv

TEST ?= i2c_test
SEED ?= 1
INFO_LEVEL ?= UVM_MEDIUM

SIMV_OPTS = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)

VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_dir $(COV_DIR)/i2c_uvm.vdb
SIMV_OPTS += -cm_name i2c_uvm_$(SEED)

.PHONY: all compile sim clean verdi

all: sim

compile:
	mkdir -p $(WAVE_DIR) $(LOG_DIR) $(COV_DIR)
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) $(VCS_OUTPUT) -l $(LOG_DIR)/compile.log
	@echo "vcs 컴파일 완료"

sim: compile
	./simv $(SIMV_OPTS) -l $(LOG_DIR)/sim.log
	@echo "vcs 시뮬레이션 완료"

verdi:
	verdi -sv -f filelist.f -ssf $(WAVE_DIR)/tb_i2c.fsdb &

clean:
	rm -rf \
		simv simv.daidir simv.vdb \
		csrc \
		out \
		coverage.vdb \
		*.fsdb \
		novas* \
		verdiLog \
		vdCovLog \
		DVEfiles \
		ucli.key \
		vc_hdrs.h \
		*.log \
		*.key \
		*.h
	@echo "clean 완료"