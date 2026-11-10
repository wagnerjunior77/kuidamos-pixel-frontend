// -----------------------------------------------------------------------------
// Module: threshold_core
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M6)
// Description:
//   Combinational luminance thresholding with bypass:
//     - When threshold_enable == 1: pixel_thresh = (y_gray >= threshold) ? 255 : 0
//     - When threshold_enable == 0: pixel_thresh = y_gray
// -----------------------------------------------------------------------------

module threshold_core (
    input  logic [7:0] y_gray,
    input  logic       threshold_enable,
    input  logic [7:0] threshold,
    output logic [7:0] pixel_thresh
);

    always_comb begin
        if (threshold_enable) begin
            pixel_thresh = (y_gray >= threshold) ? 8'd255 : 8'd0;
        end else begin
            pixel_thresh = y_gray;
        end
    end

endmodule

