// -----------------------------------------------------------------------------
// Module: grayscale_core
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M3)
// Description:
//   Bit-exact integer RGB888 to 8-bit luminance (Y) conversion:
//     Y = floor((77 * R + 150 * G + 29 * B) / 256)
//   All operands and partial products use 16-bit unsigned arithmetic with
//   no intermediate truncation prior to the right-shift by 8.
// -----------------------------------------------------------------------------

module grayscale_core (
    input  logic [7:0] pixel_r,
    input  logic [7:0] pixel_g,
    input  logic [7:0] pixel_b,
    output logic [7:0] y_gray
);

    logic [15:0] prod_r;
    logic [15:0] prod_g;
    logic [15:0] prod_b;
    logic [15:0] sum_rgb;

    always_comb begin
        prod_r  = 16'd77  * {8'd0, pixel_r};
        prod_g  = 16'd150 * {8'd0, pixel_g};
        prod_b  = 16'd29  * {8'd0, pixel_b};
        sum_rgb = prod_r + prod_g + prod_b;
        y_gray  = 8'(sum_rgb >> 8);
    end

endmodule

