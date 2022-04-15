/* 
 * multimode counter takes 2 bit control which determens value and up or down 
 *
 * @port input clk
 * @port input reset
 * @port input control
 * @port input init_seg
 * @port input init_val
 * @port input gameover
 * @port output count
 */
module multimode_counter#(DATA_WIDTH=4)(clk, reset, control, init_seg, init_val, gameover, count);
  /* input ports */
  input clk;
  input reset;
  input [1:0] control;
  input init_seg;
  input [DATA_WIDTH - 1:0] init_val;
  input gameover;
  
  /* output ports */
  output [DATA_WIDTH - 1:0] count;
  
  bit [DATA_WIDTH - 1:0] value;
  bit [DATA_WIDTH - 1:0] counter;
  
  assign count = counter;

  typedef enum { UP, DOWN } direction_type;
  direction_type direction;	
  
  always @(posedge clk or posedge reset or posedge init_seg) begin
    if(reset || gameover)
      counter = 0;
    else if (init_seg)
      counter = init_val;
    else begin
      /* mode selection based on control bits */
      case(control)
        2'b00: begin value = 1; direction = UP; end
        2'b01: begin value = 2; direction = UP; end
        2'b10: begin value = 1; direction = DOWN; end
        2'b11: begin value = 2; direction = DOWN; end
      endcase
      if(direction == UP)
        counter = counter + value;
      else
        counter = counter - value;
    end
  end  
endmodule

/* 
 * game module holds score board and instance of the multimode counter to run the game 
 *
 * @port input clk
 * @port input reset
 * @port input control
 * @port output count
 * @port input init_seg
 * @port output INIT
 * @port output WINNER
 * @port output LOSER
 * @port output GAMEOVER
 * @port output WHO
 */
module game#(DATA_WIDTH=4)(clk, reset, control, count, init_seg, INIT, WINNER, LOSER, GAMEOVER, WHO);
  	parameter WINS = 15;
  	parameter LOSES = 15;
  
    /* input ports */
    input clk;
    input reset;
  	input [1:0] control;
  	input init_seg;
    input [DATA_WIDTH - 1:0] INIT;
  
  	/* output ports */
    output [DATA_WIDTH - 1:0] count;
  	output WINNER;
  	output LOSER;
  	output GAMEOVER;
    output [1:0] WHO;

    wire [DATA_WIDTH - 1:0] counter;
    
  	bit winner_seg = 0;
  	bit loser_seg = 0;
  	bit gameover_seg = 0;
    bit [1:0] who_seg = 0;
  
  	/* register that holds number of winner signal reached high 
    and loser signal reached high */
  	int	winner_count = 0;
    int	loser_count = 0;
  
  	/* assign signals to output wires to match the required signal names */
    assign count = counter;
    assign WINNER = winner_seg;
    assign LOSER = loser_seg;
  	assign GAMEOVER = gameover_seg;
  	assign WHO = who_seg;
  
  	/* checking for counter value to set winner or loser if exist */
    always @(counter) begin 
      /* if count equals all 1's set winner signal high */
      if(counter == (2 ** DATA_WIDTH) - 1) begin
        winner_seg = 1;
        winner_count = winner_count + 1;
      end
      /* if count equals all 0's set loser signal high */
      else if(counter == 0 && reset != 1) begin
        loser_seg = 1;
        loser_count = loser_count + 1;
      end
      /* number of winner signal high or number of loser signal high to 
      determine who finished the game */
      if(winner_count == WINS || loser_count == LOSES) begin
        gameover_seg = 1;
        /* if winner finished the game set WHO signal = 2 */
        if(winner_count == WINS)
          who_seg = 2'b10; 
        /* if loser finished the game set WHO signal = 1 */
        else
          who_seg = 2'b01;
      end
    end
  
    /* check for clock or asynchornous reset */
  always @(posedge clk or posedge reset) begin
        /* reset loser and winner signals every clock cycles */
        loser_seg = 0;
        winner_seg = 0;
      	/* reset all values to 0 if signal reset is high or gameover is high */
        if(gameover_seg || reset) begin
          winner_seg = 0;
          loser_seg = 0;
          winner_count = 0;
          loser_count = 0;
          gameover_seg = 0;
          who_seg = 0;
        end
    end
  	/* multimode counter instance */
    multimode_counter mmc(clk, reset, control, init_seg, INIT, GAMEOVER, counter);
endmodule 

/******************************** Testbench ********************************/

module game_tb#(DATA_WIDTH=4);
  parameter CLK = 1;
  bit clk;
  bit reset;
  bit [1:0] control = 2'b00;
  bit init_seg = 0;
  bit [DATA_WIDTH - 1:0] init_val;
  
  wire [DATA_WIDTH - 1:0] count;
  wire loser;
  wire winner;
  wire gameover;
  wire [1:0] who;
  
  initial begin
    clk = 1'b0;
    forever #CLK clk = ~clk;
  end
  
  initial begin
    /* Scenario 1: Set Initial value to 0 to give loser an advantage with ctrl 0*/
    control = 2'b00;
    init_seg = 1; init_val = 0;
    #2 init_seg = 0;
    
    #500 reset = 1;
    #20 reset = 0;  
    
    /* Scenario 2: Set Initial value to 1 to give winner an advantage with ctrl 0*/
    init_seg = 1; init_val = 1;
    #2 init_seg = 0;

    #500 reset = 1;
    #20 reset = 0;
    
    control = 2'b01;
    /* Scenario 3: Set Initial value to 2 to give loser an advantage with ctrl 1*/
    init_seg = 1; init_val = 2;
    #2 init_seg = 0;
    
    #500 reset = 1;
    #20 reset = 0;
    
    /* Scenario 4: Set Initial value to 1 to give winner an advantage with ctrl 1*/
    init_seg = 1; init_val = 1;
    #2 init_seg = 0;
    
    #500 reset = 1;
    #20 reset = 0;
    
    control = 2'b10;  
    /* Scenario 5: Set Initial value to 1 to give loser an advantage with ctrl 2*/
    init_seg = 1; init_val = 1;
    #2 init_seg = 0;
    
    #500 reset = 1;
    #20 reset = 0;

    /* Scenario 6: Set Initial value to 15 to give winner an advantage with ctrl 2*/
    init_seg = 1; init_val = 15;
    #2 init_seg = 0;
    
    #500 reset = 1;
    #20 reset = 0;
    
    control = 2'b11; 
    /* Scenario 7: Set Initial value to 15 to give loser an advantage with ctrl 3*/
    init_seg = 1; init_val = 15;
    #2 init_seg = 0;

    #500 reset = 1;
    #20 reset = 0;
 
    /* Scenario 8: Set Initial value to 0 to give winner an advantage with ctrl 3*/
    init_seg = 1; init_val = 0;
    #2 init_seg = 0;

end  
  
  game dut(
    .clk (clk),
    .reset (reset),
    .control (control),
    .count (count),
    .init_seg (init_seg),
    .INIT (init_val),
    .WINNER (winner),
    .LOSER (loser),
    .GAMEOVER (gameover),
    .WHO (who)
  );
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
    #5000 $finish;
  end
endmodule