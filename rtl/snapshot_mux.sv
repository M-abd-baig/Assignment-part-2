`timescale 1ns / 1ps
module snapshot_mux #(
    parameter int WIDTH = 1
) (
    input logic clk,
    input logic hold,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
  logic [WIDTH-1:0] frozen;

  // Initialize frozen to 0
  initial frozen = '0;

  // Capture d on every clock edge
  // The spec says: frozen = value d held on the last rising edge BEFORE hold went high
  // This means we continuously capture when hold is low
  always_ff @(posedge clk) begin
    if (!hold) begin
      frozen <= d;
    end
    // When hold is high, frozen keeps its last value (no update)
  end

  // Combinational output - no clock involved
  assign q = hold ? frozen : d;

endmodule
