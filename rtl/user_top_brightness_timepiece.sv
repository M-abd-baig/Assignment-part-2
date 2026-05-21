`timescale 1ns / 1ps
module user_top_brightness_timepiece #(
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

  logic [6:0] inner_hours_disp, inner_minutes_disp, inner_seconds_disp;
  logic inner_blank_hours, inner_blank_minutes, inner_blank_seconds;
  logic pwm_signal;

  // PWM counter using mod_n_counter (1ms period = 50,000 cycles at 50MHz)
  logic [15:0] pwm_count;
  logic [15:0] duty_cycle;
  logic [1:0] brightness;

  assign brightness = {sw[9], sw[8]};

  // Duty cycle based on brightness (Grey code)
  always_comb begin
    case (brightness)
      2'b00:   duty_cycle = 16'd6250;  // 12.5% of 50000
      2'b01:   duty_cycle = 16'd12500;  // 25% of 50000
      2'b11:   duty_cycle = 16'd25000;  // 50% of 50000
      2'b10:   duty_cycle = 16'd50000;  // 100% of 50000
      default: duty_cycle = 16'd50000;
    endcase
  end

  // PWM period counter
  mod_n_counter #(
      .N(50000),
      .WIDTH(16)
  ) u_pwm_counter (
      .clk(clk),
      .rst(1'b0),
      .enable(1'b1),
      .count(pwm_count)
  );

  // PWM output - compare counter with duty cycle
  assign pwm_signal = (pwm_count < duty_cycle);

  // Timepiece instance (replaced user_top with user_top_timepiece_v1)
  user_top_timepiece_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_timepiece (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(led),
      .hours_disp(inner_hours_disp),
      .minutes_disp(inner_minutes_disp),
      .seconds_disp(inner_seconds_disp),
      .blank_hours(inner_blank_hours),
      .blank_minutes(inner_blank_minutes),
      .blank_seconds(inner_blank_seconds)
  );

  // Intercept blanking signals with PWM
  assign blank_hours = inner_blank_hours ? 1'b1 : ~pwm_signal;
  assign blank_minutes = inner_blank_minutes ? 1'b1 : ~pwm_signal;
  assign blank_seconds = inner_blank_seconds ? 1'b1 : ~pwm_signal;

  // Pass through display values unchanged
  assign hours_disp = inner_hours_disp;
  assign minutes_disp = inner_minutes_disp;
  assign seconds_disp = inner_seconds_disp;

endmodule

