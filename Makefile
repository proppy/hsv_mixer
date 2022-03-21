# FPGA variables
PROJECT = fpga/encoder_pwm
SOURCES= src/hsv_mixer.v src/encoder.v src/debounce.v src/pwm.v src/hsv2rgb.v
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = fpga/icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 1

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

all: test_encoder test_debounce test_pwm test_hsv_mixer

hsv2rgb:
	interpreter_main src/hsv2rgb.x
	ir_converter_main --entry hsv2rgb src/hsv2rgb.x > src/hsv2rgb.ir
	opt_main src/hsv2rgb.ir > src/hsv2rgb.opt.ir
	codegen_main --generator=combinational src/hsv2rgb.opt.ir > src/hsv2rgb.v

# if you run rules with NOASSERT=1 it will set PYTHONOPTIMIZE, which turns off assertions in the tests
test_hsv_mixer:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s hsv_mixer -s dump -g2012 src/hsv_mixer.v test/dump_hsv_mixer.v src/ src/encoder.v src/debounce.v src/pwm.v src/hsv2rgb.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_hsv_mixer vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

test_encoder:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s hsv_encoder -s dump -g2012 test/dump_encoder.v src/encoder.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_encoder vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

test_pwm:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s hsv_pwm -s dump -g2012 src/pwm.v test/dump_pwm.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_pwm vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

test_debounce:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s hsv_debounce -s dump -g2012 src/debounce.v test/dump_debounce.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_debounce vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

show_%: %.vcd %.gtkw
	gtkwave $^

# FPGA recipes

show_synth_%: src/%.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed"

%.json: $(SOURCES)
	yosys -l fpga/yosys.log -p 'synth_ice40 -top hsv_mixer -json $(PROJECT).json' $(SOURCES)

%.asc: %.json $(ICEBREAKER_PIN_DEF) 
	nextpnr-ice40 -l fpga/nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<

%.bin: %.asc
	icepack $< $@

prog: $(PROJECT).bin
	iceprog $<

# general recipes

lint:
	verible-verilog-lint src/*v --rules_config verible.rules

clean:
	rm -rf *vcd sim_build fpga/*log fpga/*bin test/__pycache__

.PHONY: clean
