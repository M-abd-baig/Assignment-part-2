`timescale 1ns / 1ps

module restartable_rate_generator #(
    parameter int CYCLE_COUNT = 2
) (
    input  logic clk,
    input  logic run,
    output logic tick = 1'b0
);

  localparam int W = (CYCLE_COUNT <= 1) ? 1 : $clog2(CYCLE_COUNT);

  logic [W-1:0] counter = '0;

  generate
    if (CYCLE_COUNT <= 1) begin : g_special

      always_ff @(posedge clk) begin
        tick <= run;
      end

    end else begin : g_general

      always_ff @(posedge clk) begin

        if (!run) begin
          counter <= '0;
          tick    <= 1'b0;

        end else if (counter == W'(CYCLE_COUNT - 2)) begin
          counter <= counter + 1'b1;
          tick    <= 1'b1;

        end else if (counter == W'(CYCLE_COUNT - 1)) begin
          counter <= '0;
          tick    <= 1'b0;

        end else begin
          counter <= counter + 1'b1;
          tick    <= 1'b0;

        end
      end
    end
  endgenerate

endmodule
