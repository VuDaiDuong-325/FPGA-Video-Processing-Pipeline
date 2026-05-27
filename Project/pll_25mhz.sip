set_global_assignment -entity "pll_25mhz" -library "lib_pll_25mhz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_25mhz" -library "lib_pll_25mhz" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "pll_25mhz" -library "lib_pll_25mhz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_25mhz" -name SPD_FILE [file join $::quartus(sip_path) "pll_25mhz.spd"]

set_global_assignment -library "lib_pll_25mhz" -name MISC_FILE [file join $::quartus(sip_path) "pll_25mhz_sim/pll_25mhz.vo"]
