`timescale 1ns / 1ps
module up_down_counter #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = '0

);
  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);
  logic [WIDTH-1:0] next_count;
  always_ff @(posedge clk) if (enable) count <= next_count;
  // linter warning

  always_comb begin
    next_count = count;
    if (up) begin
      if (count < Max) begin
        next_count = count + 1;
      end else begin
        next_count = '0;
      end
    end
    if (!up) begin
      if (count > 0) begin
        next_count = count - 1;
      end
      if (count == 0) begin
        next_count = Max;
      end
    end
  end
endmodule
