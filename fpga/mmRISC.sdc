create_clock -name CLK50 -period  20.000 [get_ports {CLK50}]
create_clock -name TCK   -period 100.000 [get_ports {TCK}]
create_clock -name CLK   -period  50.000 [get_nets {U_PLL|altpll_component|auto_generated|wire_pll1_clk[0]}]
create_clock -name CLK   -period  60.000 [get_nets {U_PLL|altpll_component|auto_generated|wire_pll1_clk[1]}]
create_clock -name LOCK  -period 100.000 [get_nets {U_PLL|altpll_component|auto_generated|locked}]
derive_pll_clocks
derive_clock_uncertainty
set_input_delay  -clock {TCK  } 5 [get_ports {TDI TMS}]
set_output_delay -clock {TCK  } 5 [get_ports {TDO}]
set_input_delay  -clock {CLK  } 5 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*] RXD}]
set_output_delay -clock {CLK  } 5 [get_ports {GPIO0[*] GPIO1[*] GPIO2[*] SDRAM_CKE SDRAM_CLK SDRAM_CSn TXD}]
set_input_delay  -clock {CLK50} 1 [get_ports {RES_N}]
set_input_delay  -clock {TCK  } 1 [get_ports {TRSTn}]
