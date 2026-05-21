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

  // Grey code to duty cycle mapping
  logic [1:0] brightness;
  logic [31:0] duty_cycle;

  assign brightness = {sw[9], sw[8]};

  always_comb begin
    case (brightness)
      2'b00:   duty_cycle = 32'd125000;  // 12.5%
      2'b01:   duty_cycle = 32'd250000;  // 25%
      2'b11:   duty_cycle = 32'd500000;  // 50%
      2'b10:   duty_cycle = 32'd1000000;  // 100%
      default: duty_cycle = 32'd1000000;
    endcase
  end

  // PWM generator
  pwm_generator #(
      .COUNTER_MAX(50000)
  ) u_pwm (
      .clk(clk),
      .duty_cycle(duty_cycle),
      .pwm(pwm_signal)
  );

  // Timepiece instance
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

  // Intercept blanking with PWM
  assign blank_hours = inner_blank_hours ? 1'b1 : ~pwm_signal;
  assign blank_minutes = inner_blank_minutes ? 1'b1 : ~pwm_signal;
  assign blank_seconds = inner_blank_seconds ? 1'b1 : ~pwm_signal;

  assign hours_disp = inner_hours_disp;
  assign minutes_disp = inner_minutes_disp;
  assign seconds_disp = inner_seconds_disp;

endmodule
