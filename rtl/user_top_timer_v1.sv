`timescale 1ns / 1ps
module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic probe_running,
    output logic [2:0] probe_mode_enable,
`endif
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

  // Timer values (hours: 0-99, minutes: 0-59, seconds: 0-59)
  logic [6:0] hours, minutes, seconds;
  logic [6:0] display_hours, display_minutes, display_seconds;

  // Control signals
  logic running;
  logic one_second_tick;
  logic edit_mode;
  logic inc, dec;
  logic long_press;
  logic auto_inc, auto_dec;
  logic mode_enable;

  // Rate generator for 1 second ticks
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick_gen (
      .clk (clk),
      .run (running),
      .tick(one_second_tick)
  );

  // Auto-repeat for button holds (only in edit mode)
  button_auto_repeat u_auto_inc (
      .clk(clk),
      .in (edit_mode && inc),
      .out(auto_inc)
  );

  button_auto_repeat u_auto_dec (
      .clk(clk),
      .in (edit_mode && dec),
      .out(auto_dec)
  );

  // Edit mode selector (same as Assignment 1)
  edit_mode_selector u_mode (
      .clk(clk),
      .hold(~button[3]),  // Active low button
      .enable(mode_enable)
  );

  // Hours counter
  editable_countdown #(
      .MAX  (99),
      .WIDTH(7)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(one_second_tick && (mode_enable == 3'b100)),
      .edit_mode(mode_enable[2]),
      .inc(auto_inc && (mode_enable[2])),
      .dec(auto_dec && (mode_enable[2])),
      .count(hours),
      .borrow_out()
  );

  // Minutes counter
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .clr(1'b0),
      .tick(one_second_tick && (mode_enable == 3'b010) && (hours != 0 || minutes != 0 || seconds != 0)),
      .edit_mode(mode_enable[1]),
      .inc(auto_inc && (mode_enable[1])),
      .dec(auto_dec && (mode_enable[1])),
      .count(minutes[5:0]),
      .borrow_out()
  );

  // Seconds counter
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .clr(1'b0),
      .tick(one_second_tick && (mode_enable == 3'b001) && (hours != 0 || minutes != 0 || seconds != 0)),
      .edit_mode(mode_enable[0]),
      .inc(auto_inc && (mode_enable[0])),
      .dec(auto_dec && (mode_enable[0])),
      .count(seconds[5:0]),
      .borrow_out()
  );

  // Button inputs
  assign inc = ~button[1];  // Increment
  assign dec = ~button[0];  // Decrement
  assign long_press = ~button[3];  // Long press for set mode

  // Running control
  always_ff @(posedge clk) begin
    if (~button[0] && ~running && (hours != 0 || minutes != 0 || seconds != 0) && (mode_enable == 3'b000))
      running <= 1'b1;
    else if (~button[0] && running && (mode_enable == 3'b000)) running <= 1'b0;
    else if (hours == 0 && minutes == 0 && seconds == 0) running <= 1'b0;
  end

  // Mode enable logic
  assign mode_enable = (long_press && ~running) ? 3'b001 : 3'b000;  // Simplified

  // Display mux
  assign display_hours = hours;
  assign display_minutes = minutes;
  assign display_seconds = seconds;

  // Outputs
  assign led = 10'b0;
  assign hours_disp = display_hours;
  assign minutes_disp = display_minutes;
  assign seconds_disp = display_seconds;
  assign blank_hours = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
