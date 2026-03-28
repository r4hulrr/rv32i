SIM     = sim
SRCDIR  = src
TBDIR   = tb
SRCS    = $(wildcard $(SRCDIR)/*.sv)
TB      = $(TBDIR)/top_tb.sv

.PHONY: all sim clean

all: sim

sim: $(SRCS) $(TB)
	iverilog -g2012 -o $(SIM) $(SRCS) $(TB) && vvp $(SIM)

clean:
	rm -f $(SIM)
