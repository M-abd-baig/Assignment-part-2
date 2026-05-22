`timescale 1ns / 1ps

module user_top_timepiece_v1 #(
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
  logic [6:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;
  logic tick;
  logic pwm_out;
  logic btn0, btn1, btn3;

  assign btn0 = ~button[0];
  assign btn1 = ~button[1];
  assign btn3 = ~button[3];

`ifdef FORMAL
  initial begin
    running = 1'b0;
    hours = 7'd0;
    minutes = 6'd0;
    seconds = 6'd0;
    mode_enable = 3'b000;
  end
`endif

  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  ((CYCLES_PER_SECOND / 2) * 8 / 10)
  ) u_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick (
      .clk (clk),
      .run (running),
      .tick(tick)
  );

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode (
      .clk(clk),
      .button(btn3),
      .mode_enable(mode_enable)
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_inc (
      .clk(clk),
      .button(btn1 && (mode_enable != 0)),
      .pulse()
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_dec (
      .clk(clk),
      .button(btn0 && (mode_enable != 0)),
      .pulse()
  );

  logic inc_edge, dec_edge;
  logic btn1_prev, btn0_prev;
  always_ff @(posedge clk) begin
    btn1_prev <= btn1;
    btn0_prev <= btn0;
  end
  assign inc_edge = btn1 && !btn1_prev;
  assign dec_edge = btn0 && !btn0_prev;

  logic all_zeros;
  assign all_zeros = (hours == 0 && minutes == 0 && seconds == 0);

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_sec (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running && !all_zeros),
      .edit_mode(mode_enable[0]),
      .inc(inc_edge && mode_enable[0]),
      .dec(dec_edge && mode_enable[0]),
      .count(seconds),
      .borrow_out()
  );

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_min (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running && !all_zeros && seconds == 0),
      .edit_mode(mode_enable[1]),
      .inc(inc_edge && mode_enable[1]),
      .dec(dec_edge && mode_enable[1]),
      .count(minutes),
      .borrow_out()
  );

  editable_countdown #(
      .MAX  (99),
      .WIDTH(7)
  ) u_hrs (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running && !all_zeros && seconds == 0 && minutes == 0),
      .edit_mode(mode_enable[2]),
      .inc(inc_edge && mode_enable[2]),
      .dec(dec_edge && mode_enable[2]),
      .count(hours),
      .borrow_out()
  );

  logic start_rise;
  logic start_prev;
  always_ff @(posedge clk) begin
    start_prev <= btn0;
  end
  assign start_rise = btn0 && !start_prev;

  always_ff @(posedge clk) begin
    if (mode_enable != 0) begin
      running <= 1'b0;
    end else if (start_rise && !all_zeros) begin
      running <= ~running;
    end else if (all_zeros) begin
      running <= 1'b0;
    end
  end

  assign blank_seconds = (mode_enable[0] && pwm_out);
  assign blank_minutes = (mode_enable[1] && pwm_out);
  assign blank_hours = (mode_enable[2] && pwm_out);

  assign led = 10'b0;
  assign hours_disp = hours;
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
