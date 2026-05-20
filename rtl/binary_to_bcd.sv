`timescale 1ns / 1ps
module binary_to_bcd (
    input  logic [6:0] bin,
    output logic [3:0] tens,
    output logic [3:0] ones
);
  /* For any input value bin in the range 0 to 99, the output "tens" represents the decimal
tens digits of bin, and the output "ones" represents the decimal digit ones*/
  /*only need 7 bits becaue we are counting from 0 to 99*/

  assign tens = 4'(bin / 7'd10);  // register 10 as a 4 bit number and then divide the input by 10
                                  //to set its value

  assign ones = 4'(bin % 7'd10);  // same idea as before but use remainder operator instead.
endmodule
