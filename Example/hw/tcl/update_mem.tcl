set PROJECT_NAME "soc"
set IMEM_HEX "../sw/build/imem.hex"
set DMEM_HEX "../sw/build/dmem.hex"
set TOP_MODULE "Computer"

puts ">>> [1/8] Open project..."
# Open project from the soc directory
open_project "soc/$PROJECT_NAME.xpr"

puts ">>> [2/8] Set Top Module..."
set_property top $TOP_MODULE [current_fileset]
update_compile_order -fileset sources_1

puts ">>> [3/8] Set property..."
set_property SEVERITY {Warning} [get_drc_checks REQP-1839]
set_property {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} {} [get_runs synth_1]

puts ">>> [4/8] Update Hex..."
add_files -norecurse -force $IMEM_HEX
add_files -norecurse -force $DMEM_HEX

puts ">>> [5/8] Start Synthesis..."
reset_run synth_1

puts ">>> [6/8] Start Implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4

puts ">>> [7/8] Waiting..."
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Fail to Generate Bitstream"
    puts ">>> print Log <<<"
    set log_file "soc/$PROJECT_NAME.runs/impl_1/runme.log"
    if {[file exists $log_file]} {
        exec tail -n 50 $log_file >@stdout
    }
    exit 1
}

puts ">>> Generate Bitstream Completely!"
close_project
exit