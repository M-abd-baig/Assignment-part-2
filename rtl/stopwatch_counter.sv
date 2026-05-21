`timescale 1ns / 1ps


module stopwatch_counter #(
    parameter int CYCLES_PER_SECOND = 50000000
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [6:0] minutes,
    output logic [5:0] seconds,
    output logic [6:0] centiseconds
);

  localparam int CENTI_CYCLES = CYCLES_PER_SECOND / 100;
  logic centi_tick;

  // Generate tick every centisecond
  restartable_rate_generator #(
      .CYCLE_COUNT(CENTI_CYCLES)
  ) u_centi_gen (
      .clk (clk),
      .run (enable && !rst),
      .tick(centi_tick)
  );

  // Cascade counter: centiseconds(0-99), seconds(0-59), minutes(0-99)
  cascade_counter #(
      .N2(100),  // minutes: 0-99
      .N1(60),   // seconds: 0-59  
      .N0(100),  // centiseconds: 0-99
      .W2(7),
      .W1(6),
      .W0(7)
  ) u_cascade (
      .clk(clk),
      .rst(rst),
      .enable(centi_tick),
      .count2(minutes),
      .count1(seconds),
      .count0(centiseconds)
  );

endmodule

