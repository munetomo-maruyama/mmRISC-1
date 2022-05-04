# Directory
set DIR_RTL ../../../verilog
set FPGA_RTL ../../../fpga

vlib work
vmap work work

# Compile
vlog \
    -work work \
    -sv \
    +incdir+$DIR_RTL/common \
    +incdir+$DIR_RTL/ahb_sdram/model \
    +incdir+$DIR_RTL/i2c/i2c/trunk/rtl/verilog \
    -timescale=1ns/100ps \
    +define+RISCV_ARCH_TEST \
    +define+SIMULATION \
    +define+den512Mb \
    +define+sg75     \
    +define+x16      \
    +define+BUS_INTERVENTION_01 \
    +define+DUMP_BGN=32'h90004010 \
    +define+DUMP_END=32'h900048e0 \
    +define+TOHOST=32'h90003000 \
    $DIR_RTL/chip/chip_top.v \
    $DIR_RTL/ram/ram.v \
    $DIR_RTL/ram/ram_fpga.v \
    $FPGA_RTL/RAM128KB_DP.v\
    $DIR_RTL/port/port.v \
    $DIR_RTL/uart/uart.v \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_top.v \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_fifo4.v \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_brg.v \
    $DIR_RTL/i2c/i2c.v                                        \
    $DIR_RTL/i2c/i2c/trunk/rtl/verilog/i2c_master_top.v       \
    $DIR_RTL/i2c/i2c/trunk/rtl/verilog/i2c_master_bit_ctrl.v  \
    $DIR_RTL/i2c/i2c/trunk/rtl/verilog/i2c_master_byte_ctrl.v \
    $DIR_RTL/i2c/i2c_slave_model.v                            \
    $DIR_RTL/spi/spi.v                                         \
    $DIR_RTL/spi/simple_spi/trunk/rtl/verilog/simple_spi_top.v \
    $DIR_RTL/spi/simple_spi/trunk/rtl/verilog/fifo4.v          \
    $DIR_RTL/int_gen/int_gen.v \
    $DIR_RTL/mmRISC/mmRISC.v \
    $DIR_RTL/mmRISC/bus_m_ahb.v \
    $DIR_RTL/mmRISC/csr_mtime.v \
    $DIR_RTL/cpu/cpu_top.v \
    $DIR_RTL/cpu/cpu_fetch.v \
    $DIR_RTL/cpu/cpu_datapath.v \
    $DIR_RTL/cpu/cpu_pipeline.v \
    $DIR_RTL/cpu/cpu_fpu32.v \
    $DIR_RTL/cpu/cpu_csr.v \
    $DIR_RTL/cpu/cpu_csr_int.v \
    $DIR_RTL/cpu/cpu_csr_dbg.v \
    $DIR_RTL/cpu/cpu_debug.v \
    $DIR_RTL/debug/debug_top.v \
    $DIR_RTL/debug/debug_dtm_jtag.v \
    $DIR_RTL/debug/debug_cdc.v \
    $DIR_RTL/debug/debug_dm.v \
    $DIR_RTL/ahb_matrix/ahb_top.v \
    $DIR_RTL/ahb_matrix/ahb_master_port.v \
    $DIR_RTL/ahb_matrix/ahb_slave_port.v \
    $DIR_RTL/ahb_matrix/ahb_interconnect.v \
    $DIR_RTL/ahb_matrix/ahb_arb.v \
    $DIR_RTL/ahb_sdram/logic/ahb_lite_sdram.v \
    $DIR_RTL/ahb_sdram/model/sdr.v \
    ./tb_TOP.v
   
# Transcript File
#transcript file log#.txt

# Start Simulation
#vsim -c -voptargs="+acc" -L altera_mf_ver \
#    work.tb_TOP
vsim -c -voptargs="+acc" \
    -L altera_mf_ver \
    work.tb_TOP

# Add Waveform
add wave -divider TestBench
add wave -hex -position end  sim:/tb_TOP/tb_clk
add wave -hex -position end  sim:/tb_TOP/tb_res
add wave -hex -position end  sim:/tb_TOP/tb_cyc

add wave -divider RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/RES_N
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/por_n
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/res_org
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/res_pll

#add wave -divider RAMI
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/RES
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/CLK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HSEL
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HTRANS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HWRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HMASTLOCK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HSIZE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HBURST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HPROT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HWDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HREADY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HREADYOUT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HRDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HRESP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/ready_count
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_htrans
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_h#addr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_hwdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_hwrite
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_hsize
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_hmastlock
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_re_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_re_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_re_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_re_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_we_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_we_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_we_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_we_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_r#addr_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_r#addr_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_r#addr_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_r#addr_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_w#addr_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_w#addr_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_w#addr_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_w#addr_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_rdata_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_rdata_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_rdata_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_rdata_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_wdata_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_wdata_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_wdata_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_wdata_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_contention_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_contention_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_contention_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_dphase_contention_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_cdata_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_cdata_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_cdata_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/s_mem_cdata_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/rdata_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/rdata_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/rdata_2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/rdata_3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/wait_cycle

add wave -divider CPU_FETCH
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_START
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_STOP
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_SEQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_BURST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_LOCK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_PROT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_SIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/busi_m_addr_next
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_LAST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_RDATA_RAW
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_DONE_RAW
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_busy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_jump
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_addr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_we_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_re_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cw_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cl_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_count_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_full_issue
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_we_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_re_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cw_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cl_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_count_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_wp_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_rp_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_empty_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_full_body
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSEL[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HTRANS[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWRITE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HMASTLOCK[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSIZE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HBURST[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HPROT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HADDR[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADY[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADYOUT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRESP[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_addr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_jump
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_ack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_berr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1_size
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2_size
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0_stat_next
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0_stat
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1_stat
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2_stat
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf0
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_CODE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_BERR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_JUMP

add wave -divider CPU[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSEL[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWRITE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSIZE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HADDR[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADYOUT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSEL[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWRITE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSIZE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HADDR[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HREADYOUT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HRDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/EX_MARDY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/MA_MDRDY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_ID_ENABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_EX_ENABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_MA_ENABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_WB_ENABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/decode_ack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/decode_stp
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/stall
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_ex1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_ex2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_id1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_id2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_ex_id1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/fwd_ex_id2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/INT_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/WFI_THRU_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/buserr_req_align
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/buserr_req_fault
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/EX_BUSERR_ALIGN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/WB_BUSERR_FAULT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/INSTR_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_START
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_STOP
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_ex_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_FUNC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_RSLT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_ALU_SRC2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_IMM
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_FUNC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_CSR_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_csr_rdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/id_busA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/id_busB
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busX
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busZ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/wb_busW
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/aluout1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/aluout2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/mulout
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/divout
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_MARDY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/MA_MDRDY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_MACMD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_STSRC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/WB_MACMD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/WB_LOAD_DST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_FUNC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_BUSY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_DIV_ZERO
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_DIV_OVER
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/div_count
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/dividened
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/dividened_sign
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/divisor
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/quotient
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/remainder
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/quotient_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/remainder_out

add wave -divider CSR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EX_CSR_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EX_CSR_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EX_CSR_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EX_CSR_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EX_CSR_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/DBGABS_CSR_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/DBGABS_CSR_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/DBGABS_CSR_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/DBGABS_CSR_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/DBGABS_CSR_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mtvec
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mscratch
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mepc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcause
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mtval
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mip
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycle
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycleh
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstret
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstreth
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcountinhibit
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INSTR_EXEC

# Do Simulation with logging all signals in WLF file
log -r *
run -all

