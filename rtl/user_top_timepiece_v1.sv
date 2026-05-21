`timescale 1s / 1ps


/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */
/* verilator lint_off WIDTHTRUNC */


`timescale 1ns / 1ps

module user_top_timepiece_v1 #(
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

  logic [1:0] mode_sel;
  assign mode_sel = sw[1:0];

  // Watch outputs
  logic [9:0] watch_led;
  logic [6:0] watch_hours, watch_minutes, watch_seconds;
  logic watch_blank_hours, watch_blank_minutes, watch_blank_seconds;

  // Stopwatch outputs
  logic [9:0] stopwatch_led;
  logic [6:0] stopwatch_hours, stopwatch_minutes, stopwatch_seconds;
  logic stopwatch_blank_hours, stopwatch_blank_minutes, stopwatch_blank_seconds;

  // Timer outputs
  logic [9:0] timer_led;
  logic [6:0] timer_hours, timer_minutes, timer_seconds;
  logic timer_blank_hours, timer_blank_minutes, timer_blank_seconds;

  // Watch instance
  user_top_watch_v4 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_watch (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(watch_led),
      .hours_disp(watch_hours),
      .minutes_disp(watch_minutes),
      .seconds_disp(watch_seconds),
      .blank_hours(watch_blank_hours),
      .blank_minutes(watch_blank_minutes),
      .blank_seconds(watch_blank_seconds)
  );

  // Stopwatch instance
  user_top_stopwatch_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_stopwatch (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(stopwatch_led),
      .hours_disp(stopwatch_hours),
      .minutes_disp(stopwatch_minutes),
      .seconds_disp(stopwatch_seconds),
      .blank_hours(stopwatch_blank_hours),
      .blank_minutes(stopwatch_blank_minutes),
      .blank_seconds(stopwatch_blank_seconds)
  );

  // Timer instance
  user_top_timer_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_timer (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(timer_led),
      .hours_disp(timer_hours),
      .minutes_disp(timer_minutes),
      .seconds_disp(timer_seconds),
      .blank_hours(timer_blank_hours),
      .blank_minutes(timer_blank_minutes),
      .blank_seconds(timer_blank_seconds)
  );

  // Output mux based on mode_sel
  always_comb begin
    // Default to watch
    led = watch_led;
    hours_disp = watch_hours;
    minutes_disp = watch_minutes;
    seconds_disp = watch_seconds;
    blank_hours = watch_blank_hours;
    blank_minutes = watch_blank_minutes;
    blank_seconds = watch_blank_seconds;

    // Stopwatch mode (01)
    if (mode_sel == 2'b01) begin
      led = stopwatch_led;
      hours_disp = stopwatch_hours;
      minutes_disp = stopwatch_minutes;
      seconds_disp = stopwatch_seconds;
      blank_hours = stopwatch_blank_hours;
      blank_minutes = stopwatch_blank_minutes;
      blank_seconds = stopwatch_blank_seconds;
    end

    // Timer mode (11)
    if (mode_sel == 2'b11) begin
      led = timer_led;
      hours_disp = timer_hours;
      minutes_disp = timer_minutes;
      seconds_disp = timer_seconds;
      blank_hours = timer_blank_hours;
      blank_minutes = timer_blank_minutes;
      blank_seconds = timer_blank_seconds;
    end
  end

endmodule


/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on UNDRIVEN */
/* verilator lint_on WIDTHTRUNC */
