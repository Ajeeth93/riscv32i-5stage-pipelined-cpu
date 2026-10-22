# Test program for the 5-stage pipeline (Harris & Harris riscvtest)
# Exercises forwarding, a load-use stall, a taken beq and a jal.
# Passes when it stores 25 to address 100.
#
# Addr  Machine   Assembly              Effect
  0000  00500113  addi x2, x0, 5        # x2 = 5
  0004  00c00193  addi x3, x0, 12       # x3 = 12
  0008  ff718393  addi x7, x3, -9       # x7 = 12 - 9 = 3          (forward from MEM)
  000c  0023e233  or   x4, x7, x2       # x4 = 3 | 5 = 7           (forward from MEM, reads x2 from reg file)
  0010  0041f2b3  and  x5, x3, x4       # x5 = 12 & 7 = 4
  0014  004282b3  add  x5, x5, x4       # x5 = 4 + 7 = 11
  0018  02728863  beq  x5, x7, end      # not taken
  001c  0041a233  slt  x4, x3, x4       # x4 = (12 < 7) = 0
  0020  00020463  beq  x4, x0, around   # taken -> 2 flushed slots
  0024  00000293  addi x5, x0, 0        # skipped
  0028  0023a233  slt  x4, x7, x2       # around: x4 = (3 < 5) = 1
  002c  005203b3  add  x7, x4, x5       # x7 = 1 + 11 = 12
  0030  402383b3  sub  x7, x7, x2       # x7 = 12 - 5 = 7
  0034  0471aa23  sw   x7, 84(x3)       # mem[96] = 7
  0038  06002103  lw   x2, 96(x0)       # x2 = mem[96] = 7
  003c  005104b3  add  x9, x2, x5       # x9 = 7 + 11 = 18         (load-use stall)
  0040  008001ef  jal  x3, end          # x3 = 0x44, jump -> 2 flushed slots
  0044  00100113  addi x2, x0, 1        # skipped
  0048  00910133  add  x2, x2, x9       # end: x2 = 7 + 18 = 25
  004c  0221a023  sw   x2, 0x20(x3)     # mem[100] = 25  -> PASS condition
  0050  00210063  beq  x2, x2, done     # done: infinite loop
