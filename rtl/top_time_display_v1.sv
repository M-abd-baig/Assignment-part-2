`timescale 1ns / 1ps
module top_time_display_v1 #(
    parameter int CYCLES_PER_SECOND = 50000000
) (
    input logic CLOCK_50,
    input logic [1:0] SW,
    output logic [6:0] HEX5,
    output logic [6:0] HEX4,
    output logic [6:0] HEX3,
    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);
  /*This top-level_module for the DE1-SoC board displays the time on the seven_segment displays, initialised
 to 00:00:00, with the tick rate controlled by SW[1:0]*/
  logic [4:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;
  logic tick_1hz;
  logic tick_25Hz;
  logic tick_1Khz;
  logic enable;
  logic [3:0] hour_tens;
  logic [3:0] minute_tens;
  logic [3:0] seconds_tens;
  logic [3:0] hour_ones;
  logic [3:0] minute_ones;
  logic [3:0] seconds_ones;


  hms_counter u_hms (
      .clk(CLOCK_50),
      .enable(enable),
      .hours(hours),
      .minutes(minutes),
      .seconds(seconds)
  );
  binary_to_bcd u_bcd_hours (
      .bin ({2'b0, hours}),
      .tens({hour_tens}),
      .ones(hour_ones)
  );
  binary_to_bcd u_bcd_minutes (
      .bin ({1'b0, minutes}),
      .tens(minute_tens),
      .ones(minute_ones)
  );
  binary_to_bcd u_bcd_seconds (
      .bin ({1'b0, seconds}),
      .tens(seconds_tens),
      .ones(seconds_ones)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_rg_1Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1hz)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 25)
  ) u_rg_25Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_25Hz)
  );
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 1000)
  ) u_rg_1KHz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1Khz)
  );
  always_comb begin
    case (SW)
      2'b00:   enable = tick_1hz;
      2'b01:   enable = tick_25Hz;
      2'b10:   enable = tick_1Khz;
      2'b11:   enable = 1'b1;
      default: enable = 1'b0;
    endcase
  end

  seven_segment u_HEX5 (
      .digit(hour_tens),
      .blank(1'b0),
      .segments(HEX5)
  );
  seven_segment u_HEX4 (
      .digit(hour_ones),
      .blank(1'b0),
      .segments(HEX4)
  );
  seven_segment u_HEX3 (
      .digit(minute_tens),
      .blank(1'b0),
      .segments(HEX3)
  );
  seven_segment u_HEX2 (
      .digit(minute_ones),
      .blank(1'b0),
      .segments(HEX2)
  );
  seven_segment u_HEX1 (
      .digit(seconds_tens),
      .blank(1'b0),
      .segments(HEX1)
  );
  seven_segment u_HEX0 (
      .digit(seconds_ones),
      .blank(1'b0),
      .segments(HEX0)
  );
endmodule

/* 1'b0 just means "enable is low" — the counter stops counting. It's not about the switches.

  Think about it this way — default only triggers if SW somehow has a

  value that isn't 2'b00, 2'b01, 2'b10, or 2'b11. But wait — SW is 2 bits,
  so those four cases cover every possible combination.
  The default can never actually happen!

  So default: enable = 1'b0 is really just a safety net that the linter
  wants to see. It's saying "if somehow an impossible case occurs, stop
  the counter." In practice it will never trigger.*/
