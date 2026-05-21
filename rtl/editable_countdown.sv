`timescale 1ns / 1ps
module editable_countdown #(
    parameter int MAX   = 59,
    parameter int WIDTH = 6
) (
    input logic clk,
    input logic clr,
    input logic tick,
    input logic edit_mode,
    input logic inc,
    input logic dec,
    output logic [WIDTH-1:0] count,
    output logic borrow_out
);

  logic [WIDTH-1:0] current_count;
  logic [WIDTH-1:0] max_value;

  // Cast MAX to correct width
  assign max_value = MAX[WIDTH-1:0];

  // Initialize
  initial current_count = 0;

  // Count logic
  always_ff @(posedge clk) begin
    if (clr) begin
      // Clear takes priority
      current_count <= 0;
    end else if (edit_mode) begin
      // Edit mode: increment or decrement on each clock when inc/dec is high
      if (inc && !dec) begin
        if (current_count == max_value) current_count <= 0;
        else current_count <= current_count + 1;
      end else if (dec && !inc) begin
        if (current_count == 0) current_count <= max_value;
        else current_count <= current_count - 1;
      end
    end else if (tick) begin
      // Countdown mode: decrement on tick
      if (current_count == 0) current_count <= max_value;  // Wrap around
      else current_count <= current_count - 1;
    end
  end

  // Output
  assign count = current_count;

  // Borrow output (combinational)
  assign borrow_out = (current_count == 0) && tick && !edit_mode && !clr;

endmodule
