// -----------------------------------------------------------------------------
// Module: crop_core
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M4)
// Description:
//   Combinational Rectangular Region-of-Interest (ROI) selection and coordinate
//   remapping with configurable bypass (crop_enable = 0 uses full input frame).
//   Upper boundary comparisons use 12-bit unsigned arithmetic without overflow:
//     x_start <= x < x_start + crop_width
//     y_start <= y < y_start + crop_height
// -----------------------------------------------------------------------------

module crop_core (
    input  logic [10:0] x,
    input  logic [10:0] y,
    input  logic [10:0] in_width,
    input  logic [10:0] in_height,
    input  logic        crop_enable,
    input  logic [10:0] x_start,
    input  logic [10:0] y_start,
    input  logic [10:0] crop_width,
    input  logic [10:0] crop_height,
    output logic        in_roi,
    output logic [10:0] u,
    output logic [10:0] v,
    output logic [10:0] roi_width,
    output logic [10:0] roi_height
);

    logic [10:0] eff_x_start;
    logic [10:0] eff_y_start;
    logic [11:0] x_end_12;
    logic [11:0] y_end_12;
    logic        in_roi_x;
    logic        in_roi_y;

    always_comb begin
        eff_x_start = crop_enable ? x_start     : 11'd0;
        eff_y_start = crop_enable ? y_start     : 11'd0;
        roi_width   = crop_enable ? crop_width  : in_width;
        roi_height  = crop_enable ? crop_height : in_height;

        x_end_12    = {1'b0, eff_x_start} + {1'b0, roi_width};
        y_end_12    = {1'b0, eff_y_start} + {1'b0, roi_height};

        in_roi_x    = (x >= eff_x_start) && ({1'b0, x} < x_end_12);
        in_roi_y    = (y >= eff_y_start) && ({1'b0, y} < y_end_12);
        in_roi      = in_roi_x && in_roi_y;

        u           = in_roi ? (x - eff_x_start) : 11'd0;
        v           = in_roi ? (y - eff_y_start) : 11'd0;
    end

endmodule

