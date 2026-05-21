
`timescale 1ns / 1ps

// ------------------------------------------------------------------
// Stopwatch Implementation
// ------------------------------------------------------------------

/* verilator lint_off UNUSEDSIGNAL */


`timescale 1ns / 1ps

module user_top_stopwatch_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // Internal signals
  logic rise_start_stop, rise_lap;
  logic counter_rst, counter_enable, lap_hold;
  logic [6:0] minutes, centiseconds;
  logic [5:0] seconds;
  logic [6:0] display_minutes, display_centiseconds;
  logic [5:0] display_seconds;

  // Rising edge detectors
  rising_edge_detector u_start_stop (
      .clk(clk),
      .sig_in(~button[0]),
      .rise(rise_start_stop)
  );

  rising_edge_detector u_lap (
      .clk(clk),
      .sig_in(~button[1]),
      .rise(rise_lap)
  );

  // Handle simultaneous presses
  wire actual_rise_start_stop = rise_start_stop & ~rise_lap;
  wire actual_rise_lap = rise_lap & ~rise_start_stop;

  // Stopwatch counter
  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk(clk),
      .rst(counter_rst),
      .enable(counter_enable),
      .minutes(minutes),
      .seconds(seconds),
      .centiseconds(centiseconds)
  );

  // Snapshot mux for lap
  snapshot_mux #(
      .WIDTH(7)
  ) u_mux_minutes (
      .clk(clk),
      .hold(lap_hold),
      .d(minutes),
      .q(display_minutes)
  );

  snapshot_mux #(
      .WIDTH(6)
  ) u_mux_seconds (
      .clk(clk),
      .hold(lap_hold),
      .d(seconds),
      .q(display_seconds)
  );

  // Stopwatch control
  stopwatch_control u_control (
      .clk(clk),
      .rise_start_stop(actual_rise_start_stop),
      .rise_lap(actual_rise_lap),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .lap_hold(lap_hold)
  );

  // Outputs - FOR TEST: map counter directly to see if it's counting
  assign led           = 10'b0;
  assign hours_disp    = 7'b0;
  assign minutes_disp  = minutes;  // Direct from counter (skip mux for debugging)
  assign seconds_disp  = {1'b0, seconds};  // Direct from counter (skip mux)
  assign blank_hours   = 1'b0;  // Changed to 0 to show value
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

endmodule


/* verilator lint_on UNUSEDSIGNAL */
