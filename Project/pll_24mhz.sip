set_global_assignment -entity "pll_24mhz" -library "lib_pll_24mhz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_24mhz" -library "lib_pll_24mhz" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "pll_24mhz" -library "lib_pll_24mhz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_24mhz" -name SPD_FILE [file join $::quartus(sip_path) "pll_24mhz.spd"]

set_global_assignment -library "lib_pll_24mhz" -name MISC_FILE [file join $::quartus(sip_path) "pll_24mhz_sim/pll_24mhz.vo"]
