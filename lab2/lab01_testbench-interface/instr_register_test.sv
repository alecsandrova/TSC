/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;

  int seed = 555;
  parameter WR_NR = 3;
  parameter RD_NR = 3;
  parameter R_O = 0; //0 - increment; 1 - decrement; 2 - random;
  parameter W_O = 0; //0 - increment; 1 - decrement; 2 - random;
  static int failed_tests_number = 0;


  instruction_t  iw_reg_test [0:31];
 


  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    // repeat (3) begin A.N. 06/03/2024
      repeat(WR_NR) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin A.N. 06/03/2024
    for (int i = 0; i < RD_NR; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk) case(R_O)
        0: read_pointer = i % 32; 
        1: read_pointer = 31 - (i % 32);
        2: read_pointer = $unsigned($random) % 32;
      endcase
      @(negedge clk) print_results;
      check_results;
      $display("Failed tests: %0d\n", failed_tests_number);
    end

    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //

    static int temp_up = 0;
    static int temp_down = 31;
    operand_a = $random(seed)%16; // between -15 and 15. 
    operand_b = $unsigned($random)%16;  // between 0 and 15
    opcode = opcode_t'($unsigned($random)%8);  // between 0 and 7
    case(W_O)
      0: write_pointer = temp_up++;
      1: write_pointer = temp_down--;
      2: write_pointer = $random($random) % 32;
    endcase
    iw_reg_test[write_pointer] <= '{opcode,operand_a,operand_b,0}; 
    $display("TEST %0d: ", write_pointer);
    $display("  opc = %0d (%s)", opcode, opcode.name);
    $display("  op_a = %0d",   operand_a);
    $display("  op_b = %0d\n", operand_b);
    $display("  time = %0d\n", $time);
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
    $display("  result = %0d\n", instruction_word.res);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.res);
  endfunction: print_results
    
  function void check_results;
    result_t res;
    case(iw_reg_test[read_pointer].opc)
        ZERO: res = 0;
        PASSA: res = iw_reg_test[read_pointer].op_a;
        PASSB: res = iw_reg_test[read_pointer].op_b;
        ADD: res = iw_reg_test[read_pointer].op_a + iw_reg_test[read_pointer].op_b;
        SUB: res = iw_reg_test[read_pointer].op_a - iw_reg_test[read_pointer].op_b;
        MULT: res = iw_reg_test[read_pointer].op_a * iw_reg_test[read_pointer].op_b;
        DIV: begin
          if (iw_reg_test[read_pointer].op_b === 0) res = 0;
          else res = iw_reg_test[read_pointer].op_a / iw_reg_test[read_pointer].op_b;
        end
        MOD: res = iw_reg_test[read_pointer].op_a % iw_reg_test[read_pointer].op_b;
        default : res = 0;
    endcase
    if(res === instruction_word.res)
      $display("TEST PASSED\n", "DUT result = %0d\n", instruction_word.res,"TEST result = %0d\n", res);
    else begin
      $display("TEST NOT PASSED \n", "DUT result = %0d\n", instruction_word.res,"TEST result = %0d\n", res);
      failed_tests_number++;
    end
  endfunction: check_results;

endmodule: instr_register_test
