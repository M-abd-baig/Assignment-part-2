`timescale 1ns / 1ps
module button_auto_repeat #(
    parameter int HOLD_CYCLES   = 50000000,
    parameter int REPEAT_CYCLES = 5000000
) (
    input  logic clk,
    input  logic button,
    output logic pulse
);
  logic rise;
  logic held;
  logic pulse_train;

  rising_edge_detector u_rising_edge_detector (
      .clk(clk),
      .sig_in(button),
      .rise(rise)
  );

  // Detect that the button has been held long enough to enable repeats.
  // The first repeat must fire AT cycle HOLD_CYCLES, so 'held' must be
  // asserted by cycle HOLD_CYCLES - REPEAT_CYCLES so that the rate
  // generator's first tick lands on cycle HOLD_CYCLES.
  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES - REPEAT_CYCLES + 1)
  ) u_button_hold_detect (
      .clk(clk),
      .button(button),
      .held(held)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(REPEAT_CYCLES)
  ) u_restartable_rate_generator (
      .clk (clk),
      .run (held),
      .tick(pulse_train)
  );

  assign pulse = rise | (button & pulse_train);
endmodule

/*The behaviour can be summarised as:
    press → immediate pulse (rise)
hold... hold... hold... (HOLD_CYCLES passes, held=1)
tick, tick, tick... (pulse_train fires every REPEAT_CYCLES, held lets it through)
release → everything resets*/
