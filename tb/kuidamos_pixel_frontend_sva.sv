// -----------------------------------------------------------------------------
// Module: kuidamos_pixel_frontend_sva
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestones M3–M7)
// Description:
//   SystemVerilog Assertions (SVA) monitor for kuidamos_pixel_frontend.
//   Verifies:
//     1. Synchronous reset clearing outputs and internal frame state
//     2. Zeroed data and markers whenever pixel_out_valid == 0
//     3. Output marker consistency (out_sof -> out_sol, out_eof -> out_eol)
//     4. cfg_error exclusivity and causality (only after valid in_sof)
//     5. State and coordinate freeze on input bubbles (pixel_valid == 0)
//     6. Stability of captured configuration registers (cfg_*_q) during frame
//     7. Coordinate bounds (x_q < cfg_in_width_q, y_q < cfg_in_height_q)
// -----------------------------------------------------------------------------

module kuidamos_pixel_frontend_sva (
    input logic        clk,
    input logic        reset_n,

    // Input stream
    input logic        pixel_valid,
    input logic        in_sof,
    input logic        in_sol,
    input logic        in_eol,
    input logic        in_eof,

    // Output stream
    input logic [7:0]  pixel_out,
    input logic        pixel_out_valid,
    input logic        out_sof,
    input logic        out_sol,
    input logic        out_eol,
    input logic        out_eof,
    input logic        cfg_error,

    // Internal DUT state and captured configuration registers
    input logic        frame_active_q,
    input logic [10:0] x_q,
    input logic [10:0] y_q,
    input logic [10:0] cfg_in_width_q,
    input logic [10:0] cfg_in_height_q,
    input logic        cfg_crop_enable_q,
    input logic [10:0] cfg_x_start_q,
    input logic [10:0] cfg_y_start_q,
    input logic [10:0] cfg_crop_width_q,
    input logic [10:0] cfg_crop_height_q,
    input logic        cfg_resize_x2_q,
    input logic        cfg_resize_y2_q,
    input logic        cfg_threshold_enable_q,
    input logic [7:0]  cfg_threshold_q
);

    int unsigned sva_check_count = 0;
    int unsigned sva_error_count = 0;

    // Shadow registers of previous cycle state for procedural and SVA checks
    logic        past_valid          = 1'b0;
    logic        past_reset_n        = 1'b0;
    logic        past_pixel_valid    = 1'b0;
    logic        past_in_sof         = 1'b0;
    logic        past_frame_active_q = 1'b0;
    logic [10:0] past_x_q            = 11'd0;
    logic [10:0] past_y_q            = 11'd0;

    logic [10:0] past_cfg_in_width_q         = 11'd0;
    logic [10:0] past_cfg_in_height_q        = 11'd0;
    logic        past_cfg_crop_enable_q      = 1'b0;
    logic [10:0] past_cfg_x_start_q          = 11'd0;
    logic [10:0] past_cfg_y_start_q          = 11'd0;
    logic [10:0] past_cfg_crop_width_q       = 11'd0;
    logic [10:0] past_cfg_crop_height_q      = 11'd0;
    logic        past_cfg_resize_x2_q        = 1'b0;
    logic        past_cfg_resize_y2_q        = 1'b0;
    logic        past_cfg_threshold_enable_q = 1'b0;
    logic [7:0]  past_cfg_threshold_q        = 8'd0;

    always @(posedge clk) begin
        if (past_valid) begin
            sva_check_count <= sva_check_count + 1;

            // 1. Synchronous reset must clear all outputs and active frame state
            if (!past_reset_n) begin
                if (pixel_out_valid !== 1'b0 || pixel_out !== 8'd0 ||
                    out_sof !== 1'b0 || out_sol !== 1'b0 ||
                    out_eol !== 1'b0 || out_eof !== 1'b0 ||
                    cfg_error !== 1'b0 || frame_active_q !== 1'b0 ||
                    x_q !== 11'd0 || y_q !== 11'd0) begin
                    $error("[SVA FAIL] sva_reset_clears_all violated after reset_n=0");
                    sva_error_count <= sva_error_count + 1;
                end
            end

            // 2. Invalid output must have zero data and zero markers
            if (pixel_out_valid === 1'b0) begin
                if (pixel_out !== 8'd0 || out_sof !== 1'b0 || out_sol !== 1'b0 ||
                    out_eol !== 1'b0 || out_eof !== 1'b0) begin
                    $error("[SVA FAIL] sva_invalid_out_zero violated: out=%0d flags=%b%b%b%b when valid=0",
                           pixel_out, out_sof, out_sol, out_eol, out_eof);
                    sva_error_count <= sva_error_count + 1;
                end
            end

            // 3. Marker implications: SOF -> SOL & valid, EOF -> EOL & valid
            if (out_sof === 1'b1 && (pixel_out_valid !== 1'b1 || out_sol !== 1'b1)) begin
                $error("[SVA FAIL] sva_sof_sol violated: out_sof=1 without valid & out_sol");
                sva_error_count <= sva_error_count + 1;
            end
            if (out_eof === 1'b1 && (pixel_out_valid !== 1'b1 || out_eol !== 1'b1)) begin
                $error("[SVA FAIL] sva_eof_eol violated: out_eof=1 without valid & out_eol");
                sva_error_count <= sva_error_count + 1;
            end

            // 4. cfg_error exclusivity and cause
            if (cfg_error === 1'b1) begin
                if (pixel_out_valid !== 1'b0 || frame_active_q !== 1'b0 ||
                    !(past_reset_n && past_pixel_valid && past_in_sof)) begin
                    $error("[SVA FAIL] sva_cfg_error violated: cfg_error=1 in illegal state");
                    sva_error_count <= sva_error_count + 1;
                end
            end

            // 5. Bubble freezes internal frame/coordinate state and produces no valid/error
            if (past_reset_n && !past_pixel_valid && reset_n) begin
                if (pixel_out_valid !== 1'b0 || cfg_error !== 1'b0 ||
                    frame_active_q !== past_frame_active_q ||
                    x_q !== past_x_q || y_q !== past_y_q) begin
                    $error("[SVA FAIL] sva_bubble_freeze violated after pixel_valid=0");
                    sva_error_count <= sva_error_count + 1;
                end
            end

            // 6. Captured configuration registers remain stable during an active frame
            if (past_reset_n && past_frame_active_q && !(past_pixel_valid && past_in_sof) && reset_n) begin
                if (cfg_in_width_q         !== past_cfg_in_width_q         ||
                    cfg_in_height_q        !== past_cfg_in_height_q        ||
                    cfg_crop_enable_q      !== past_cfg_crop_enable_q      ||
                    cfg_x_start_q          !== past_cfg_x_start_q          ||
                    cfg_y_start_q          !== past_cfg_y_start_q          ||
                    cfg_crop_width_q       !== past_cfg_crop_width_q       ||
                    cfg_crop_height_q      !== past_cfg_crop_height_q      ||
                    cfg_resize_x2_q        !== past_cfg_resize_x2_q        ||
                    cfg_resize_y2_q        !== past_cfg_resize_y2_q        ||
                    cfg_threshold_enable_q !== past_cfg_threshold_enable_q ||
                    cfg_threshold_q        !== past_cfg_threshold_q) begin
                    $error("[SVA FAIL] sva_cfg_stable_in_frame violated: captured cfg changed mid-frame");
                    sva_error_count <= sva_error_count + 1;
                end
            end

            // 7. Coordinate bounds inside active frame
            if (reset_n && frame_active_q) begin
                if (x_q >= cfg_in_width_q || y_q >= cfg_in_height_q) begin
                    $error("[SVA FAIL] sva_coord_bounds violated: (x_q=%0d, y_q=%0d) >= (%0d, %0d)",
                           x_q, y_q, cfg_in_width_q, cfg_in_height_q);
                    sva_error_count <= sva_error_count + 1;
                end
            end
        end

        past_valid                  <= 1'b1;
        past_reset_n                <= reset_n;
        past_pixel_valid            <= pixel_valid;
        past_in_sof                 <= in_sof;
        past_frame_active_q         <= frame_active_q;
        past_x_q                    <= x_q;
        past_y_q                    <= y_q;

        past_cfg_in_width_q         <= cfg_in_width_q;
        past_cfg_in_height_q        <= cfg_in_height_q;
        past_cfg_crop_enable_q      <= cfg_crop_enable_q;
        past_cfg_x_start_q          <= cfg_x_start_q;
        past_cfg_y_start_q          <= cfg_y_start_q;
        past_cfg_crop_width_q       <= cfg_crop_width_q;
        past_cfg_crop_height_q      <= cfg_crop_height_q;
        past_cfg_resize_x2_q        <= cfg_resize_x2_q;
        past_cfg_resize_y2_q        <= cfg_resize_y2_q;
        past_cfg_threshold_enable_q <= cfg_threshold_enable_q;
        past_cfg_threshold_q        <= cfg_threshold_q;
    end

`ifndef NO_CONCURRENT_SVA
    // -------------------------------------------------------------------------
    // Concurrent SVA properties (enabled by default in Synopsys VCS)
    // -------------------------------------------------------------------------
    property p_reset_clears_all;
        @(posedge clk) (!reset_n) |=> (!pixel_out_valid && (pixel_out == 8'd0) &&
                                       !out_sof && !out_sol && !out_eol && !out_eof &&
                                       !cfg_error && !frame_active_q &&
                                       (x_q == 11'd0) && (y_q == 11'd0));
    endproperty

    property p_invalid_out_zero;
        @(posedge clk) disable iff (!reset_n)
        (!pixel_out_valid) |-> ((pixel_out == 8'd0) && !out_sof && !out_sol && !out_eol && !out_eof);
    endproperty

    property p_sof_implies_sol;
        @(posedge clk) disable iff (!reset_n)
        out_sof |-> (pixel_out_valid && out_sol);
    endproperty

    property p_eof_implies_eol;
        @(posedge clk) disable iff (!reset_n)
        out_eof |-> (pixel_out_valid && out_eol);
    endproperty

    property p_cfg_error_exclusivity;
        @(posedge clk) disable iff (!reset_n)
        cfg_error |-> (!pixel_out_valid && !frame_active_q && $past(reset_n && pixel_valid && in_sof));
    endproperty

    property p_bubble_freeze;
        @(posedge clk) disable iff (!reset_n)
        (reset_n && !pixel_valid) |=> (!pixel_out_valid && !cfg_error &&
                                       $stable(frame_active_q) && $stable(x_q) && $stable(y_q));
    endproperty

    property p_cfg_stable_in_frame;
        @(posedge clk) disable iff (!reset_n)
        (reset_n && frame_active_q && !(pixel_valid && in_sof)) |=>
            ($stable(cfg_in_width_q) && $stable(cfg_in_height_q) &&
             $stable(cfg_crop_enable_q) && $stable(cfg_x_start_q) &&
             $stable(cfg_y_start_q) && $stable(cfg_crop_width_q) &&
             $stable(cfg_crop_height_q) && $stable(cfg_resize_x2_q) &&
             $stable(cfg_resize_y2_q) && $stable(cfg_threshold_enable_q) &&
             $stable(cfg_threshold_q));
    endproperty

    property p_coord_bounds;
        @(posedge clk) disable iff (!reset_n)
        frame_active_q |-> ((x_q < cfg_in_width_q) && (y_q < cfg_in_height_q));
    endproperty

    a_reset_clears_all: assert property (p_reset_clears_all) else begin
        $error("[SVA] a_reset_clears_all failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_invalid_out_zero: assert property (p_invalid_out_zero) else begin
        $error("[SVA] a_invalid_out_zero failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_sof_implies_sol: assert property (p_sof_implies_sol) else begin
        $error("[SVA] a_sof_implies_sol failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_eof_implies_eol: assert property (p_eof_implies_eol) else begin
        $error("[SVA] a_eof_implies_eol failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_cfg_error_exclusivity: assert property (p_cfg_error_exclusivity) else begin
        $error("[SVA] a_cfg_error_exclusivity failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_bubble_freeze: assert property (p_bubble_freeze) else begin
        $error("[SVA] a_bubble_freeze failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_cfg_stable_in_frame: assert property (p_cfg_stable_in_frame) else begin
        $error("[SVA] a_cfg_stable_in_frame failed");
        sva_error_count <= sva_error_count + 1;
    end
    a_coord_bounds: assert property (p_coord_bounds) else begin
        $error("[SVA] a_coord_bounds failed");
        sva_error_count <= sva_error_count + 1;
    end
`endif

endmodule
