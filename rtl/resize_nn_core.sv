// -----------------------------------------------------------------------------
// Module: resize_nn_core
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M5)
// Description:
//   Combinational Nearest-Neighbor downscaling for independent axis factors
//   1 (bypass) or 2, operating on post-crop ROI dimensions (W, H).
//   For factor F = 2, output dimension is N_out = floor(N / 2) and selected
//   source indices are floor(k * N / N_out) = 2 * k for k = 0 .. N_out - 1,
//   which equals even coordinates strictly below 2 * N_out.
//   Also regenerates frame/line synchronization markers (SOF, SOL, EOL, EOF)
//   from the effective output coordinates (x_out, y_out).
// -----------------------------------------------------------------------------

module resize_nn_core (
    input  logic        in_roi,
    input  logic [10:0] u,
    input  logic [10:0] v,
    input  logic [10:0] roi_width,
    input  logic [10:0] roi_height,
    input  logic        resize_x2,
    input  logic        resize_y2,
    output logic [10:0] out_width,
    output logic [10:0] out_height,
    output logic        sel_pixel,
    output logic [10:0] x_out,
    output logic [10:0] y_out,
    output logic        out_sof,
    output logic        out_sol,
    output logic        out_eol,
    output logic        out_eof
);

    logic [11:0] limit_x_12;
    logic [11:0] limit_y_12;
    logic        sel_x;
    logic        sel_y;
    logic        is_first_x;
    logic        is_first_y;
    logic        is_last_x;
    logic        is_last_y;

    always_comb begin
        out_width  = resize_x2 ? {1'b0, roi_width[10:1]}  : roi_width;
        out_height = resize_y2 ? {1'b0, roi_height[10:1]} : roi_height;

        limit_x_12 = {out_width,  1'b0};
        limit_y_12 = {out_height, 1'b0};

        sel_x      = !resize_x2 || ((u[0] == 1'b0) && ({1'b0, u} < limit_x_12));
        sel_y      = !resize_y2 || ((v[0] == 1'b0) && ({1'b0, v} < limit_y_12));

        sel_pixel  = in_roi && sel_x && sel_y && (out_width != 11'd0) && (out_height != 11'd0);

        x_out      = sel_pixel ? (resize_x2 ? {1'b0, u[10:1]} : u) : 11'd0;
        y_out      = sel_pixel ? (resize_y2 ? {1'b0, v[10:1]} : v) : 11'd0;

        is_first_x = (x_out == 11'd0);
        is_first_y = (y_out == 11'd0);
        is_last_x  = (x_out == (out_width  - 11'd1));
        is_last_y  = (y_out == (out_height - 11'd1));

        out_sof    = sel_pixel && is_first_x && is_first_y;
        out_sol    = sel_pixel && is_first_x;
        out_eol    = sel_pixel && is_last_x;
        out_eof    = sel_pixel && is_last_x  && is_last_y;
    end

endmodule

