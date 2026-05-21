`timescale 1ns / 1ps
module pwm_generator #(
    parameter int PERIOD_CYCLES = 50_000_000,
    parameter int DUTY_CYCLES   = 25_000_000
) (
    input  logic clk,
    input  logic rst,
    output logic pwm_out
);
  logic [$clog2(PERIOD_CYCLES)-1:0] count;

  mod_n_counter #(
      .N(PERIOD_CYCLES),
      .WIDTH($clog2(PERIOD_CYCLES))
  ) u_pwm_generator (
      .clk(clk),
      .rst(rst),
      .enable(1'b1),
      .count(count)
  );

  // Compare with one extra bit so DUTY_CYCLES == PERIOD_CYCLES (100% duty) works.
  localparam int W = $clog2(PERIOD_CYCLES) + 1;
  localparam logic [W-1:0] DutyCount = W'(DUTY_CYCLES);
  assign pwm_out = ({1'b0, count} < DutyCount);
endmodule
