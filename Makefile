# Path & files
#  Source
WORK_DIR        = $(shell pwd)
DESIGN_DIR      = $(WORK_DIR)/proj
INCDIR          = $(DESIGN_DIR)/include
PACKAGE_DIR     = $(DESIGN_DIR)/pkg
INTERFACE_DIR   = $(DESIGN_DIR)/if
SRC_DIR         = $(DESIGN_DIR)/src
EXTPROC_MDL_DIR = $(WORK_DIR)/lib
DC_DIR          = $(WORK_DIR)/dc
DC_OUTPUT_DIR   = $(DC_DIR)/dc_output
DPICMODEL_DIR   = $(EXTPROC_MDL_DIR)
LD_LIBRARY_PATH = $(DPICMODEL_DIR)

# Design
DESIGN_UNIT   = apd04_topk_minheap_tb
UVM_UNITTEST  = 

# UVM settings
UVM_TESTNAME  = 
UVM_TESTCASE  = 
UVM_CASELIMIT = 10
UVM_VERBOSITY = UVM_LOW

#  Testbench & UVM
# If the UVM_UNITTEST is empty, then do the top-level test
ifeq ($(strip $(UVM_UNITTEST)),)
	TESTBENCH_DIR = $(DESIGN_DIR)/tb
else 
	TESTBENCH_DIR = $(DESIGN_DIR)/tb/unit/$(UVM_UNITTEST)
endif
ifneq ($(strip $(UVM_TESTNAME)),)
	UVM_AGENT_DIR   = $(TESTBENCH_DIR)/agent
	UVM_ENV_DIR     = $(TESTBENCH_DIR)/env
	UVM_OBJ_DIR     = $(TESTBENCH_DIR)/obj
	UVM_RM_DIR      = $(TESTBENCH_DIR)/rm
	UVM_TEST_DIR    = $(TESTBENCH_DIR)/test
	UVM_SEQ_DIR     = $(TESTBENCH_DIR)/seq
	UVM_SEQER_DIR   = $(TESTBENCH_DIR)/seqer
	UVM_SCB_DIR     = $(TESTBENCH_DIR)/scb
	UVM_MONITOR_DIR = $(TESTBENCH_DIR)/mon
	UVM_DRIVER_DIR  = $(TESTBENCH_DIR)/drv
	UVM_SEQITEM_DIR = $(TESTBENCH_DIR)/seq_item
	UVM_IF_DIR      = $(TESTBENCH_DIR)/if
endif

# DPI library
DPICMODEL_LIB   = 

FILELIST_FILE   = $(WORK_DIR)/filelist.f
NETLIST_FL_FILE = $(WORK_DIR)/filelist_ns.f
SYNLIST_FILE    = $(WORK_DIR)/synlist.f
XRUN_DIR        = $(WORK_DIR)/xrun
XRUN_NS_DIR     = $(WORK_DIR)/xrun_ns
XRUN_SCRIPT     = $(WORK_DIR)/xrun.tcl
XRUN_DBG_SCRIPT = $(WORK_DIR)/xrun_debug.tcl
XRUN_LOG        = $(WORK_DIR)/xrun.log
VCS_DIR         = $(WORK_DIR)/vcs
VCS_LOG         = $(WORK_DIR)/vcs.log
DC_DIR          = $(WORK_DIR)/dc
DC_SCRIPT       = $(WORK_DIR)/syn_dc.tcl
DC_NETLIST      = $(DC_OUTPUT_DIR)/netlist.v

# Cadence Xcelium
XRUN = xrun
INDAGO = indago
IMC = imc

# MCE Setting
MCE = # -mce

# DPI-C model setting
ifneq ($(strip $(DPICMODEL_LIB)),)
	DPICMODEL = -sv_lib $(DPICMODEL_LIB) 
endif

# UVM settings
ifneq ($(strip $(UVM_TESTNAME)),)
	UVM_ARGUMENTS = +UVM_TESTNAME=$(UVM_TESTNAME) +UVM_TESTCASE=$(UVM_TESTCASE) +UVM_CASELIMIT=$(UVM_CASELIMIT) +UVM_TESTQP=$(UVM_TESTQP)
endif

# Synopsys VCS
VCS = vcs

# Synopsys Design Compiler
DC = dc_shell

# Compile options
XRUN_OPTS = -64bit -sv -access +rwc -accessreg +rwc -debug -ml_uvm -uvmlinedebug -top $(DESIGN_UNIT) +UVM_VERBOSITY=$(UVM_VERBOSITY) -classlinedebug -plidebug -fsmdebug -uvmaccess -date -dumpstack -negdelay -timescale 1ns/1ps -lwdgen -incdir $(INCDIR) $(MCE) +define+USE_DEFAULT_NETTYPE_WIRE $(UVM_ARGUMENTS) -notimingcheck -delay_mode zero -sequdp_nba_delay -coverage all -covtest $(DESIGN_UNIT) -covoverwrite

VCS_OPTS  = -full64 -j32 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -debug_acc+all -lca -kdb +incdir+$(INCDIR) -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed +define+USE_DEFAULT_NETTYPE_WIRE +notimingcheck +delay_mode_zero -cm line+tgl+cond+fsm+branch+assert -cm_dir $(VCS_DIR)/$(DESIGN_UNIT).vdb -assert svaext -top $(DESIGN_UNIT)

DC_OPTS   = -64bit -no_gui -x "set search_path $(INCDIR)" 

# The UVM testbenches need to be build as follow sequence: IF, SEQITEM, SEQ, SEQER, RM, DRV, MON, AGENT, SCB, ENV, TEST
flist:  # Put the sources into the filelist.f
	@echo "Generating $(FILELIST_FILE), testbench path is $(TESTBENCH_DIR)"
	@find $(PACKAGE_DIR) -name "*.sv" > $(FILELIST_FILE)
	@find $(INTERFACE_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(SRC_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(SRC_DIR) -name "*.v" >> $(FILELIST_FILE)
ifneq ($(strip $(UVM_TESTNAME)),)
	@find $(UVM_IF_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_OBJ_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_SEQITEM_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_SEQ_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_SEQER_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_DRIVER_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_MONITOR_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_AGENT_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_SCB_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_RM_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_ENV_DIR) -name "*.sv" >> $(FILELIST_FILE)
	@find $(UVM_TEST_DIR) -name "*.sv" >> $(FILELIST_FILE)
endif
	@find $(TESTBENCH_DIR) -maxdepth 1 -name "*.sv" >> $(FILELIST_FILE)

synlist: # Put source files into the syn_filelist.f
	@echo "Generating $(SYNLIST_FILE)"
	@find $(SRC_DIR) -name "*.sv" >> $(SYNLIST_FILE)
	@find $(INTERFACE_DIR) -name "*.sv" >> $(SYNLIST_FILE)

mklib: # Make library under LIBRARY_DIR
ifneq ($(strip $(DPICMODEL_LIB)),)
	@echo "Making library"
	@mkdir -p $(DPICMODEL_DIR)/build 
	@cd $(DPICMODEL_DIR)/build && cmake .. && make
endif

run: flist mklib
	@echo "Running Xcelium"
	@mkdir -p $(XRUN_DIR)
	@cd $(XRUN_DIR) && $(XRUN) $(XRUN_OPTS) -f $(FILELIST_FILE) -input $(XRUN_SCRIPT) -l $(XRUN_LOG) $(DPICMODEL)

cov:
	@echo "Merging coverage data"
	@cd $(XRUN_DIR) && $(IMC) -execcmd "merge * -overwrite -out full_cov"
	@cd $(XRUN_DIR) && $(IMC) -load cov_work/scope/full_cov &

# Clean the backup files
clbak: # Clean all .bak files
	@echo "Cleaning .bak files"
	@find . -name "*.bak" -exec rm {} \;

# Clean command
clean: # Clean the directory
	@echo "Cleaning directory"
ifneq ($(strip $(XRUN_DIR)),)
	@rm -rf $(XRUN_DIR)/*
endif
ifneq ($(strip $(DC_DIR)),)
	@rm -rf $(DC_DIR)/*
endif


