`timescale 1ns / 1ps

module key_synchroniser (
    input logic clk,
    input logic [3:0] key_n,
    output logic [3:0] key_sync = 4'b0
);
  logic [3:0] middle_man = 4'b0;



  always_ff @(posedge clk) begin
    middle_man <= ~(key_n);
    key_sync   <= middle_man;

  end


endmodule
