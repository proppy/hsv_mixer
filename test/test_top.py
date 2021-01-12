import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random
from test.test_encoder import Encoder

async def reset(dut):
    dut.enc0_a <= 0
    dut.enc0_b <= 0
    dut.enc1_a <= 0
    dut.enc1_b <= 0
    dut.enc2_a <= 0
    dut.enc2_b <= 0
    dut.reset_n <= 0

    await ClockCycles(dut.clk, 5)
    dut.reset_n <= 1;
    await ClockCycles(dut.clk, 5) # how long to wait for the debouncers to clear

@cocotb.test()
async def test_all(dut):
    clock = Clock(dut.clk, 10, units="us")
    clocks_per_phase = 10
    encoder0 = Encoder(dut.clk, dut.enc0_a, dut.enc0_b, clocks_per_phase = clocks_per_phase, noise_cycles = clocks_per_phase / 4)
    encoder1 = Encoder(dut.clk, dut.enc1_a, dut.enc1_b, clocks_per_phase = clocks_per_phase, noise_cycles = clocks_per_phase / 4)
    encoder2 = Encoder(dut.clk, dut.enc2_a, dut.enc2_b, clocks_per_phase = clocks_per_phase, noise_cycles = clocks_per_phase / 4)

    cocotb.fork(clock.start())

    await reset(dut)
    assert dut.enc0 == 0
    assert dut.enc1 == 0
    assert dut.enc2 == 0

    # pwm should all be low at start
    assert dut.pwm0_out == 0
    assert dut.pwm1_out == 0
    assert dut.pwm1_out == 0

    # do 3 ramps for each encoder up to a smaller amount as the test with clock divider is much slower
    max_count = 255
    for encoder, dut_enc in zip([encoder0, encoder1, encoder2], [dut.enc0, dut.enc1, dut.enc2]):
        for i in range(clocks_per_phase * 2 * max_count):
            await encoder.update(1)

        # let noisy transition finish, otherwise can get an extra count
        for i in range(10):
            await encoder.update(0)
        
        assert(dut_enc == max_count)

    # sync to pwm
    await RisingEdge(dut.pwm0_out)
    # pwm should all be on for max_count 
    for i in range(max_count): 
        assert dut.pwm0_out == 1
        assert dut.pwm1_out == 1
        assert dut.pwm2_out == 1
        await ClockCycles(dut.clk, 1)
