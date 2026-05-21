`timescale 1s / 1ps
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

  typedef struct packed {
    logic [3:0] button;
    logic [9:0] sw;
  } ui_in_t;

  typedef struct packed {
    logic [9:0] led;
    logic [6:0] hours_disp;
    logic [6:0] minutes_disp;
    logic [6:0] seconds_disp;
    logic blank_hours;
    logic blank_minutes;
    logic blank_seconds;
  } ui_out_t;

  ui_in_t watch_in, timer_in, stopwatch_in;
  ui_out_t watch_out, timer_out, stopwatch_out;

  logic [1:0] mode_sel;
  assign mode_sel = sw[1:0];

  // Watch instance
  user_top_watch_v4 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_watch (
      .clk(clk),
      .button(watch_in.button),
      .sw(watch_in.sw),
      .led(watch_out.led),
      .hours_disp(watch_out.hours_disp),
      .minutes_disp(watch_out.minutes_disp),
      .seconds_disp(watch_out.seconds_disp),
      .blank_hours(watch_out.blank_hours),
      .blank_minutes(watch_out.blank_minutes),
      .blank_seconds(watch_out.blank_seconds)
  );

  // Timer instance
  user_top_timer_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_timer (
      .clk(clk),
      .button(timer_in.button),
      .sw(timer_in.sw),
      .led(timer_out.led),
      .hours_disp(timer_out.hours_disp),
      .minutes_disp(timer_out.minutes_disp),
      .seconds_disp(timer_out.seconds_disp),
      .blank_hours(timer_out.blank_hours),
      .blank_minutes(timer_out.blank_minutes),
      .blank_seconds(timer_out.blank_seconds)
  );

  // Stopwatch instance
  user_top_stopwatch_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_stopwatch (
      .clk(clk),
      .button(stopwatch_in.button),
      .sw(stopwatch_in.sw),
      .led(stopwatch_out.led),
      .hours_disp(stopwatch_out.hours_disp),
      .minutes_disp(stopwatch_out.minutes_disp),
      .seconds_disp(stopwatch_out.seconds_disp),
      .blank_hours(stopwatch_out.blank_hours),
      .blank_minutes(stopwatch_out.blank_minutes),
      .blank_seconds(stopwatch_out.blank_seconds)
  );

  // Connect inputs: buttons go to selected app only, switches go to all
  assign watch_in.sw = sw;
  assign timer_in.sw = sw;
  assign stopwatch_in.sw = sw;

  always_comb begin
    // Default: buttons to watch
    watch_in.button = button;
    timer_in.button = 4'b0;
    stopwatch_in.button = 4'b0;

    case (mode_sel)
      2'b01: begin  // Stopwatch
        watch_in.button = 4'b0;
        timer_in.button = 4'b0;
        stopwatch_in.button = button;
      end
      2'b11: begin  // Timer
        watch_in.button = 4'b0;
        timer_in.button = button;
        stopwatch_in.button = 4'b0;
      end
      default: begin  // Watch (00 or 10)
        watch_in.button = button;
        timer_in.button = 4'b0;
        stopwatch_in.button = 4'b0;
      end
    endcase
  end

  // Output mux - select which app drives the display
  always_comb begin
    case (mode_sel)
      2'b01: begin  // Stopwatch
        led = stopwatch_out.led;
        hours_disp = stopwatch_out.hours_disp;
        minutes_disp = stopwatch_out.minutes_disp;
        seconds_disp = stopwatch_out.seconds_disp;
        blank_hours = stopwatch_out.blank_hours;
        blank_minutes = stopwatch_out.blank_minutes;
        blank_seconds = stopwatch_out.blank_seconds;
      end
      2'b11: begin  // Timer
        led = timer_out.led;
        hours_disp = timer_out.hours_disp;
        minutes_disp = timer_out.minutes_disp;
        seconds_disp = timer_out.seconds_disp;
        blank_hours = timer_out.blank_hours;
        blank_minutes = timer_out.blank_minutes;
        blank_seconds = timer_out.blank_seconds;
      end
      default: begin  // Watch
        led = watch_out.led;
        hours_disp = watch_out.hours_disp;
        minutes_disp = watch_out.minutes_disp;
        seconds_disp = watch_out.seconds_disp;
        blank_hours = watch_out.blank_hours;
        blank_minutes = watch_out.blank_minutes;
        blank_seconds = watch_out.blank_seconds;
      end
    endcase
  end

endmodule
