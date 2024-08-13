# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test //a1
    dut.ui_in.value = 0
    dut.uio_in.value = 62

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    
   # Set the input values you want to test //b1
    dut.ui_in.value = 0
    dut.uio_in.value = 65

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    
   # Set the input values you want to test //a2
    dut.ui_in.value = 0
    dut.uio_in.value = 64
   # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    
   # Set the input values you want to test //b2
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    await ClockCycles(dut.clk, 1)
    
   # Set the input values you want to test //a3
    dut.ui_in.value = 0
    dut.uio_in.value = 66
    await ClockCycles(dut.clk, 1)
    
   # Set the input values you want to test //b3
    dut.ui_in.value = 0
    dut.uio_in.value = 62

    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 65
   # Set the input values you want to test //a4
    dut.ui_in.value = 0
    dut.uio_in.value = 64
   # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 0
   # Set the input values you want to test //b4
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 66
     # Set the input values you want to test //a5
    dut.ui_in.value = 0
    dut.uio_in.value = 66
   # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 128
   # Set the input values you want to test //b5
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 68
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 64
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 68
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 192
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 69
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 192

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values
