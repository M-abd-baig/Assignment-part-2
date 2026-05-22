`timescale 1ns / 1ps

module user_top_stopwatch_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input  logic       clk,
    input  logic [3:0] button,
    input  logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic       blank_hours,
    output logic       blank_minutes,
    output logic       blank_seconds
);

  logic rise_start_stop, rise_lap;
  logic actual_rise_start_stop, actual_rise_lap;
  logic counter_rst, counter_enable, lap_hold;
  logic [6:0] minutes, centiseconds;
  logic [5:0] seconds;
  logic [6:0] display_minutes;
  logic [5:0] display_seconds;
  logic [6:0] display_centiseconds;

  rising_edge_detector u_start_stop (
      .clk   (clk),
      .sig_in(~button[0]),
      .rise  (rise_start_stop)
  );

  rising_edge_detector u_lap (
      .clk   (clk),
      .sig_in(~button[1]),
      .rise  (rise_lap)
  );

  // Simultaneous presses: both ignored
  assign actual_rise_start_stop = rise_start_stop & ~rise_lap;
  assign actual_rise_lap        = rise_lap & ~rise_start_stop;

  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk         (clk),
      .rst         (counter_rst),
      .enable      (counter_enable),
      .minutes     (minutes),
      .seconds     (seconds),
      .centiseconds(centiseconds)
  );

  snapshot_mux #(
      .WIDTH(7)
  ) u_mux_minutes (
      .clk (clk),
      .hold(lap_hold),
      .d   (minutes),
      .q   (display_minutes)
  );

  snapshot_mux #(
      .WIDTH(6)
  ) u_mux_seconds (
      .clk (clk),
      .hold(lap_hold),
      .d   (seconds),
      .q   (display_seconds)
  );

  snapshot_mux #(
      .WIDTH(7)
  ) u_mux_centiseconds (
      .clk (clk),
      .hold(lap_hold),
      .d   (centiseconds),
      .q   (display_centiseconds)
  );

  stopwatch_control u_control (
      .clk            (clk),
      .rise_start_stop(actual_rise_start_stop),
      .rise_lap       (actual_rise_lap),
      .counter_rst    (counter_rst),
      .counter_enable (counter_enable),
      .lap_hold       (lap_hold)
  );

  assign led           = 10'b0;
  assign hours_disp    = display_centiseconds;
  assign minutes_disp  = display_minutes;
  assign seconds_disp  = {1'b0, display_seconds};
  assign blank_hours   = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

endmodule
