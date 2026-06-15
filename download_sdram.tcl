proc load_image {bin_file {base_addr 0x02000000}} {
    set master_paths [get_service_paths master]
    if {[llength $master_paths] == 0} {
        puts "ERROR: No JTAG master found. Please check the USB-Blaster connection."
        return -1
    }

    set m_path [lindex $master_paths 0]
    set claim_path [claim_service master $m_path ""]

    puts "==================================================="
    puts "  Loading RGB565 Image into SDRAM"
    puts "  File    : $bin_file"
    puts "  Address : $base_addr  (= VGA BUFFER_A_BASE)"
    puts "==================================================="

    if {![file exists $bin_file]} {
        puts "ERROR: File '$bin_file' not found."
        close_service master $claim_path
        return -1
    }

    set fsize [file size $bin_file]
    set expected 614400
    if {$fsize != $expected} {
        puts "WARNING: File size = $fsize bytes, expected $expected bytes (640x480x2)."
        puts "         Continuing anyway..."
    }

    master_write_from_file $claim_path $bin_file $base_addr

    close_service master $claim_path

    puts "==================================================="
    puts "  Image loading completed!"
    puts "  -> Press '1' + Enter in the JTAG UART terminal"
    puts "     to enable VGA display."
    puts "==================================================="
    return 0
}

# If called from command line with a filename:
set argc [llength $argv]
if {$argc >= 1} {
    set bin_file [lindex $argv 0]
    load_image $bin_file
} else {
    # Default filename
    load_image "tom_and_jerry.bin"
}