`timescale 1ns / 1ps

module stopwatch_counter #(
    parameter int CYCLES_PER_SECOND = 50000000
) (
    input logic clk,
    input logic rst,
    input logic enable,

    output logic [6:0] minutes = 0,
    output logic [5:0] seconds = 0,
    output logic [6:0] centiseconds = 0
);

  // -------------------------------------------------
  // Tick generator
  // -------------------------------------------------

  logic tick;

  restartable_rate_generator #(
      .CYCLE_COUNT((CYCLES_PER_SECOND / 100))
  ) rate_gen (
      .clk (clk),
      .run (enable),
      .tick(tick)
  );

  // -------------------------------------------------
  // Clean one-cycle wrap enables
  // -------------------------------------------------

  logic sec_enable;
  logic min_enable;

  assign sec_enable = tick && (centiseconds == 99);

  assign min_enable = tick && (centiseconds == 99) && (seconds == 59);

  // -------------------------------------------------
  // Centiseconds
  // -------------------------------------------------

  cascade_counter #(
      .MAX  (99),
      .WIDTH(7)
  ) cs_counter (
      .clk(clk),
      .rst(rst),
      .enable(tick),
      .count(centiseconds)
  );

  // -------------------------------------------------
  // Seconds
  // -------------------------------------------------

  cascade_counter #(
      .MAX  (59),
      .WIDTH(6)
  ) sec_counter (
      .clk(clk),
      .rst(rst),
      .enable(sec_enable),
      .count(seconds)
  );

  // -------------------------------------------------
  // Minutes
  // -------------------------------------------------

  cascade_counter #(
      .MAX  (99),
      .WIDTH(7)
  ) min_counter (
      .clk(clk),
      .rst(rst),
      .enable(min_enable),
      .count(minutes)
  );

endmodule
