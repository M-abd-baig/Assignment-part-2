`timescale 1ns / 1ps

module stopwatch_control (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst,
    output logic counter_enable,
    output logic lap_hold
);

  // State encoding as per spec
  typedef enum logic [1:0] {
    STOPPED_LIVE   = 2'b00,
    RUNNING_LIVE   = 2'b01,
    RUNNING_FROZEN = 2'b10,  // Note: order matters for assertions
    STOPPED_FROZEN = 2'b11
  } state_t;

  state_t state, next_state;

  // Initialize to STOPPED_LIVE
  initial begin
    state = STOPPED_LIVE;
    counter_rst = 1'b0;
    counter_enable = 1'b0;
    lap_hold = 1'b0;
  end

  // State register
  always_ff @(posedge clk) begin
    state <= next_state;
  end

  // Next state and output logic combined
  always_ff @(posedge clk) begin
    // Default outputs
    counter_rst <= 1'b0;
    counter_enable <= 1'b0;
    lap_hold <= 1'b0;

    case (state)
      STOPPED_LIVE: begin
        if (rise_start_stop) begin
          next_state <= RUNNING_LIVE;
          counter_enable <= 1'b1;
        end else if (rise_lap) begin
          next_state <= STOPPED_FROZEN;
          counter_rst <= 1'b1;  // Reset when lap pressed while stopped with live display
          lap_hold <= 1'b1;
        end else begin
          next_state <= STOPPED_LIVE;
        end
      end

      RUNNING_LIVE: begin
        if (rise_start_stop) begin
          next_state <= STOPPED_LIVE;
        end else if (rise_lap) begin
          next_state <= RUNNING_FROZEN;
          lap_hold   <= 1'b1;
        end else begin
          next_state <= RUNNING_LIVE;
          counter_enable <= 1'b1;
        end
      end

      RUNNING_FROZEN: begin
        if (rise_start_stop) begin
          next_state <= STOPPED_FROZEN;
          lap_hold   <= 1'b1;
        end else if (rise_lap) begin
          next_state <= RUNNING_LIVE;
        end else begin
          next_state <= RUNNING_FROZEN;
          counter_enable <= 1'b1;
          lap_hold <= 1'b1;
        end
      end

      STOPPED_FROZEN: begin
        if (rise_start_stop) begin
          next_state <= RUNNING_FROZEN;
          counter_enable <= 1'b1;
          lap_hold <= 1'b1;
        end else if (rise_lap) begin
          next_state <= STOPPED_LIVE;
        end else begin
          next_state <= STOPPED_FROZEN;
          lap_hold   <= 1'b1;
        end
      end
    endcase
  end

endmodule
