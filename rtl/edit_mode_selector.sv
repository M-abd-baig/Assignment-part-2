`timescale 1ns / 1ps
module edit_mode_selector #(
    parameter int HOLD_CYCLES = 50000000
) (
    input logic clk,
    input logic button,
    output logic [2:0] mode_enable
);
  logic long_press;
  button_hold_pulse #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_hold_pulse (
      .clk(clk),
      .button(button),
      .pulse(long_press)
  );
  logic press;
  rising_edge_detector u_detector (
      .clk(clk),
      .sig_in(button),
      .rise(press)
  );
  logic reset_counter;
  logic enable_counter;
  logic [1:0] count;
  mod_n_counter #(
      .N(3),
      .WIDTH(2)
  ) u_mod_3_counter (
      .clk(clk),
      .rst(reset_counter),
      .enable(enable_counter),
      .count(count)
  );
  logic armed;
  logic disarm;
  arming_latch u_latch (
      .clk(clk),
      .arm(long_press),
      .disarm(disarm),
      .armed(armed)
  );
  // Counter behavior wiring
  assign enable_counter = armed && press;

  // Clear counter when not in edit mode or when wrapping from Hours back to Normal
  assign reset_counter  = (!armed) || (count == 2'b10 && enable_counter);
  assign disarm         = (count == 2'b10 && enable_counter);

  // Decode the 3-bit one-hot enable vector:
  // count == 00 -> 3'b001 (Seconds)
  // count == 01 -> 3'b010 (Minutes)
  // count == 10 -> 3'b100 (Hours)
  assign mode_enable    = armed ? (3'b001 << count) : 3'b000;
endmodule




