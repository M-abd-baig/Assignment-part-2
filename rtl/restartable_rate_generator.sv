/*This module drives the watch's one-second timekeeping and is re-used during time editing
, where holding a button causes repeated increments or decrements. Supporting CYCLE_COUNT =1
ensures the design remains functional when the watch is configured to tick every clock cycle,
which is useful for debugging */
`timescale 1ns / 1ps
module restartable_rate_generator #(
    parameter int CYCLE_COUNT = 2
) (
    input  logic clk,
    input  logic run,  //simply the signal that says "start counting"
    output logic tick
);

  logic tick_qualifier;
  logic running = 1'b0;

  generate
    if (CYCLE_COUNT > 1) begin : g_general
      //$clog2(CYCLE_COUNT) means "ceiling log base 2".
      localparam int CountWidth = $clog2(CYCLE_COUNT);
      //^calculates how many bits i need to store a number up to cycle count
      logic rst_count;
      logic enable_count;
      logic [CountWidth-1:0] count;
      mod_n_counter #(
          .N(CYCLE_COUNT),
          .WIDTH(CountWidth)
      ) u_count (
          .clk(clk),
          .rst(rst_count),
          .enable(enable_count),
          .count(count)
      );
      assign rst_count = !run;
      assign enable_count = run;
      assign tick_qualifier = (count == CountWidth'(CYCLE_COUNT - 1));


      //including counter instantiaion
    end else begin : g_special
      assign tick_qualifier = 1'b1;
    end
  endgenerate

  //Becomes high at the end of each cyle



  always_ff @(posedge clk) running <= run;
  assign tick = running && tick_qualifier;
endmodule


/*SOME NOTES*/
/*1- What does CYCLE_COUNT do and why do we need it?
    The reason why we need CYCLE_COUNT is because it sovles a problem.
    An FPGA clock ticks millions of times per second. But you want your watch to advance
    seconds only once per second. So you need a certain number of clock cycles before
    producing one tick. That number is CYCLE_COUNT.
    e.g. Say your clock runs at 4Hz. You want 1 tick per second, so you set CYCLE_COUNT=4*/
/*2-Why is CYCLE_COUNT a parameter?
    Because different FPGAs run at different clock speeds. If your clock runs at 50MHz, you
    would set CYCLE_COUNT= 50,000,000. If it runs at 4 Hz in a simulation, you'd set
    CYCLE_COUNT=4*/

/*3-How does instantiation using CYCLE_COUNT help acheive our purpose?
    Looking at the instantiation, it can be seen that CYCLE_COUNT is passed into
    mod_n_counter's N parameter. Now look at what mod_n_counter does with N -it counts from 0 to N-1
    then wraps. So if Cycle = 4, the counter counts 0,1,2,3 then wraps back to 0.
    So the connection is :
    - restartable_rate_generator recievs CYCLE_COUNT from whoever instantiates it
    - it passes the same value in to mod_n_counter as N
    - mod_n_counter counts up to that value
    - when count reaches CYCLE_COUNT-1, tick_qualifier goes high
    - that produces one tick*/

/*4- What does tick_qualifier do and how does it work?
    Looking at the assign statement of the tick_qualifier, this is just asking a question every single
    clock cycle: "Has count reached its maximum value yet?
    - if count = 0,1,2 the answer is no, hence tick_qualifier =0
    - if count =3 (i.e. CYCLE_COUNT-1), the answer is yes and tick_qualifer=1
    mod_n_counter doesn't directly make tick_qualifer go high-it just provides a count value. The
    assign statement is what mathces the value and raises tick_qualifier at the righ moment."*/

