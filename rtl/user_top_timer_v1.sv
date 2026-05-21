`timescale 1ns / 1ps

/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */



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

  // Timer values
  logic [6:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;

  // Control signals
  logic running;
  logic one_second_tick;
  logic edit_mode;
  logic inc, dec;
  logic auto_inc, auto_dec;
  logic [2:0] mode_enable;
  logic long_press;

  // Rate generator
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick_gen (
      .clk (clk),
      .run (running),
      .tick(one_second_tick)
  );

  // Button inputs (active low)
  assign inc = ~button[1];
  assign dec = ~button[0];
  assign long_press = ~button[3];

  // Auto-repeat
  button_auto_repeat u_auto_inc (
      .clk(clk),
      .button(edit_mode && inc),
      .pulse(auto_inc)
  );

  button_auto_repeat u_auto_dec (
      .clk(clk),
      .button(edit_mode && dec),
      .pulse(auto_dec)
  );

  // Edit mode selector
  edit_mode_selector u_mode (
      .clk(clk),
      .button(long_press),
      .mode_enable(mode_enable)
  );

  assign edit_mode = (mode_enable != 3'b000);

  // Hours counter
  editable_countdown #(
      .MAX  (99),
      .WIDTH(7)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(one_second_tick && (mode_enable == 3'b100) && (hours != 0 || minutes != 0 || seconds != 0)),
      .edit_mode(mode_enable[2]),
      .inc(auto_inc && mode_enable[2]),
      .dec(auto_dec && mode_enable[2]),
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
      .inc(auto_inc && mode_enable[1]),
      .dec(auto_dec && mode_enable[1]),
      .count(minutes),
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
      .inc(auto_inc && mode_enable[0]),
      .dec(auto_dec && mode_enable[0]),
      .count(seconds),
      .borrow_out()
  );

  // Running control - FIXED: Cannot run when count is zero OR in edit mode
  always_ff @(posedge clk) begin
    // Start timer: button[0] pressed, not running, count > 0, NOT in edit mode
    if (~button[0] && ~running && (hours != 0 || minutes != 0 || seconds != 0) && ~edit_mode) begin
      running <= 1'b1;
    end  // Stop timer: button[0] pressed, running, NOT in edit mode
    else if (~button[0] && running && ~edit_mode) begin
      running <= 1'b0;
    end  // Auto-stop when reaches zero - immediately stop
    else if (hours == 0 && minutes == 0 && seconds == 0) begin
      running <= 1'b0;
    end  // Cannot run in edit mode
    else if (edit_mode) begin
      running <= 1'b0;
    end
  end

  // Outputs
  assign led = 10'b0;
  assign hours_disp = hours;
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};
  assign blank_hours = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule



/* verilator lint_on PINCONNECTEMPTY */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on UNDRIVEN */
