create_clock -name CLK50 -period  20.000 [get_ports {CLK50}]
create_clock -name CLK   -period  50.000 [get_nets {U_CHIP_TOP|U_PLL|altpll_component|auto_generated|wire_pll1_clk[0]}]
create_clock -name CLK   -period  60.000 [get_nets {U_CHIP_TOP|U_PLL|altpll_component|auto_generated|wire_pll1_clk[1]}]
create_clock -name CLKLO -period 10000.0 [get_nets {U_CHIP_TOP|U_PLL|altpll_component|auto_generated|wire_pll1_clk[2]}]
create_clock -name LOCK  -period 100.000 [get_nets {U_CHIP_TOP|U_PLL|altpll_component|auto_generated|locked}]
derive_pll_clocks
derive_clock_uncertainty
set_false_path   -to [get_ports {RESOUT_N}]
set_input_delay  -clock {CLK50}  5 [get_ports {RES_N}]
set_output_delay -clock {CLK  }  0 [get_ports {RESOUT_N}]
set_input_delay  -clock {CLK  } 10 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*]}]
set_output_delay -clock {CLK  } 10 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*]}]
set_input_delay  -clock {CLK  } 10 [get_ports {RXD}]
set_output_delay -clock {CLK  } 10 [get_ports {TXD}]
set_input_delay  -clock {CLK  } 10 [get_ports {I2C0_SCL I2C0_SDA I2C0_INT1 I2C0_INT2}]
set_output_delay -clock {CLK  } 10 [get_ports {I2C0_SCL I2C0_SDA}]
set_input_delay  -clock {CLK  } 10 [get_ports {I2C1_SCL I2C1_SDA}]
set_output_delay -clock {CLK  } 10 [get_ports {I2C1_SCL I2C1_SDA}]
set_input_delay  -clock {CLK  } 10 [get_ports {SPI_MISO}]
set_output_delay -clock {CLK  } 10 [get_ports {SPI_CSN[*] SPI_SCK SPI_MOSI}]
set_input_delay  -clock {CLK  } 20 [get_ports {SDRAM_DQ[*]}]
set_output_delay -clock {CLK  } 20 [get_ports {SDRAM_DQ[*] SDRAM_ADDR[*]}]
set_output_delay -clock {CLK  } 20 [get_ports {SDRAM_CSn SDRAM_RASn SDRAM_CASn SDRAM_WEn}]
set_output_delay -clock {CLK  } 20 [get_ports {SDRAM_CKE SDRAM_BA[*] SDRAM_DQM[*]}]
set_output_delay -clock {CLK  } 10 [get_ports {SDRAM_CLK}]
set_output_delay -clock {CLKLO}  0 [get_ports {RESOUT_N}] -add_delay
set_input_delay  -clock {CLKLO} 10 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*]}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*]}] -add_delay
set_input_delay  -clock {CLKLO} 10 [get_ports {RXD}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {TXD}] -add_delay
set_input_delay  -clock {CLKLO} 10 [get_ports {I2C0_SCL I2C0_SDA I2C0_INT1 I2C0_INT2}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {I2C0_SCL I2C0_SDA}] -add_delay
set_input_delay  -clock {CLKLO} 10 [get_ports {I2C1_SCL I2C1_SDA}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {I2C1_SCL I2C1_SDA}] -add_delay
set_input_delay  -clock {CLKLO} 10 [get_ports {SPI_MISO}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {SPI_CSN[*] SPI_SCK SPI_MOSI}] -add_delay
set_input_delay  -clock {CLKLO} 20 [get_ports {SDRAM_DQ[*]}] -add_delay
set_output_delay -clock {CLKLO} 20 [get_ports {SDRAM_DQ[*] SDRAM_ADDR[*]}] -add_delay
set_output_delay -clock {CLKLO} 20 [get_ports {SDRAM_CSn SDRAM_RASn SDRAM_CASn SDRAM_WEn}] -add_delay
set_output_delay -clock {CLKLO} 20 [get_ports {SDRAM_CKE SDRAM_BA[*] SDRAM_DQM[*]}] -add_delay
set_output_delay -clock {CLKLO} 10 [get_ports {SDRAM_CLK}] -add_delay
set_clock_groups -asynchronous -group [get_clocks {CLKLO} ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {CLKLO}]

create_clock -name TCKi  -period 100.000 [get_ports {TCK  }]
create_clock -name TCKo  -period 100.000 [get_ports {TCKC_rep}]
set_clock_groups -asynchronous -group [get_clocks {TCKi } ] -group [get_clocks {CLK50}]
set_clock_groups -asynchronous -group [get_clocks {TCKi } ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {TCKi } ] -group [get_clocks {CLKLO}]
set_clock_groups -asynchronous -group [get_clocks {TCKi } ] -group [get_clocks {TCKo }]
set_clock_groups -asynchronous -group [get_clocks {TCKo } ] -group [get_clocks {CLK50}]
set_clock_groups -asynchronous -group [get_clocks {TCKo } ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {TCKo } ] -group [get_clocks {CLKLO}]
set_clock_groups -asynchronous -group [get_clocks {TCKo } ] -group [get_clocks {TCKi }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {TCKi }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {TCKo }]
set_input_delay  -clock {TCKi }  5 [get_ports {TRSTn TMS TDI}]
set_input_delay  -clock {TCKo }  5 [get_ports {TRSTn TMS TDI}] -add_delay
set_output_delay -clock {TCKi }  5 [get_ports {TDO}]
set_output_delay -clock {TCKo }  5 [get_ports {TDO}] -add_delay
set_false_path   -from [get_ports {TCK      }] -to [get_ports {TCKC_pri}]
set_false_path   -from [get_ports {TMS TDI  }] -to [get_ports {TMSC_pri}]
set_false_path   -from [get_ports {GPIO2[10]}] -to [get_ports {TMSC_pri}]
set_false_path   -from [get_ports {TMSC_pri }] -to [get_ports {TDO     }]
set_input_delay  -clock {CLK  }  5 [get_ports {TCKC_rep}]
set_input_delay  -clock {CLK  }  5 [get_ports {TMSC_rep}]
set_output_delay -clock {CLK  }  5 [get_ports {TMSC_rep}]
set_output_delay -clock {CLK  }  5 [get_ports {TMSC_PUP_rep}]
set_output_delay -clock {CLK  }  5 [get_ports {TMSC_PDN_rep}]
set_input_delay  -clock {CLK  }  5 [get_ports {RES_N}] -add_delay
set_output_delay -clock {CLK  }  5 [get_ports {STBY_ACK_N}]
set_input_delay  -clock {CLKLO}  5 [get_ports {TCKC_rep}] -add_delay
set_input_delay  -clock {CLKLO}  5 [get_ports {TMSC_rep}] -add_delay
set_output_delay -clock {CLKLO}  5 [get_ports {TMSC_rep}] -add_delay
set_output_delay -clock {CLKLO}  5 [get_ports {TMSC_PUP_rep}] -add_delay
set_output_delay -clock {CLKLO}  5 [get_ports {TMSC_PDN_rep}] -add_delay
set_input_delay  -clock {CLKLO}  5 [get_ports {RES_N}] -add_delay
set_output_delay -clock {CLKLO}  5 [get_ports {STBY_ACK_N}] -add_delay

create_clock -name TCKC  -period 100.000 [get_ports {TCKC_rep  }] -add
create_clock -name TMSC  -period 100.000 [get_ports {TMSC_rep  }]
set_clock_groups -asynchronous -group [get_clocks {TCKC } ] -group [get_clocks {CLK50}]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {CLK50}]
set_clock_groups -asynchronous -group [get_clocks {TCKC } ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {CLK  }]
set_clock_groups -asynchronous -group [get_clocks {TCKC } ] -group [get_clocks {CLKLO}]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {CLKLO}]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {TCKC }]
set_clock_groups -asynchronous -group [get_clocks {TCKC } ] -group [get_clocks {TCKo }]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {TCKo }]
set_clock_groups -asynchronous -group [get_clocks {TCKC } ] -group [get_clocks {TCKi }]
set_clock_groups -asynchronous -group [get_clocks {TMSC } ] -group [get_clocks {TCKi }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {TCKC }]
set_clock_groups -asynchronous -group [get_clocks {LOCK } ] -group [get_clocks {TMSC }]
set_input_delay  -clock {TCKC }  5 [get_ports {TMSC_rep}] -add_delay
set_output_delay -clock {TCKC }  5 [get_ports {TMSC_rep}] -add_delay
set_input_delay  -clock {TMSC }  5 [get_ports {TCKC_rep}] -add_delay
set_output_delay -clock {TMSC }  5 [get_ports {TCKC_rep}] -add_delay
