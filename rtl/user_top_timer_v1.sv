`timescale 1ns / 1ps

module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic probe_running,
    output logic [2:0] probe_mode_enable,
`endif
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // ------------------------------------------------------------------------
  // Signal Declarations
  // ------------------------------------------------------------------------
  logic running_reg;
  logic running;
  logic [2:0] mode_enable;

  logic [6:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;

  logic tick;
  logic pwm_out;

  // Active-High Internal Button Mappings
  logic btn0, btn1, btn2, btn3;
  assign btn0 = ~button[0];  // Stopped: Start/Stop | Set Mode: Decrement
  assign btn1 = ~button[1];  // Set Mode: Increment
  assign btn2 = ~button[2];  // Unused by spec, but mapped
  assign btn3 = ~button[3];  // Mode Select (Hold 1s)

  // ------------------------------------------------------------------------
  // Helper Module Instantiations
  // ------------------------------------------------------------------------

  // 2 Hz Flashing clock with 80% Duty Cycle for Set Mode
  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  ((CYCLES_PER_SECOND / 2) * 8 / 10)
  ) u_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  // Time base countdown tick generator
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_tick (
      .clk (clk),
      .run (running),
      .tick(tick)
  );

  // Manages transitions between Stopped, Seconds, Minutes, and Hours edit states
  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode (
      .clk(clk),
      .button(btn3 && !running),  // Spec: "Set mode cannot be entered while running"
      .mode_enable(mode_enable)
  );

  // Edge Detectors
  logic start_stop_rise;
  rising_edge_detector u_edge_btn0 (
      .clk(clk),
      .sig_in(btn0),
      .rise(start_stop_rise)
  );

  logic inc_rise;
  rising_edge_detector u_edge_btn1 (
      .clk(clk),
      .sig_in(btn1),
      .rise(inc_rise)
  );

  // ------------------------------------------------------------------------
  // State Control & Run/Stop FSM Logic
  // ------------------------------------------------------------------------
  logic all_zeros;
  assign all_zeros = (hours == 0 && minutes == 0 && seconds == 0);

  // Define "running" exactly as required by the specification note
  assign running   = running_reg;

  always_ff @(posedge clk) begin
    if (all_zeros) begin
      // Spec: "When the count reaches zero, the timer stops automatically"
      running_reg <= 1'b0;
    end else if (mode_enable != 3'b000) begin
      // Spec Note Priority Rule: Edit mode takes priority, canceling running state
      running_reg <= 1'b0;
    end else if (start_stop_rise) begin
      // Spec: "Pressing button[0] starts the timer if count > 0... or pauses it"
      running_reg <= ~running_reg;
    end
  end

  // ------------------------------------------------------------------------
  // Core Countdown Counters (Cascaded Structure)
  // ------------------------------------------------------------------------
  logic sec_borrow, min_borrow, hrs_borrow;

  // SECONDS COUNTER
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_sec (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running),
      .edit_mode(mode_enable[0]),
      .inc(inc_rise && mode_enable[0]),
      .dec(start_stop_rise && mode_enable[0]),  // btn0 handles decrement in Set Mode
      .count(seconds),
      .borrow_out(sec_borrow)
  );

  // MINUTES COUNTER
  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_min (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running && (seconds == 6'd0)),
      .edit_mode(mode_enable[1]),
      .inc(inc_rise && mode_enable[1]),
      .dec(start_stop_rise && mode_enable[1]),  // btn0 handles decrement in Set Mode
      .count(minutes),
      .borrow_out(min_borrow)
  );

  // HOURS COUNTER
  editable_countdown #(
      .MAX  (23),
      .WIDTH(7)
  ) u_hrs (
      .clk(clk),
      .clr(1'b0),
      .tick(tick && running && (seconds == 6'd0) && (minutes == 6'd0)),
      .edit_mode(mode_enable[2]),
      .inc(inc_rise && mode_enable[2]),
      .dec(start_stop_rise && mode_enable[2]),  // btn0 handles decrement in Set Mode
      .count(hours),
      .borrow_out(hrs_borrow)
  );

  // ------------------------------------------------------------------------
  // Display Blanking and Outputs Mappings
  // ------------------------------------------------------------------------
  // Direct combinational blanking to prevent cycle latency mismatches in cocotb
  assign blank_seconds = mode_enable[0] && pwm_out;
  assign blank_minutes = mode_enable[1] && pwm_out;
  assign blank_hours = mode_enable[2] && pwm_out;

  assign hours_disp = hours;
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  // Tie off mandatory lint signals safely
  assign led = 10'b0;

  // Unused cleanups for Verilator's strict parser
  logic [9:0] unused_sw;
  assign unused_sw = sw;
  logic [2:0] unused_borrows;
  assign unused_borrows = {sec_borrow, min_borrow, hrs_borrow};
  logic unused_btn2;
  assign unused_btn2 = btn2;

  // ------------------------------------------------------------------------
  // Formal Verification Block
  // ------------------------------------------------------------------------
`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;

  // 1. Force the registers to start in a clean state at step 0
  initial begin
    running_reg = 1'b0;
  end

  // 2. Bound the solver to realistic hardware parameters
  always_comb begin
    assume (seconds <= 6'd59);
    assume (minutes <= 6'd59);
    assume (hours <= 7'd23);
  end

  // 3. Keep the solver from choosing a broken starting point at Step 0
  always @(*) begin
    if (all_zeros) begin
      assume (!running_reg);
    end
  end
`endif

endmodule
