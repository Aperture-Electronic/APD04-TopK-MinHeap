ida_database -open -name="ida.db"
ida_probe -log -sv_flow -uvm_reg -log_objects -sv_modules -wave -wave_probe_args "-depth all -all -memories -variables -packed 4096 -unpacked 68 -dynamic"
# ida_probe -log -sv_flow -uvm_reg -log_objects -sv_modules -wave -wave_probe_args "-depth all -all -memories -variables -packed 4096 -unpacked 68 -dynamic" -start_time 9425355000ps -end_time 9515855000ps
run

