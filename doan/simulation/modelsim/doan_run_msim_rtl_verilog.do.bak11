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


vlog "D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll_sim/sys_pll.vo"
vlog "D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/vga_pll_sim/vga_pll.vo"

vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll.vo}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/system/simulation {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/system/simulation/system.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/ov7670_capture.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/VGA_controller.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sdram_double_buffer_controller.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sdram_read_controller.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/video_dcfifo.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/mock_camera_generator.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/debug_top.v}
vlib sys_pll
vmap sys_pll sys_pll
vlog -vlog01compat -work sys_pll +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll/sys_pll_0002.v}

vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/debug_top_tb.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/sys_pll/sys_pll_0002.v}
vlog -vlog01compat -work work +incdir+D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/vga_pll {D:/HK6/SoC_Design/FPGA-Video-Processing-Pipeline/doan/vga_pll/vga_pll_0002.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -L sys_pll -voptargs="+acc"  debug_top_tb

add wave *
view structure
view signals
run -all
