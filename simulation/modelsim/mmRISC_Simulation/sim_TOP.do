# Convert hex to memh
#exec ../../../tools/hex2v ../../../workspace/mmRISC_SampleCPU/Debug/mmRISC_SampleCPU.hex > rom.memh
exec ../../../tools/hex2v ../../../workspace/mmRISC_SampleFPU/Debug/mmRISC_SampleFPU.hex > rom.memh

# Directory
set DIR_RTL ../../../verilog
set FPGA_RTL ../../../fpga

# Compile
#   +define+MULTI_HART \
#   +define+RAM_WAIT \
#   +define+FPGA \

vlib work
vmap work work

vlog \
    -work work \
    -sv \
    +incdir+$DIR_RTL/common \
    +incdir+$DIR_RTL/ahb_sdram/model \
    +incdir+$DIR_RTL/i2c/i2c/trunk/rtl/verilog \
    -timescale=1ns/100ps \
    +define+SIMULATION \
    +define+den512Mb \
    +define+sg75     \
    +define+x16      \
    $DIR_RTL/chip/chip_top.v \
    $DIR_RTL/ram/ram.v      \
    $DIR_RTL/ram/ram_fpga.v \
    $FPGA_RTL/RAM128KB_DP.v \
    $DIR_RTL/port/port.v \
    $DIR_RTL/uart/uart.v                              \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_top.v   \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_fifo4.v \
    $DIR_RTL/uart/sasc/trunk/rtl/verilog/sasc_brg.v   \
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
#$DIR_RTL/../fpga/PLL.v \

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
#
add wave -hex -position end  sim:/tb_TOP/cpu_res
add wave -hex -position end  sim:/tb_TOP/cpu_clk
add wave -hex -position end  sim:/tb_TOP/cpu_stall
add wave -hex -position end  sim:/tb_TOP/cpu_bcc
add wave -hex -position end  sim:/tb_TOP/cpu_cmp
add wave -hex -position end  sim:/tb_TOP/count_bcc
add wave -hex -position end  sim:/tb_TOP/count_bcc_stall
add wave -hex -position end  sim:/tb_TOP/count_bcc_taken
add wave -hex -position end  sim:/tb_TOP/count_bcc_not_taken
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycle
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycleh
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstret
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstreth

add wave -divider RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/RES_N
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/por_n
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/res_org
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/res_pll
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/locked_pll
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/locked_reg
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/locked
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/RES_ORG
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/SRSTn
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/SRSTn_IN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/SRSTn_OUT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/RES_SYS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/res_dm
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/ndmreset
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/havereset
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/res_dmihard_async
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/RES_DBG
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_RESET

add wave -divider JTAG
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TCK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TMS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TDI
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/TDO
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TDO_D
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TDO_E
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/TRSTn
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/SRSTn
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/res_tap_async
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dtmcs_dmihardreset_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dtmcs_dmireset_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/res_dmihard_async
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/RES_DBG
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/state_tap_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/state_tap_next_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/ir_sft_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/ir_tap_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/bypass_sft_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/idcode_sft_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dtmcs_sft_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dtmcs_rdata_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_sft_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_rdata_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_status_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_cmd_in_progress_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_wr_put_try_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_wr_put_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_wr_rdy_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_wr_data_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_rd_get
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_rd_rdy
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmiwr_rd_data
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_wr_put
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_wr_rdy
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_wr_data
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_rd_get_try_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_rd_get_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_rd_rdy_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmird_rd_data_tck
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_op_cmd_rd
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_op_cmd_wr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_op_cmd
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_busy
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/dmi_state

##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/dbgabs_req_gpr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/dbgabs_req_fpr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/gpr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/fpr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HSEL
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HTRANS
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HWRITE
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HMASTLOCK
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HSIZE
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HBURST
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HPROT
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HADDR
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HWDATA
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HREADY
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HREADYOUT
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HRDATA
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/CPUD_M_HRESP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hsel
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_htrans
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hwrite
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_haddr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hwdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hrdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hready
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/m_hreadyout
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hsel
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_htrans
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hwrite
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_haddr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hwdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hrdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hready
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/s_hreadyout

#add wave -divider AHB_MATRIX
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HSEL
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HTRANS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HWRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HMASTLOCK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HSIZE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HBURST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HPROT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HWDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HREADY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HREADYOUT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HRDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_HRESP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/M_PRIORITY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HSEL
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HTRANS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HWRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HMASTLOCK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HSIZE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HBURST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HPROT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HWDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HREADY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HREADYOUT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HRDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HRESP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HADDR_BASE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/S_HADDR_MASK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_phase_a_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_phase_a_1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_phase_d
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_#addr_req
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_#addr_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_MASTER_PORT/m_hreadyout_0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_INTERCONNECT/phase_a_req
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_INTERCONNECT/phase_a_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_INTERCONNECT/phase_a_req_winner
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_INTERCONNECT/phase_a_ack_winner
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_AHB_MATRIX/U_AHB_INTERCONNECT/s_hmastlock

add wave -divider DMBUS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_RW
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DTM_JTAG/DMBUS_ERR

add wave -divider DM
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/authok
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/rdata_dm_control
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dm_control
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dm_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/haltreq
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/resumereq
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/hasel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/hartsel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/ha_sel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dm_hawindowsel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dm_hamask
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_HALT_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_STATUS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_AVAILABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_HALT_ON_RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_RESUME_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/HART_RESUME_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/rdata_dm_status
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allhavereset
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anyhavereset
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allresumeack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anyresumeack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allnoexistent
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anynoexistent
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allunavail
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anyunavail
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allrunning
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anyrunning
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/allhalted
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/anyhalted
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_RW
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DMBUS_ERR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sel_dm_command
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_TYPE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_SIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_DONE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_REQ_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_ACK_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_TYPE_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_WRITE_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_ADDR_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_WDATA_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_RDATA_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/DBGABS_DONE_internal
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/ha_sel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/abstract_busy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/cmderr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dbgabs_arg0_read
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dbgabs_arg0_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dbgabs_arg1_incr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/dbgabs_autoincr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sbcs
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sbaddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sbdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sel_dm_sbcs
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sel_dm_sbaddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sel_dm_sbdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sb_req
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sb_ack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sbbusy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sb_done
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sb_req_readonaddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_DEBUG_TOP/U_DEBUG_DM/sb_req_readondata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HSEL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HTRANS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HWRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HSIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HWDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HREADY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HREADYOUT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HRDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/DBGD_M_HRESP

#add wave -divider CPU
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/DEBUG_MODE
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_HALT_REQ
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_STATUS
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_RESET
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_HALT_ON_RESET
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_RESUME_REQ
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_RESUME_ACK
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/HART_AVAILABLE

#add wave -divider CPU_CSR
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/dbgabs_req_csr_dcsr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/dbgabs_rdata_csr_dcsr
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/dbgabs_req_csr_dpc
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/csr_default
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/csr_dpc
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/dbgabs_req_csr_tselect
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/dbgabs_rdata_csr_tselect
##add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP_0/U_CPU_DEBUG_CSR/csr_tselect

#add wave -divider CPU_FETCH
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_START
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_STOP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/FETCH_ADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_SEQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_CONT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_BURST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_LOCK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_PROT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_WRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_SIZE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_ADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/busi_m_#addr_next
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_WDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_LAST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_RDATA_RAW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/BUSI_M_DONE_RAW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_busy
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_jump
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/if_#addr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_we_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_re_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cw_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cl_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_count_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_full_issue
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_we_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_re_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cw_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_cl_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_count_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_wp_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_rp_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_empty_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fifo_room_full_body
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSEL[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HTRANS[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWRITE[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HMASTLOCK[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSIZE[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HBURST[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HPROT[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HADDR[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWDATA[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADY[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADYOUT[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRDATA[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRESP[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_#addr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_jump
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/fetch_done_berr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1_size
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2_size
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0_stat_next
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf0_stat
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf1_stat
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/code_buf2_stat
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/jump_buf2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_ADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_CODE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_BERR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FETCH/DECODE_JUMP

#add wave -divider CPU_TOP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_req
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_last
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_done
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_done_raw
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_rdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_m_rdata_raw
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_aphase
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_dphase
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busa_after
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_req
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_last
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_done
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_done_raw
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_rdata
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_m_rdata_raw
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_aphase
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_dphase
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/busm_after
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_ADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_WDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_LAST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_DONE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_DONE_RAW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_RDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/BUSD_M_RDATA_RAW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSEL[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HTRANS[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWRITE[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HMASTLOCK[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSIZE[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HBURST[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HPROT[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HADDR[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWDATA[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HREADY[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HREADYOUT[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HRDATA[0]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HRESP[0]

#add wave -divider CPU_PIPELINE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_ope
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_ope_nxt
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_ope_upd
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_seq
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_seq_inc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_seq_nxt
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_seq_upd
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_ex_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_ex_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_ex_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_reset
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_jal
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_jalr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_bcc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_cj
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/jump_target_cbcc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/FETCH_START
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/FETCH_STOP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/FETCH_ADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/FETCH_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_ACK

#add wave -divider CPU_DECODE_STAGE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/regXR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[2]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[2]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[2]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[2]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[2]/U_CPU_TOP/U_CPU_DATAPATH/regXR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[3]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[3]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[3]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[3]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[3]/U_CPU_TOP/U_CPU_DATAPATH/regXR

#add wave -divider CPU_DATAPATH
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_FUNC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_RSLT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_IMM
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_FUNC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/id_busA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/id_busB
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busX
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busZ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/wb_busW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/ex_busS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_MARDY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/MA_MDRDY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_MACMD
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_STSRC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/WB_MACMD
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/WB_LOAD_DST

add wave -divider RAMD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HSEL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HTRANS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HWRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HMASTLOCK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HSIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HBURST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HPROT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HWDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HREADY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HREADYOUT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HRDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMD/S_HRESP

add wave -divider RAMI
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HSEL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HTRANS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HWRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HMASTLOCK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HSIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HBURST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HPROT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HWDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HREADY
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HREADYOUT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HRDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_RAMI/S_HRESP

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
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/stall
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_ex_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_AMO_LRSVD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/EX_AMO_SCOND
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/lrsvd_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/lrsvd_addr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/lrsvd_pollute
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/scond_unspecified
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/scond_failure
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/scond_success
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/scond_dst_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_alu_src1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_alu_src2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_alu_src3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_alu_dst1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_alu_dst2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_dec_src1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_dec_src2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/id_stsrc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/ex_load_dst
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/ma_load_dst
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

add wave -hex -divider CPU_DEBUG
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS_CHAIN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS_ACTION
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS_MATCH
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS_MASK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_BUS_HIT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_CND_TDATA2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_REQ_INST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_REQ_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_ACK_INST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_ACK_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/INSTR_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/INSTR_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/INSTR_CODE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_SIZE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_LAST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/BUSM_M_DONE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_rdata_reg
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_rdata_mem
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_req_reg
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_req_mem
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_ack_reg
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_ack_mem
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_done_reg
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/dbgabs_done_mem
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_addr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_addr_before
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_code_before
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_addr_before
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_code_before
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_addr_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_code_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_addr_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_code_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_addr_after
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_16b_code_after
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_addr_after
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit_32b_code_after
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_inst_hit
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_active_ma
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_active_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_write_ma
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_write_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_size_ma
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_size_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_addr_ma
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_addr_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_wdata_ma
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_wdata_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/busm_rdata_wb
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_addr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_rdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_wdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_08b_raddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_08b_waddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_08b_rdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_08b_wdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_16b_raddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_16b_waddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_16b_rdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_16b_wdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_32b_raddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_32b_waddr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_32b_rdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit_32b_wdata
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_data_hit
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_req_inst
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_req_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_req_icnt
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_req_inst_temp
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/trg_req_data_temp
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_REQ_INST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_REQ_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_ACK_INST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DEBUG/TRG_ACK_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/DEBUG_MODE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/INSTR_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR

add wave -divider CSR_DBG
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_HALT_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_STATUS
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_HALT_ON_RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_RESUME_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_RESUME_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/HART_AVAILABLE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_STOP_COUNT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_STOP_TIMER
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_MIE_STEP
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_HALT_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_HALT_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_HALT_RESET
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_HALT_EBREAK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_RESUME_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_RESUME_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_DPC_SAVE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_DPC_LOAD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/DBG_CAUSE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/INSTR_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_dcsr_ebreakm
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_dcsr_stepie
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_dcsr_stopcount
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_dcsr_stoptime
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_dcsr_step
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_tselect
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_mcontrol
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_rdata_tdata1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_tdata2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_icount
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_icount_count
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/csr_icount_reload
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/trg_cnd_bus_chain_temp
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/TRG_CND_BUS_CHAIN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/TRG_CND_ICOUNT_HIT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/TRG_CND_ICOUNT_ACT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_DBG/TRG_CND_ICOUNT_DEC

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
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mstatus
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mie
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mip
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycle
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcycleh
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstret
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_minstreth
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/csr_mcountinhibit
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INSTR_EXEC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/IRQ_MTIME
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/IRQ_MSOFT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/IRQ_EXT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INTCTRL_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INTCTRL_NUM
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INTCTRL_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MTVEC_EXP
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MTVAL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MEPC_SAVE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MEPC_LOAD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MCAUSE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/EXP_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/MRET_ACK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INT_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR/INT_ACK

#add wave -divider CSR_INTC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/CSR_INT_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/CSR_INT_WRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/CSR_INT_#addR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/CSR_INT_WDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/CSR_INT_RDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/IRQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/mintcurlvl
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/mintprelvl
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/mintcfgpriority
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/bit_max
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/irq3_tour
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/irq2_tour
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/irq1_tour
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/irq0_tour
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/intctrl_req
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/intctrl_num
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/intctrl_lvl
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/INTCTRL_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/INTCTRL_NUM
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_CSR_INT/INTCTRL_ACK

#add wave -divider CPU[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSEL[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWRITE[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSIZE[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HADDR[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWDATA[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADYOUT[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRDATA[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSEL[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWRITE[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSIZE[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HADDR[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWDATA[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HREADYOUT[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HRDATA[1]
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_ID_ENABLE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_EX_ENABLE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_MA_ENABLE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/PIPE_WB_ENABLE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_REQ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/DECODE_ACK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/decode_ack
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/decode_stp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/slot
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/stall
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_ex1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_ex2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_id1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_wb_id2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_ex_id1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/fwd_ex_id2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/regXR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_DEC_SRC2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_FUNC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_CMP_RSLT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_SRC2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_IMM
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_DST2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_ALU_FUNC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/id_busA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/id_busB
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ex_busX
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ex_busY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ex_busZ
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/wb_busW
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ex_busS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/aluout1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/aluout2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/mulout
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/divout
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_MARDY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/MA_MDRDY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_MACMD
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/EX_STSRC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/WB_MACMD
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/WB_LOAD_DST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_FUNC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_EXEC
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/ID_DIV_BUSY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/div_count
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/dividened
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/dividened_sign
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/divisor
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/quotient
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/remainder
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/quotient_out
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[1]/U_CPU_TOP/U_CPU_DATAPATH/remainder_out

#add wave -divider CSR_MTIME
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/CLK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/RES
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HSEL
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HTRANS
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HWRITE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HMASTLOCK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HSIZE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HBURST
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HPROT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HADDR
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HWDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HREADY
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HREADYOUT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HRDATA
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/S_HRESP
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/CSR_MTIME_EXTCLK
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/csr_mtime_extclk_sync1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/csr_mtime_extclk_sync2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/csr_mtime_extclk_sync3
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/dphase_active
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/dphase_#addr
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/dphase_write
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_ctrl
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_ctrl_enable
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_ctrl_clksrc
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_ctrl_inte
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_ctrl_ints
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_tick_match
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_clkenb
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_div
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_div_div
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/prescaler
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/prescaler_match
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_tick
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_wbuf
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtime_rbuf
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtimeh
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtimeh_rbuf
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtimecmp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtimecmp_wbuf
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/mtimecmph
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/IRQ_MTIME
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_CSR_MTIME/IRQ_MSOFT

#add wave -divider GPIO
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdd0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdd1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdd2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdr0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdr1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/pdr2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/GPIO0
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/GPIO1
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_PORT/GPIO2

add wave -divider UART
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/TXD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/RXD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/din_i
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/dout_o
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/re_i
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/we_i
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/IRQ_UART
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/clk
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/rst
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/div0
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/div1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/sio_ce
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/sio_ce_x4
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/ps
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/ps_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/br_cnt
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/br_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/sio_ce_x4_r
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/cnt
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/sio_ce_r
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_UART/BRG/sio_ce_x4_t

#add wave -divider FPU32_INNER79_FROM_FLOAT32
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/FLOAT32
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/INNER79
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/float32_sign
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/float32_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/float32_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/inner79_sign
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/inner79_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/inner79_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_INNER79_FROM_FLOAT32/pos

#add wave -divider FPU32_FLOAT32_FROM_INNER79
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/INNER79
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/FLOAT32
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/RMODE
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/FLAG_IN
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/FLAG_OUT
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_sign
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_sign
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_zero_select
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_zero_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_zero_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_zero_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_toosmall_select
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_toosmall_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_toosmall_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_toosmall_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_normal_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_sofar_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_overflow_select
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_overflow_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_overflow_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_overflow_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_underflow_select
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_underflow_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_underflow_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_underflow_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_select
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_frac_temp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_frac_temp2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_flag_temp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_frac_right_shift
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/inner79_subnormal_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_subnormal_pos
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_expo_temp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_frac_temp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_frac_temp2
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_flag_temp
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_normal_pos
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_expo
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_frac
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/float32_flag
#add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FLOAT32_FROM_INNER79/FLOAT32

add wave -divider FPU32
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/RES_CPU
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/CLK
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSEL[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWRITE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HSIZE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HADDR[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HWDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HRDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUI_M_HREADYOUT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSEL[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWRITE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HSIZE[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HADDR[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HWDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HRDATA[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/CPUD_M_HREADYOUT[0]
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/stall
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/ID_FPU_STALL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_DATAPATH/regXR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/DBGABS_FPR_REQ
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/DBGABS_FPR_WRITE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/DBGABS_FPR_ADDR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/DBGABS_FPR_WDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/DBGABS_FPR_RDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_DST1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_SRC1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_FPU_DSTDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_FPU_SRCDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_FPU_ST_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/WB_FPU_LD_DATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/WB_LOAD_DST
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_STSRC
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/regFR
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_SRC1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_SRC2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_SRC3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_DST1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_SRC1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_SRC2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_SRC3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_ALU_DST1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_CMD
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_RMODE
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/ID_FPU_STALL
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpu_ack
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_ope_f2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_mac_f2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_exe_f2x_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_exe_x2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_exe_f2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_cvt_f2x_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_cvt_x2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/id_fpu_flw_x2f_rdy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_ma_busy_set
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_ma_busy_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_ma_busy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_dv_busy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_sq_busy
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_fpu_set
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_fpu_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_fpu
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_alu_set
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_alu_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_alu
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_flw_set
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_flw_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpureg_dirty_flw
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/conflict_fpu
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/conflict_alu
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/conflict_flw
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_i_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_m_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_a_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_f_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_d_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_s_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_float_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_float_in3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_inner_out1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_inner_out2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/idata_inner_out3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mdata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mdata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mdata_inner_in3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mdata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/adata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/adata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/adata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fdata_inner_in
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fdata_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_f_i1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_f_i2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_f_i3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_w_i1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_w_i2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fpubyp_w_i3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mspecial_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mspecial_float_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mspecial_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mspecial_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/mspecial_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aspecial_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aspecial_float_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aspecial_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aspecial_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aspecial_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_float_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_float_in3
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/maspecial_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/dspecial_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/dspecial_float_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/dspecial_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/dspecial_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/dspecial_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sspecial_float_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sspecial_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sspecial_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sspecial_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_m_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_m_special_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_m_special_flag
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_a_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_a_special_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_a_special_flag
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/adata_inner_out2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/aflag_out2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_d_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_d_special_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_d_special_flag
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_f_special
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_f_special_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_f_special_flag
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fdata_inner_in
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fdata_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fdata_float_out_final
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fflag_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fflag_out_final
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_fflags_set
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_fflags
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_dv_busy_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_complete
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_seq
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_sel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_cnt
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_da_sign_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_db_sign_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_da_expo_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_db_expo_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_da_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_db_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_dy_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_dq_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_de_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_mdata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_mdata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_mdata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_adata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_adata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/div_adata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_sq_busy_clr
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_complete
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_seq
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_sel
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_cnt
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_db_sign_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_db_expo_keep
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_db_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_dy_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_dg_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_dh_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_dr_inner
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_mdata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_mdata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_mdata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_adata_inner_in1
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_adata_inner_in2
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/sqr_adata_inner_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_sqr_loop
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_div_loop
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_frm
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/csr_fflags
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_c_token
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_f2i_float_in
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_f2i_int_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_f2i_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_c_int_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/pipe_c_fflags_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/FLOAT_IN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/sign
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/expo
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/frac
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/judge_zro
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/judge_inf_s
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/judge_inf_u
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/uint32_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/uint32_data_round
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_F2I/INT_OUT
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/EX_FPU_DSTDATA
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_i2f_int_in
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_i2f_float_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/fcvt_i2f_flg_out
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/INT_IN
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/uint32_data
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/pos
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/sign
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/expo
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/frac
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/frac_round
add wave -hex -position end  sim:/tb_TOP/U_CHIP_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_FPU32/U_FCVT_I2F/FLOAT_OUT

add wave -divider SDRAM
add wave -hex -position end  sim:/tb_TOP/sdram_clk
add wave -hex -position end  sim:/tb_TOP/sdram_cke
add wave -hex -position end  sim:/tb_TOP/sdram_csn
add wave -hex -position end  sim:/tb_TOP/sdram_dqm
add wave -hex -position end  sim:/tb_TOP/sdram_rasn
add wave -hex -position end  sim:/tb_TOP/sdram_casn
add wave -hex -position end  sim:/tb_TOP/sdram_wen
add wave -hex -position end  sim:/tb_TOP/sdram_ba
add wave -hex -position end  sim:/tb_TOP/sdram_addr
add wave -hex -position end  sim:/tb_TOP/sdram_dq

add wave -divider I2C
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/CLK
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/RES
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HSEL
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HTRANS
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HWRITE
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HMASTLOCK
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HSIZE
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HBURST
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HPROT
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HADDR
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HWDATA
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HREADY
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HREADYOUT
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HRDATA
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/S_HRESP
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SCL_I
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SCL_O
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SCL_OEN
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SDA_I
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SDA_O
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/I2C_SDA_OEN
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/IRQ_I2C
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_stb_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_cyc_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_we_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_adr_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_dat_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_dat_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/wb_ack_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_I2C/U_I2C_CORE/tip

add wave -divider SPI
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/CLK
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/RES
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HSEL
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HTRANS
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HWRITE
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HMASTLOCK
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HSIZE
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HBURST
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HPROT
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HADDR
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HWDATA
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HREADY
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HREADYOUT
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HRDATA
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/S_HRESP
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/SPI_CSN
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/SPI_SCK
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/SPI_MOSI
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/SPI_MISO
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/IRQ_SPI
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/wb_stb_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/wb_cyc_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/wb_we_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/wb_adr_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/wb_dat_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_stb_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_cyc_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_we_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_adr_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_dat_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_dat_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/core_wb_ack_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_stb_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_cyc_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_we_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_adr_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_dat_o
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_dat_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs_wb_ack_i
add wave -position end  sim:/tb_TOP/U_CHIP_TOP/U_SPI/spcs

# Do Simulation with logging all signals in WLF file
log -r *
run -all

