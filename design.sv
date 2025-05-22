// Code your design here

// Approx Half Adder (Approx-1: XOR -> OR)
module approx_half_adder(input a, b, output sum, carry);
  assign sum = a | b;
  assign carry = a & b;
endmodule

// Highly Approx Full Adder (Approx-4: Sum: A, Carry: B)
module approx_full_adder(input a, b, cin, output sum, cout);
  assign sum = a;
  assign cout = b;
endmodule

// Approximate 4:2 Compressor
module approx_compressor(input a, b, c, d, output sum, carry);
  assign sum = (a | b) ^ (c | d);
  assign carry = (a | b) & (c | d);
endmodule


module approx_multiplier(input [3:0] A,B, output [7:0] result);
  // 4x4 Partial Product Matrix
  wire [3:0][3:0] pp;	// pp[r][c] = a[c] & b[r]
  genvar i,j;
  generate
    for (i = 0; i < 4; i++) begin: gen_row
      for (j = 0; j < 4; j++) begin: gen_col
        assign pp[i][j] = A[j] & B[i];
      end
    end
  endgenerate
  
  // Intermediate
//   wire p10, g10, p20, g20, p30, g30, p21, g21, p31, g31, p32, g32;
  wire [5:0] p, g;

  approx_half_adder ha_pg1 (pp[0][1], pp[1][0], p[0], g[0]);
  approx_half_adder ha_pg2 (pp[0][2], pp[2][0], p[1], g[1]);
  approx_half_adder ha_pg3 (pp[0][3], pp[3][0], p[2], g[2]);
  approx_half_adder ha_pg4 (pp[1][2], pp[2][1], p[3], g[3]);
  approx_half_adder ha_pg5 (pp[1][3], pp[3][1], p[4], g[4]);
  approx_half_adder ha_pg6 (pp[2][3], pp[3][2], p[5], g[5]);
  
  // LSB
  assign result[0] = pp[0][0];
  
  // Stage 1: First level of reduction
  wire ha1_carry;
  approx_half_adder ha1 (.a(p[0]), .b(g[0]), .sum(result[1]), .carry(ha1_carry));

  wire comp1_sum, comp1_carry, comp2_sum, comp2_carry, comp3_sum, comp3_carry;

  approx_compressor comp1 (.a(p[1]), .b(pp[1][1]), .c(g[1]), .d(ha1_carry), .sum(comp1_sum), .carry(comp1_carry));
  approx_compressor comp2 (.a(p[2]), .b(p[3]), .c(g[3]), .d(g[2]), .sum(comp2_sum), .carry(comp2_carry));
  approx_compressor comp3 (.a(p[4]), .b(pp[2][2]), .c(g[4]), .d(1'b0), .sum(comp3_sum), .carry(comp3_carry));

  // 2. Approximate Additions
  wire ha2_carry, fa1_carry, fa2_carry, fa3_carry;
  approx_half_adder ha2 (.a(comp1_sum), .b(comp1_carry), .sum(result[2]), .carry(ha2_carry));
  approx_full_adder fa1 (.a(comp2_sum), .b(comp2_carry), .cin(ha2_carry), .sum(result[3]), .cout(fa1_carry));
  approx_full_adder fa2 (.a(comp3_sum), .b(comp3_carry), .cin(fa1_carry), .sum(result[4]), .cout(fa2_carry));
  approx_full_adder fa3 (.a(p[5]), .b(g[5]), .cin(fa2_carry), .sum(result[5]), .cout(fa3_carry));
  
  // Final stage
  approx_half_adder ha3 (.a(pp[3][3]), .b(fa3_carry), .sum(result[6]), .carry(result[7]));
endmodule
