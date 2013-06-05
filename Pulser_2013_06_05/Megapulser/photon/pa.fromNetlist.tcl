
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name photon -dir "C:/Users/lattice/Desktop/Grand unified pulser/Megapulser/photon/planAhead_run_1" -part xc6slx45fgg484-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/lattice/Desktop/Grand unified pulser/Megapulser/photon/photon.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/lattice/Desktop/Grand unified pulser/Megapulser/photon} {ipcore_dir} }
add_files [list {C:/Users/lattice/Desktop/Grand unified pulser/Megapulser/photon/pulser_ram.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/dacbox_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/dds_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/fifo_photon.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/normal_pmt_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/pulser_ram.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/pulse_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/readout_count_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/sec_normal_pmt_fifo.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "xem6010.ucf" [current_fileset -constrset]
add_files [list {xem6010.ucf}] -fileset [get_property constrset [current_run]]
link_design
