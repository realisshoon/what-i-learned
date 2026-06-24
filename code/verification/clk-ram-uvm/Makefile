OUT_DIR  = out
SIM_DIR  = $(OUT_DIR)/sim
WAVE_DIR = $(OUT_DIR)/wave
COV_DIR  = $(OUT_DIR)/cov
LOG_DIR  = $(OUT_DIR)/log

SIMV = $(SIM_DIR)/simv

VCS_OPTS = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca

VCS_OUTPUT = -o simv
VCS_INCDIR = +incdir+tb +incdir+rtl
VCS_SRC_FILES = ./rtl/ram.sv ./tb/ram_if.sv ./tb/ram_pkg.sv ./tb/tb_ram.sv

TEST ?= ram_random_test
SEED ?= 1
INFO_LEVEL ?= UVM_MEDIUM

SIMV_OPTS = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)

SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_dir coverage.vdb
SIMV_OPTS += -cm_name sim1


.PHONY: all compile simv clean

all: simv

compile:
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) $(VCS_OUTPUT)
	@echo "vcs 컴파일 중"

simv: compile
	./simv $(SIMV_OPTS)
	@echo "vcs 시뮬레이션 중"

clean:
	rm -rf \
		simv simv.daidir simv.vdb \
		csrc \
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
	@echo "clean 중"~