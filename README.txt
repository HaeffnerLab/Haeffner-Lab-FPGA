FPGA firmware for lattice:

Updated: Jun 1, 2013

Lattice now use differential bus pulser board. Local 729 pulser will be phased out. Use Pulser_2013_05_31.

Pulser2 is still under testing but with less urgency.

Updated: Apr 3, 2013

DDS: First generation DDS. Has to be used with pulser breakout board with single-ended line to the DDS. Currently used in lattice.
DDS_phase_coherent: Second generation DDS with differential line. Currently used for 729 source in the laser room.
DDS2: Second generation DDS with unlocked configuration. Under testing.

Pulser_differential_bus: Pulser with diff bus. Currently used for 729 source in laser room.
Pulser_w_line_triggering: Currently used with lattice experiment. Single-ended but to DDS.
Pulser2: SDRAM+diff_line implemented. Currently under testing.

SDRAM_python: sample python script to test various function of Pulser2.