# Makefile for Raspberry Pi GPIO programs
#
# Requirements:
#   - lgpio library (install: sudo apt install liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod)
#
# Usage:
#   make         - Build all programs
#   make sonic   - Build sonic program
#   make servo   - Build servo program
#   make clean   - Remove all compiled programs
#   make install - Install programs to /usr/local/bin (requires sudo)

CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -llgpio

# All programs (lgpio only)
PROGRAMS = sonic servo

# Installation directory
INSTALL_DIR = /usr/local/bin

.PHONY: all clean install help

# Default target
all: $(PROGRAMS)

# Build individual programs
sonic: sonic.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built $@ successfully"

servo: servo.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built $@ successfully"

# Clean build artifacts
clean:
	rm -f $(PROGRAMS)
	rm -f distance  # Remove distance output file if present
	@echo "Cleaned all build artifacts"

# Install to system (requires sudo)
install: all
	@echo "Installing programs to $(INSTALL_DIR)..."
	install -m 755 $(PROGRAMS) $(INSTALL_DIR)/
	@echo "Installation complete"

# Uninstall from system (requires sudo)
uninstall:
	@echo "Removing programs from $(INSTALL_DIR)..."
	cd $(INSTALL_DIR) && rm -f $(PROGRAMS)
	@echo "Uninstall complete"

# Help message
help:
	@echo "Raspberry Pi GPIO Programs Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make         - Build all programs"
	@echo "  make sonic   - Build ultrasonic sensor program"
	@echo "  make servo   - Build servo motor control program"
	@echo "  make clean   - Remove compiled programs"
	@echo "  make install - Install to /usr/local/bin (requires sudo)"
	@echo "  make uninstall - Remove from /usr/local/bin (requires sudo)"
	@echo "  make help    - Show this help message"
	@echo ""
	@echo "Programs:"
	@echo "  sonic  - HC-SR04 ultrasonic distance sensor"
	@echo "  servo  - Standard servo motor control with PWM"
	@echo ""
	@echo "Requirements:"
	@echo "  - lgpio library: sudo apt install liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod"
