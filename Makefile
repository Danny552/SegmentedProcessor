PROJECT = riscvpc

# Quartus tools
QUARTUS_SH = quartus_sh
QUARTUS_PGM = quartus_pgm

# TCL scripts
BUILD_TCL = build.tcl
PROGRAM_TCL = program.tcl

# Default target
all: build

build: $(PROJECT).sof

$(PROJECT).sof: $(BUILD_TCL)
	@echo "Building project using TCL script..."
	@SECONDS=0; \
	$(QUARTUS_SH) -t $(BUILD_TCL); \
	echo -e "\033[1;36m⏱️  Build completed in $$SECONDS seconds\033[0m"

# Program FPGA - only check if SOF exists, don't rebuild
program: check-sof $(PROGRAM_TCL)
	@echo "Programming FPGA using TCL script..."
	$(QUARTUS_SH) -t $(PROGRAM_TCL)

# Check if SOF file exists without rebuilding
check-sof:
	@if [ ! -f "output_files/$(PROJECT).sof" ]; then \
		echo "Error: SOF file not found. Run 'make build' first."; \
		exit 1; \
	fi

# Force program (rebuild if needed)
program-force: $(PROJECT).sof $(PROGRAM_TCL)
	@echo "Programming FPGA using TCL script..."
	$(QUARTUS_SH) -t $(PROGRAM_TCL)

# Alternative: Program using quartus_pgm directly
program-direct: check-sof
	@echo "Programming FPGA directly..."
	$(QUARTUS_PGM) -c "DE-Soc" -m JTAG -o "P;output_files/$(PROJECT).sof@2"

# Show project info
info:
	@echo "Project: $(PROJECT)"
	@echo "Build script: $(BUILD_TCL)"
	@echo "Program script: $(PROGRAM_TCL)"
	@ls -la $(PROJECT).qpf $(PROJECT).qsf 2>/dev/null || echo "Project files not found"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf db incremental_db output_files
	@rm -f *.rpt *.summary *.qws *.sof *.pof *.jdi *.pin *.done *.qdf
	@echo "Clean completed!"

# Force rebuild
rebuild: clean build

# Build and program in one step
build-program: build program

# Check if TCL scripts exist
check-scripts:
	@echo "Checking TCL scripts..."
	@test -f $(BUILD_TCL) || (echo "Error: $(BUILD_TCL) not found!" && exit 1)
	@test -f $(PROGRAM_TCL) || (echo "Error: $(PROGRAM_TCL) not found!" && exit 1)
	@echo "TCL scripts found!"

# Show build status
status:
	@echo "=== Project Status ==="
	@echo "Project: $(PROJECT)"
	@if [ -f "output_files/$(PROJECT).sof" ]; then \
		echo "✓ SOF file exists: output_files/$(PROJECT).sof"; \
		ls -lh output_files/$(PROJECT).sof; \
	else \
		echo "✗ SOF file not found"; \
	fi
	@if [ -f "$(PROJECT).qsf" ]; then \
		echo "✓ QSF file exists"; \
	else \
		echo "✗ QSF file missing"; \
	fi

# Help target
help:
	@echo "Available targets:"
	@echo "  all/build      - Build the project using TCL script"
	@echo "  program        - Program FPGA (no rebuild)"
	@echo "  program-force  - Program FPGA (rebuild if needed)"
	@echo "  program-direct - Program FPGA directly with quartus_pgm"
	@echo "  build-program  - Build and program in one step"
	@echo "  clean          - Remove build artifacts"
	@echo "  rebuild        - Clean and build"
	@echo "  info           - Show project information"
	@echo "  status         - Show build status"
	@echo "  check-scripts  - Verify TCL scripts exist"
	@echo "  help           - Show this help"

.PHONY: all build program program-force program-direct build-program clean rebuild info status check-sof check-scripts help