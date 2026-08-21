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
	./rtl/spi_master.sv \
	./rtl/spi_slave.sv \
	./rtl/spi_master_slave_top.sv \
	./tb/spi_if.sv \
	./tb/spi_pkg.sv \
	./tb/tb_spi.sv

VCS_OUTPUT = -o simv

TEST ?= spi_test
SEED ?= 1
INFO_LEVEL ?= UVM_MEDIUM

SIMV_OPTS = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)

# coverage 옵션은 처음엔 꺼두는 걸 추천
# SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
# SIMV_OPTS += -cm_dir coverage.vdb
# SIMV_OPTS += -cm_name sim1

.PHONY: all compile sim clean

all: sim

compile:
	mkdir -p $(WAVE_DIR) $(LOG_DIR) $(COV_DIR)
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) $(VCS_OUTPUT) -l $(LOG_DIR)/compile.log
	@echo "vcs 컴파일 완료"

sim: compile
	./simv $(SIMV_OPTS) -l $(LOG_DIR)/sim.log
	@echo "vcs 시뮬레이션 완료"

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