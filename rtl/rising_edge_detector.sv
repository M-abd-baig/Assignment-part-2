`timescale 1ns / 1ps
/*Rising edge detector is a Mealy FSM as it avoids a one cycle output delay,
  is simpler to write, and produces output logic simple enough to be glitch_free*/
module rising_edge_detector (
    input  logic clk,
    input  logic sig_in,
    output logic rise
);
  logic prev_signal;
  always_ff @(posedge clk) prev_signal <= sig_in;

  assign rise = (sig_in == 1 && prev_signal == 0);
endmodule
