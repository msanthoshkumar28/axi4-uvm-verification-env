vlib work
vlog top.sv +incdir+C:/Users/ADMIN/OneDrive/Documents/uvm-1.2/uvm-1.2/src
vsim -novopt -suppress 12110 top -sv_lib C:/questasim64_10.7c/uvm-1.2/win64/uvm_dpi
add wave -r sim:/top/*
run -all
