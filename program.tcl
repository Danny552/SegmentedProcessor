# Define project and programming file
set project "riscvpc"
set sof_file "output_files/$project.sof"

# Set this variables accrodingly to your board configuration

set cable "DE-Soc"
set device  "2"

# Change accordingly to your operating system
set redirect "2>@1"  ;# Windows: Redirect stderr to stdout
# set redirect "2>/dev/null"  ;# Linux: Suppress stderr output

# Program the FPGA
puts "Programming FPGA with $sof_file..."

if {[catch {exec quartus_pgm -c "$cable" -m JTAG -o "P;$sof_file@$device" $redirect} error_message]} {
    puts "Error during programming: $error_message"
    exit 1
}

puts "FPGA successfully programmed!"