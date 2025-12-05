# Load the Quartus package
load_package flow


# Define project and programming file
set project "riscvpc"
set sof_file "$project.sof"
set cable "USB-Blaster"

# Open the project
project_open $project

# Compile the design
execute_flow -compile

# Close the project
project_close

# Program the FPGA
#puts "Programming FPGA..."
#exec quartus_pgm -c $cable -m jtag -o "P;$sof_file"
#puts "Programming completed."