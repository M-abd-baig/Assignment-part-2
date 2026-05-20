`timescale 1ns / 1ps

module cascade_counter #(
    parameter int N2 = 3,
    parameter int N1 = 4,
    parameter int N0 = 5,

    //output port widths
    parameter int W2 = 2,
    parameter int W1 = 2,
    parameter int W0 = 3
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [W2-1:0] count2,
    output logic [W1-1:0] count1,
    output logic [W0-1:0] count0
);
  logic enable_count0;
  logic enable_count1;
  logic enable_count2;
  localparam logic [W0-1:0] MaxC0 = W0'(N0 - 1);
  localparam logic [W1-1:0] MaxC1 = W1'(N1 - 1);
  //localparam logic [W2-1:0] MaxC2 = W2'(N2 - 1);



  assign enable_count0 = enable;
  mod_n_counter #(
      .N(N0),
      .WIDTH(W0)
  ) u_mod_n_counter_C0 (
      .clk(clk),
      .rst(rst),
      .enable(enable_count0),
      .count(count0)

  );

  assign enable_count1 = enable && ((count0) == MaxC0);
  mod_n_counter #(
      .N(N1),
      .WIDTH(W1)
  ) u_mod_n_counter_C1 (
      .clk(clk),
      .rst(rst),
      .enable(enable_count1),
      .count(count1)

  );

  assign enable_count2 = enable && ((count1) == MaxC1) && ((count0) == MaxC0);
  mod_n_counter #(
      .N(N2),
      .WIDTH(W2)
  ) u_mod_n_counter_C2 (
      .clk(clk),
      .rst(rst),
      .enable(enable_count2),
      .count(count2)
  );





endmodule
