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
  localparam int RealCycleCount = CYCLES_PER_SECOND / 100;
  //logic run;
  logic tick;
  //assign run = !rst && enable;
  cascade_counter #(
      .N2(100),
      .N1(60),
      .N0(100),
      //output ports
      .W2(7),
      .W1(6),
      .W0(7)
  ) u_cascade_counter (
      .clk(clk),
      .rst(rst),
      .enable(tick),
      .count2(minutes),
      .count1(seconds),
      .count0(centiseconds)
  );




  restartable_rate_generator #(
      .CYCLE_COUNT(RealCycleCount)
  ) u_restartable_rate_generator (
      .clk (clk),
      .run (enable && !rst),
      .tick(tick)
  );

endmodule
