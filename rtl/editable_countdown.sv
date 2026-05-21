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

  logic up;  // For up_down_counter_rst - 1 = up, 0 = down
  logic enable;
  logic [WIDTH-1:0] up_down_count;

  // Determine direction: in edit mode, inc/dec control; else count down on tick
  assign up = edit_mode ? inc : 1'b0;  // In edit mode, inc counts up; normally count down
  assign enable = edit_mode ? (inc || dec) : tick;

  // Use up_down_counter_rst for the actual counting
  up_down_counter_rst #(
      .MAX  (MAX),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .rst(clr),
      .enable(enable),
      .up(up),
      .count(up_down_count)
  );

  // In edit mode, count follows up_down_count
  // In countdown mode, we need to invert: when tick=1, count decreases
  // But up_down_counter_rst can count down when up=0
  assign count = up_down_count;

  // Borrow output - combinational
  // Borrow is high when count is 0 and we get a tick (would decrement to MAX)
  assign borrow_out = (count == 0) && tick && !edit_mode && !clr;

endmodule
