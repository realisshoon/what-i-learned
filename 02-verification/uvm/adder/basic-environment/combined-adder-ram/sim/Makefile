SIM ?= xrun
TOP ?= tb_adder

.PHONY: all clean

all:
	$(SIM) -sv -uvm -f filelist.f -top $(TOP)

clean:
	rm -rf xcelium.d xrun.history xrun.log waves.shm
