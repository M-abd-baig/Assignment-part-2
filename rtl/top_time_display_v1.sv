
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

  // Internal signals
  logic running;
  logic [2:0] mode_enable;
  logic [6:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;
  logic one_sec_tick;
  logic pwm_2hz;
  logic rise_start, rise_lap;
  logic inc_pulse, dec_pulse;
  logic sec_borrow, min_borrow;
  logic start_prev, lap_prev;

  // Rising edge detectors for start and lap (active low)
  always_ff @(posedge clk) begin
    start_prev <= button[0];
    lap_prev   <= button[1];
  end
  assign rise_start = ~button[0] & ~start_prev;
  assign rise_lap   = ~button[1] & ~lap_prev;

  // PWM generator for 2Hz flashing (80% duty cycle)
  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  ((CYCLES_PER_SECOND / 2) * 8 / 10)
  ) u_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_2hz)
  );

  // 1Hz tick generator
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick_gen (
      .clk (clk),
      .run (running),
      .tick(one_sec_tick)
  );

  // Edit mode selector - PASS RAW BUTTON (active low), NOT rising edge!
  edit_mode_selector u_mode_selector (
      .clk(clk),
      .button(~button[3]),  // Raw button, active low
      .mode_enable(mode_enable)
  );

  // Auto-repeat for edit mode (uses rising edges of lap/start when in edit mode)
  button_auto_repeat u_inc_repeat (
      .clk(clk),
      .button(rise_lap && (mode_enable != 3'b000)),
      .pulse(inc_pulse)
  );

  button_auto_repeat u_dec_repeat (
      .clk(clk),
      .button(rise_start && (mode_enable != 3'b000)),
      .pulse(dec_pulse)
  );

  // All zeros detection
  logic all_zeros;
  assign all_zeros = (hours == 0 && minutes == 0 && seconds == 0);

  // Seconds counter
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .clr(1'b0),
      .tick(one_sec_tick && running && !all_zeros),
      .edit_mode(mode_enable[0]),
      .inc(inc_pulse && mode_enable[0]),
      .dec(dec_pulse && mode_enable[0]),
      .count(seconds),
      .borrow_out(sec_borrow)
  );

  // Minutes counter
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .clr(1'b0),
      .tick(sec_borrow && running && !all_zeros),
      .edit_mode(mode_enable[1]),
      .inc(inc_pulse && mode_enable[1]),
      .dec(dec_pulse && mode_enable[1]),
      .count(minutes),
      .borrow_out(min_borrow)
  );

  // Hours counter
  editable_countdown #(
      .MAX  (99),
      .WIDTH(7)
  ) u_hours (
      .clk(clk),
      .clr(1'b0),
      .tick(min_borrow && running && !all_zeros),
      .edit_mode(mode_enable[2]),
      .inc(inc_pulse && mode_enable[2]),
      .dec(dec_pulse && mode_enable[2]),
      .count(hours),
      .borrow_out()
  );

  // Running control - edit mode takes priority
  always_ff @(posedge clk) begin
    if (mode_enable != 3'b000) begin
      running <= 1'b0;
    end else if (rise_start && !all_zeros) begin
      running <= ~running;
    end else if (all_zeros) begin
      running <= 1'b0;
    end
  end

  // Blanking - flash selected digit at 2Hz
  assign blank_hours = (mode_enable[2] && pwm_2hz);
  assign blank_minutes = (mode_enable[1] && pwm_2hz);
  assign blank_seconds = (mode_enable[0] && pwm_2hz);

  // Outputs
  assign led = 10'b0;
  assign hours_disp = hours;
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
