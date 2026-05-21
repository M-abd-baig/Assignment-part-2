`timescale 1ns / 1ps
module stopwatch_control (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst,
    output logic counter_enable,
    output logic lap_hold
);

  logic running;
  logic frozen;

  // Initialize all outputs to 0
  initial begin
    running = 1'b0;
    frozen = 1'b0;
    counter_rst = 1'b0;
    counter_enable = 1'b0;
    lap_hold = 1'b0;
  end

  // Running toggles on start/stop (only on rising edge, ignoring simultaneous)
  always_ff @(posedge clk) begin
    if (rise_start_stop && !rise_lap) begin
      running <= ~running;
    end
  end

  // Frozen behavior:
  // - Toggles on lap when running
  // - Resets to 0 when stopped
  always_ff @(posedge clk) begin
    if (!running) begin
      frozen <= 1'b0;
    end else if (rise_lap && !rise_start_stop && running) begin
      frozen <= ~frozen;
    end
  end

  // Reset pulse - exactly one cycle when:
  // - Stopped (not running) AND
  // - Not frozen AND
  // - Lap pressed (and not start_stop simultaneously)
  always_ff @(posedge clk) begin
    counter_rst <= (!running && !frozen && rise_lap && !rise_start_stop);
  end

  // Output assignments
  always_comb begin
    counter_enable = running;
    lap_hold = frozen;
  end

endmodule
