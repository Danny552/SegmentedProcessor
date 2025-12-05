transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/quartus/ARQUITECTURA/single-cycle {C:/quartus/ARQUITECTURA/single-cycle/top_level.sv}
vlog -sv -work work +incdir+C:/quartus/ARQUITECTURA/single-cycle {C:/quartus/ARQUITECTURA/single-cycle/pc.sv}
vlog -sv -work work +incdir+C:/quartus/ARQUITECTURA/single-cycle {C:/quartus/ARQUITECTURA/single-cycle/hex7seg.sv}

