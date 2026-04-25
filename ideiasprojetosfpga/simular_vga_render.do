transcript on

set script_dir [file dirname [file normalize [info script]]]
set rtl_dir $script_dir
set old_cwd [pwd]

if {![file exists [file join $rtl_dir vga_sync.vhd]]} {
    set rtl_dir [file join $script_dir src]
}

set tb_file [file join $script_dir tb_vga_render.vhd]
if {![file exists $tb_file]} {
    set tb_file [file join $rtl_dir tb_vga_render.vhd]
}

if {![file exists [file join $rtl_dir vga_sync.vhd]] || ![file exists [file join $rtl_dir game_logic.vhd]] || ![file exists $tb_file]} {
    puts "Erro: arquivos VHDL nao encontrados."
    puts "Esperado em: $script_dir ou $script_dir/src"
    return -code error
}

cd $script_dir

if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vcom -93 -work work [file join $rtl_dir vga_sync.vhd]
vcom -93 -work work [file join $rtl_dir game_logic.vhd]
vcom -93 -work work $tb_file

vsim work.tb_vga_render
run 120 ms
quit -sim

cd $old_cwd
