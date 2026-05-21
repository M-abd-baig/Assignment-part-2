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
  logic [6:0] minutes, seconds, centiseconds;
  logic [6:0] display_minutes, display_seconds, display_centiseconds;

  // Rising edge detectors for buttons - FIXED port names
  rising_edge_detector u_start_stop (
      .clk(clk),
      .sig_in(~button[0]),  // Changed from 'in' to 'sig_in'
      .rise(rise_start_stop)  // Changed from 'out' to 'rise'
  );

  rising_edge_detector u_lap (
      .clk   (clk),
      .sig_in(~button[1]),  // Changed from 'in' to 'sig_in'
      .rise  (rise_lap)     // Changed from 'out' to 'rise'
  );

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

  // Snapshot mux for lap functionality
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
      .d(seconds[5:0]),
      .q(display_seconds[5:0])
  );

  // For centiseconds - need 7 bits (0-99)
  snapshot_mux #(
      .WIDTH(7)
  ) u_mux_centiseconds (
      .clk(clk),
      .hold(lap_hold),
      .d(centiseconds),
      .q(display_centiseconds)
  );

  // Stopwatch control FSM
  stopwatch_control u_control (
      .clk(clk),
      .rise_start_stop(rise_start_stop),
      .rise_lap(rise_lap),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .lap_hold(lap_hold)
  );

  // Output assignments
  assign led = 10'b0;
  assign hours_disp = 7'b0;  // No hours for stopwatch
  assign minutes_disp = display_minutes;
  assign seconds_disp = display_seconds;

  // Blanking: show minutes and seconds, blank hours
  assign blank_hours = 1'b1;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

endmodule
