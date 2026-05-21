// ------------------------------------------------------------------
// WARNING: This file is used by the automated test suite. Do not
// modify it.
//
// This file also serves as a template for your own designs. To use
// it:
//   1. Copy the entire contents into a new file with a descriptive
//      name.
//   2. Delete the test logic below and replace it with your own
//      code.
//   3. In top_de1_soc, change the module name from user_top to your
//      new module name.
//
//   The board wrapper sets CYCLES_PER_SECOND; use this parameter in
//   your design wherever timing is needed.
// ------------------------------------------------------------------
`timescale 1ns / 1ps

module user_top_watch_v1 #(
    //core Functionality
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [3:0] button,
    input logic [9:0] sw,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  //seconds
  logic [5:0] seconds;
  logic seconds_tick;
  logic seconds_edit;
  logic seconds_inc;
  logic seconds_dec;

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds)
  );

  //minutes
  logic [5:0] minutes;
  logic minutes_tick;
  logic minutes_edit;
  logic minutes_inc;
  logic minutes_dec;

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .tick(minutes_tick),
      .edit_mode(minutes_edit),
      .inc(minutes_inc),
      .dec(minutes_dec),
      .count(minutes)
  );

  //hours
  logic [4:0] hours;
  logic hours_tick;
  logic hours_edit;
  logic hours_inc;
  logic hours_dec;

  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .tick(hours_tick),
      .edit_mode(hours_edit),
      .inc(hours_inc),
      .dec(hours_dec),
      .count(hours)
  );

  //derive 1Hz tick from system clock

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_divider_1_Hz_seconds (
      .clk (clk),
      .run (1'b1),
      .tick(seconds_tick)
  );

  assign seconds_edit = 1'b0;
  assign seconds_dec = 1'b0;
  assign seconds_inc = 1'b0;


  assign minutes_edit = 1'b0;
  assign minutes_dec = 1'b0;
  assign minutes_inc = 1'b0;


  assign hours_edit = 1'b0;
  assign hours_dec = 1'b0;
  assign hours_inc = 1'b0;

  assign minutes_tick = seconds_tick && (seconds == 6'd59);
  assign hours_tick = minutes_tick && (minutes == 6'd59);
  assign hours_disp = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};
  // Unused
  assign led = 10'b0;
  assign blank_hours = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;




endmodule
