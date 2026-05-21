
`timescale 1ns / 1ps

module user_top_watch_v4 #(
    //core Functionality
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    /* verilator lint_off UNUSED */
    input logic [3:0] button,
    input logic [9:0] sw,
    /* verilator lint_on UNUSED */
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

  //   restartable_rate_generator #(
  //       .CYCLE_COUNT(CYCLES_PER_SECOND)
  //   ) u_divider_1_Hz_seconds (
  //       .clk (clk),
  //       .run (1'b1),
  //       .tick(seconds_tick)
  //   );


  //   assign seconds_dec = 1'b0;
  //   assign seconds_inc = 1'b0;



  //   assign minutes_dec = 1'b0;
  //   assign minutes_inc = 1'b0;



  //   assign hours_dec = 1'b0;
  //   assign hours_inc = 1'b0;

  assign minutes_tick = seconds_tick && (seconds == 6'd59);
  assign hours_tick = minutes_tick && (minutes == 6'd59);
  assign hours_disp = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};
  // Unused
  assign led = 10'b0;


  //-------------
  // Mode Selection
  //-------------
  logic [2:0] mode_enable;
  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)  // Fill in, based on CYCLES_PER_SECOND
  ) u_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );

  logic rst;
  assign rst = 1'b0;
  logic pwm_out;
  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  (CYCLES_PER_SECOND / 10)
  ) u_pwm_generator (
      .clk(clk),
      .rst(rst),
      .pwm_out(pwm_out)
  );

  assign seconds_edit = mode_enable[0];
  assign minutes_edit = mode_enable[1];
  assign hours_edit = mode_enable[2];
  assign blank_seconds = mode_enable[0] && pwm_out;
  assign blank_minutes = mode_enable[1] && pwm_out;
  assign blank_hours = mode_enable[2] && pwm_out;


  logic pulse;
  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_button_auto_repeat_inc (
      .clk(clk),
      .button(button[1]),
      .pulse(pulse)

  );
  assign seconds_inc = pulse && mode_enable[0];
  assign minutes_inc = pulse && mode_enable[1];
  assign hours_inc   = pulse && mode_enable[2];



  logic dec_pulse;
  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_button_auto_repeat_dec (
      .clk(clk),
      .button(button[0]),
      .pulse(dec_pulse)

  );
  assign seconds_dec = dec_pulse && mode_enable[0];
  assign minutes_dec = dec_pulse && mode_enable[1];
  assign hours_dec   = dec_pulse && mode_enable[2];

  logic run;
  assign run = !mode_enable[0];

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_restartable_rate_generator_2 (
      .clk (clk),
      .run (run),
      .tick(seconds_tick)
  );





endmodule
