`timescale 1ns / 1ps

/* verilator lint_off UNUSEDSIGNAL */

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

  logic running;
  logic [2:0] mode_enable;
  logic start_press;
  logic tick_1hz;
  logic inc_pulse;
  logic dec_pulse;
  logic sec_borrow;
  logic min_borrow;
  logic [5:0] seconds;
  logic [5:0] minutes;
  logic [6:0] hours;
  logic all_zeros;

`ifdef FORMAL
  always @(*) begin
    assume (seconds <= 59);
    assume (minutes <= 59);
    assume (hours <= 23);
  end
`endif

  rising_edge_detector u_start_detector (
      .clk(clk),
      .sig_in(~button[0]),
      .rise(start_press)
  );

  edit_mode_selector u_edit_mode (
      .clk(clk),
      .button(~button[3]),
      .mode_enable(mode_enable)
  );

  button_auto_repeat u_inc_repeat (
      .clk(clk),
      .button(~button[1]),
      .pulse(inc_pulse)
  );

  button_auto_repeat u_dec_repeat (
      .clk(clk),
      .button(~button[0]),
      .pulse(dec_pulse)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick (
      .clk (clk),
      .run (running && !all_zeros),
      .tick(tick_1hz)
  );

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .clr(1'b0),
      .tick(tick_1hz),
      .edit_mode(mode_enable[0]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(seconds),
      .borrow_out(sec_borrow)
  );

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .clr(1'b0),
      .tick(sec_borrow),
      .edit_mode(mode_enable[1]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(minutes),
      .borrow_out(min_borrow)
  );

  editable_countdown #(
      .MAX  (23),
      .WIDTH(7)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(min_borrow),
      .edit_mode(mode_enable[2]),
      .inc(inc_pulse),
      .dec(dec_pulse),
      .count(hours),
      .borrow_out()
  );

  assign all_zeros = (hours == 0) && (minutes == 0) && (seconds == 0);

  initial running = 1'b0;

  always_ff @(posedge clk) begin
    if (mode_enable != 3'b000) begin
      running <= 1'b0;
    end else if (all_zeros) begin
      running <= 1'b0;
    end else if (start_press) begin
      running <= ~running;
    end
  end

  assign led           = 10'b0;
  assign hours_disp    = hours;
  assign minutes_disp  = {1'b0, minutes};
  assign seconds_disp  = {1'b0, seconds};
  assign blank_hours   = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

`ifdef FORMAL
  assign probe_running     = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
