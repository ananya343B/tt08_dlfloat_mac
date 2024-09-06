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
    #######1ST SET###########
    # Set the input values a1=1
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    await ClockCycles(dut.clk, 1)
    # Set the input values b1=3
    dut.ui_in.value = 0
    dut.uio_in.value = 65
    await ClockCycles(dut.clk, 1)
    ######2ND SET############
    # Set the input values a2=1
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    await ClockCycles(dut.clk, 1)
    # Set the input values b2=2
    dut.ui_in.value = 0
    dut.uio_in.value = 64
    await ClockCycles(dut.clk, 1)
    ######3RD SET###############
     # Set the input values a3=1
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    await ClockCycles(dut.clk, 1)
    # Set the input values b3=4
    dut.ui_in.value = 0
    dut.uio_in.value = 66
    await ClockCycles(dut.clk, 1)
    ######4TH SET###############
     # Set the input values a4=1
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    
    #1ST SET OUTPUT VERIF LSB
    assert dut.uo_out.value == 0
    
    await ClockCycles(dut.clk, 1)  
    # Set the input values b4=2
    dut.ui_in.value = 0
    dut.uio_in.value = 64
    
    #1ST SET OUTPUT VERIF MSB
    assert dut.uo_out.value == 65 
    await ClockCycles(dut.clk, 1)
    ######5TH SET###############
     # Set the input values a4=1
    dut.ui_in.value = 0
    dut.uio_in.value = 62
    
    #2ND SET OUTPUT VERIF LSB
    assert dut.uo_out.value == 128
    
    await ClockCycles(dut.clk, 1)  
    # Set the input values b4=2
    dut.ui_in.value = 0
    dut.uio_in.value = 64
    
    #2ND SET OUTPUT VERIF MSB
    assert dut.uo_out.value == 66 
    
    
   #OUTPUT VERIF
    ##########3RD SET#############
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 64
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 68
    ##########4TH SET#############
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 192
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 68
    ##########5TH SET#############
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 64
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 69

   
    


   
