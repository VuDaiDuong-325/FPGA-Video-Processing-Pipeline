transcript on
if ![file isdirectory doan_iputf_libs] {
	file mkdir doan_iputf_libs
}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

###### Libraries for IPUTF cores 
###### End libraries for IPUTF cores 
###### MIF file copy and HDL compilation commands for IPUTF cores 


vlog "D:/E/1subject/HK6/SoC/doan/doan/sys_pll_sim/sys_pll.vo"
vlog "D:/E/1subject/HK6/SoC/doan/doan/vga_pll_sim/vga_pll.vo"

vlog -vlog01compat -work work +incdir+D:/E/1subject/HK6/SoC/doan/doan {D:/E/1subject/HK6/SoC/doan/doan/VGA_controller.v}

vlog -vlog01compat -work work +incdir+D:/E/1subject/HK6/SoC/doan/doan {D:/E/1subject/HK6/SoC/doan/doan/tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run -all
