set project_name "soc"
set part_name "xc7a100tcsg324-1"

# 1. Build proj in ./soc/ directory
create_project -force $project_name ./soc -part $part_name

# 2. Add Sources from ./src/
add_files [glob ./src/*.v]
if {[llength [glob -nocomplain ./src/*.vh]] > 0} {
    add_files [glob ./src/*.vh]
}
if {[llength [glob -nocomplain ./src/*.hex]] > 0} {
    add_files [glob ./src/*.hex]
}
if {[llength [glob -nocomplain ./src/*.xdc]] > 0} {
    add_files -fileset constrs_1 [glob ./src/*.xdc]
}

# =======================================================
#	IP Miss, Rebuild
# =======================================================
puts ">>> Rebuild clk_wiz_0 IP..."
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0

set_property -dict [list \
  CONFIG.PRIM_IN_FREQ {100.000} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {20.000} \
  CONFIG.USE_RESET {false} \
  CONFIG.USE_LOCKED {false} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
create_ip_run [get_ips clk_wiz_0]

# Set Include Path to src
set_property include_dirs [glob ./src] [current_fileset]
update_compile_order -fileset sources_1

puts ">>> Project Structure Created in hw/soc/!"
close_project
exit