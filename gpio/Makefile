# Makefile for Raspberry Pi GPIO programs
#
# Requirements:
#   - lgpio library (install: sudo apt install lgpio libgpiod-dev)
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

# Programs using lgpio (modernized)
PROGRAMS_LGPIO = sonic servo

# Legacy programs using wiringPi (deprecated - not built by default)
# PROGRAMS_LEGACY = relay_high relay_low servo_15 detect temp sonic_servo sonic_relay

# All modern programs
PROGRAMS = $(PROGRAMS_LGPIO)

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

# Legacy programs (wiringPi - not recommended)
# Uncomment if you still need wiringPi support
# relay_high: relay_high.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi
#
# relay_low: relay_low.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi
#
# servo_15: servo_15.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi -lsoftPwm
#
# detect: detect.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi
#
# temp: temp.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi
#
# sonic_servo: sonic_servo.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi -lsoftPwm
#
# sonic_relay: sonic_relay.c
# 	$(CC) $(CFLAGS) -o $@ $< -lwiringPi

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
	@echo "  - lgpio library: sudo apt install lgpio libgpiod-dev"
