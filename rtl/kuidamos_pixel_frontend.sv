// -----------------------------------------------------------------------------
// Module: kuidamos_pixel_frontend
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestones M3–M6)
// Description:
//   Synthesizable streaming pixel pre-processing IP (V1 specification):
//     RGB888 -> Grayscale -> Crop ROI -> Nearest-Neighbor Resize -> Threshold
//   Features:
//     - Atomic configuration sampling and validation on valid in_sof
//     - 1-cycle registered output latency (edge-to-edge)
//     - Regenerated output frame/line markers (out_sof, out_sol, out_eol, out_eof)
//     - Single-cycle cfg_error pulse and full frame discard on invalid config
//     - Synchronous active-low reset (reset_n), single clock domain (DFT-ready)
// -----------------------------------------------------------------------------

module kuidamos_pixel_frontend (
    input  logic        clk,
    input  logic        reset_n,

    // Input pixel stream
    input  logic [7:0]  pixel_r,
    input  logic [7:0]  pixel_g,
    input  logic [7:0]  pixel_b,
    input  logic        pixel_valid,
    input  logic        in_sof,
    input  logic        in_sol,
    input  logic        in_eol,
    input  logic        in_eof,

    // Frame configuration (sampled atomically on valid in_sof)
    input  logic [10:0] cfg_in_width,
    input  logic [10:0] cfg_in_height,
    input  logic        cfg_crop_enable,
    input  logic [10:0] cfg_x_start,
    input  logic [10:0] cfg_y_start,
    input  logic [10:0] cfg_crop_width,
    input  logic [10:0] cfg_crop_height,
    input  logic        cfg_resize_x2,
    input  logic        cfg_resize_y2,
    input  logic        cfg_threshold_enable,
    input  logic [7:0]  cfg_threshold,

    // Output pixel stream and status
    output logic [7:0]  pixel_out,
    output logic        pixel_out_valid,
    output logic        out_sof,
    output logic        out_sol,
    output logic        out_eol,
    output logic        out_eof,
    output logic        cfg_error
);

    // -------------------------------------------------------------------------
    // Registered frame state and captured configuration
    // -------------------------------------------------------------------------
    logic        frame_active_q;
    logic [10:0] x_q;
    logic [10:0] y_q;

    logic [10:0] cfg_in_width_q;
    logic [10:0] cfg_in_height_q;
    logic        cfg_crop_enable_q;
    logic [10:0] cfg_x_start_q;
    logic [10:0] cfg_y_start_q;
    logic [10:0] cfg_crop_width_q;
    logic [10:0] cfg_crop_height_q;
    logic        cfg_resize_x2_q;
    logic        cfg_resize_y2_q;
    logic        cfg_threshold_enable_q;
    logic [7:0]  cfg_threshold_q;

    // -------------------------------------------------------------------------
    // Combinational configuration validation at in_sof
    // -------------------------------------------------------------------------
    logic [11:0] sof_crop_x_end_12;
    logic [11:0] sof_crop_y_end_12;
    logic        sof_in_dims_ok;
    logic        sof_crop_ok;
    logic [10:0] sof_roi_w;
    logic [10:0] sof_roi_h;
    logic [10:0] sof_out_w;
    logic [10:0] sof_out_h;
    logic        sof_out_dims_ok;
    logic        sof_cfg_valid;

    always_comb begin
        sof_crop_x_end_12 = {1'b0, cfg_x_start} + {1'b0, cfg_crop_width};
        sof_crop_y_end_12 = {1'b0, cfg_y_start} + {1'b0, cfg_crop_height};

        sof_in_dims_ok = (cfg_in_width != 11'd0) && (cfg_in_height != 11'd0);

        if (cfg_crop_enable) begin
            sof_crop_ok = (cfg_crop_width  != 11'd0) &&
                          (cfg_crop_height != 11'd0) &&
                          (cfg_x_start     <  cfg_in_width) &&
                          (cfg_y_start     <  cfg_in_height) &&
                          (sof_crop_x_end_12 <= {1'b0, cfg_in_width}) &&
                          (sof_crop_y_end_12 <= {1'b0, cfg_in_height});
            sof_roi_w   = cfg_crop_width;
            sof_roi_h   = cfg_crop_height;
        end else begin
            sof_crop_ok = 1'b1;
            sof_roi_w   = cfg_in_width;
            sof_roi_h   = cfg_in_height;
        end

        sof_out_w       = cfg_resize_x2 ? (sof_roi_w >> 1) : sof_roi_w;
        sof_out_h       = cfg_resize_y2 ? (sof_roi_h >> 1) : sof_roi_h;
        sof_out_dims_ok = (sof_out_w != 11'd0) && (sof_out_h != 11'd0);

        sof_cfg_valid   = sof_in_dims_ok && sof_crop_ok && sof_out_dims_ok;
    end

    // -------------------------------------------------------------------------
    // Active cycle multiplexers (SOF uses incoming cfg_* and (0,0);
    // subsequent pixels in an active frame use registered cfg_*_q and (x_q,y_q))
    // -------------------------------------------------------------------------
    logic        use_sof_cfg;
    logic        pixel_active;
    logic [10:0] curr_x;
    logic [10:0] curr_y;
    logic [10:0] eff_in_width;
    logic [10:0] eff_in_height;
    logic        eff_crop_enable;
    logic [10:0] eff_x_start;
    logic [10:0] eff_y_start;
    logic [10:0] eff_crop_width;
    logic [10:0] eff_crop_height;
    logic        eff_resize_x2;
    logic        eff_resize_y2;
    logic        eff_threshold_enable;
    logic [7:0]  eff_threshold;

    always_comb begin
        use_sof_cfg          = pixel_valid && in_sof;
        pixel_active         = pixel_valid && (in_sof ? sof_cfg_valid : frame_active_q);

        curr_x               = use_sof_cfg ? 11'd0                : x_q;
        curr_y               = use_sof_cfg ? 11'd0                : y_q;

        eff_in_width         = use_sof_cfg ? cfg_in_width         : cfg_in_width_q;
        eff_in_height        = use_sof_cfg ? cfg_in_height        : cfg_in_height_q;
        eff_crop_enable      = use_sof_cfg ? cfg_crop_enable      : cfg_crop_enable_q;
        eff_x_start          = use_sof_cfg ? cfg_x_start          : cfg_x_start_q;
        eff_y_start          = use_sof_cfg ? cfg_y_start          : cfg_y_start_q;
        eff_crop_width       = use_sof_cfg ? cfg_crop_width       : cfg_crop_width_q;
        eff_crop_height      = use_sof_cfg ? cfg_crop_height      : cfg_crop_height_q;
        eff_resize_x2        = use_sof_cfg ? cfg_resize_x2        : cfg_resize_x2_q;
        eff_resize_y2        = use_sof_cfg ? cfg_resize_y2        : cfg_resize_y2_q;
        eff_threshold_enable = use_sof_cfg ? cfg_threshold_enable : cfg_threshold_enable_q;
        eff_threshold        = use_sof_cfg ? cfg_threshold        : cfg_threshold_q;
    end

    // -------------------------------------------------------------------------
    // Datapath instances: Grayscale (M3) -> Crop (M4) -> Resize (M5) -> Threshold (M6)
    // -------------------------------------------------------------------------
    logic [7:0]  y_gray;
    logic        in_roi;
    logic [10:0] roi_u;
    logic [10:0] roi_v;
    logic [10:0] roi_width;
    logic [10:0] roi_height;
    logic [10:0] out_width;
    logic [10:0] out_height;
    logic        sel_pixel;
    logic [10:0] x_out;
    logic [10:0] y_out;
    logic        core_out_sof;
    logic        core_out_sol;
    logic        core_out_eol;
    logic        core_out_eof;
    logic [7:0]  pixel_thresh;

    grayscale_core u_grayscale_core (
        .pixel_r (pixel_r),
        .pixel_g (pixel_g),
        .pixel_b (pixel_b),
        .y_gray  (y_gray)
    );

    crop_core u_crop_core (
        .x           (curr_x),
        .y           (curr_y),
        .in_width    (eff_in_width),
        .in_height   (eff_in_height),
        .crop_enable (eff_crop_enable),
        .x_start     (eff_x_start),
        .y_start     (eff_y_start),
        .crop_width  (eff_crop_width),
        .crop_height (eff_crop_height),
        .in_roi      (in_roi),
        .u           (roi_u),
        .v           (roi_v),
        .roi_width   (roi_width),
        .roi_height  (roi_height)
    );

    resize_nn_core u_resize_nn_core (
        .in_roi     (in_roi),
        .u          (roi_u),
        .v          (roi_v),
        .roi_width  (roi_width),
        .roi_height (roi_height),
        .resize_x2  (eff_resize_x2),
        .resize_y2  (eff_resize_y2),
        .out_width  (out_width),
        .out_height (out_height),
        .sel_pixel  (sel_pixel),
        .x_out      (x_out),
        .y_out      (y_out),
        .out_sof    (core_out_sof),
        .out_sol    (core_out_sol),
        .out_eol    (core_out_eol),
        .out_eof    (core_out_eof)
    );

    threshold_core u_threshold_core (
        .y_gray           (y_gray),
        .threshold_enable (eff_threshold_enable),
        .threshold        (eff_threshold),
        .pixel_thresh     (pixel_thresh)
    );

    // -------------------------------------------------------------------------
    // Next-state logic for coordinates, frame activity, and outputs
    // -------------------------------------------------------------------------
    logic        emit_pixel;
    logic        at_last_col;
    logic        at_last_row;
    logic        frame_done;

    logic        frame_active_d;
    logic [10:0] x_d;
    logic [10:0] y_d;
    logic        pixel_out_valid_d;
    logic [7:0]  pixel_out_d;
    logic        out_sof_d;
    logic        out_sol_d;
    logic        out_eol_d;
    logic        out_eof_d;
    logic        cfg_error_d;

    // Unused input markers on well-formed streams (counters track coordinates;
    // in_sol/in_eol are part of the official V1 interface)
    logic unused_in_markers;
    assign unused_in_markers = in_sol ^ in_eol ^ (|x_out) ^ (|y_out) ^ (|out_width) ^ (|out_height);

    always_comb begin
        emit_pixel        = pixel_active && sel_pixel;
        at_last_col       = (curr_x == (eff_in_width  - 11'd1));
        at_last_row       = (curr_y == (eff_in_height - 11'd1));
        frame_done        = (at_last_col && at_last_row) || in_eof;

        frame_active_d    = frame_active_q;
        x_d               = x_q;
        y_d               = y_q;

        pixel_out_valid_d = emit_pixel;
        pixel_out_d       = emit_pixel ? pixel_thresh : 8'd0;
        out_sof_d         = emit_pixel ? core_out_sof : 1'b0;
        out_sol_d         = emit_pixel ? core_out_sol : 1'b0;
        out_eol_d         = emit_pixel ? core_out_eol : 1'b0;
        out_eof_d         = emit_pixel ? core_out_eof : 1'b0;
        cfg_error_d       = pixel_valid && in_sof && !sof_cfg_valid;

        if (pixel_valid) begin
            if (in_sof && !sof_cfg_valid) begin
                frame_active_d = 1'b0;
                x_d            = 11'd0;
                y_d            = 11'd0;
            end else if (pixel_active) begin
                if (frame_done) begin
                    frame_active_d = 1'b0;
                    x_d            = 11'd0;
                    y_d            = 11'd0;
                end else begin
                    frame_active_d = 1'b1;
                    if (at_last_col) begin
                        x_d = 11'd0;
                        y_d = curr_y + 11'd1;
                    end else begin
                        x_d = curr_x + 11'd1;
                        y_d = curr_y;
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Sequential registers (synchronous active-low reset_n)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            frame_active_q         <= 1'b0;
            x_q                    <= 11'd0;
            y_q                    <= 11'd0;

            cfg_in_width_q         <= 11'd0;
            cfg_in_height_q        <= 11'd0;
            cfg_crop_enable_q      <= 1'b0;
            cfg_x_start_q          <= 11'd0;
            cfg_y_start_q          <= 11'd0;
            cfg_crop_width_q       <= 11'd0;
            cfg_crop_height_q      <= 11'd0;
            cfg_resize_x2_q        <= 1'b0;
            cfg_resize_y2_q        <= 1'b0;
            cfg_threshold_enable_q <= 1'b0;
            cfg_threshold_q        <= 8'd0;

            pixel_out              <= 8'd0;
            pixel_out_valid        <= 1'b0;
            out_sof                <= 1'b0;
            out_sol                <= 1'b0;
            out_eol                <= 1'b0;
            out_eof                <= 1'b0;
            cfg_error              <= 1'b0;
        end else begin
            frame_active_q         <= frame_active_d;
            x_q                    <= x_d;
            y_q                    <= y_d;

            if (pixel_valid && in_sof && sof_cfg_valid) begin
                cfg_in_width_q         <= cfg_in_width;
                cfg_in_height_q        <= cfg_in_height;
                cfg_crop_enable_q      <= cfg_crop_enable;
                cfg_x_start_q          <= cfg_x_start;
                cfg_y_start_q          <= cfg_y_start;
                cfg_crop_width_q       <= cfg_crop_width;
                cfg_crop_height_q      <= cfg_crop_height;
                cfg_resize_x2_q        <= cfg_resize_x2;
                cfg_resize_y2_q        <= cfg_resize_y2;
                cfg_threshold_enable_q <= cfg_threshold_enable;
                cfg_threshold_q        <= cfg_threshold;
            end

            pixel_out              <= pixel_out_d;
            pixel_out_valid        <= pixel_out_valid_d;
            out_sof                <= out_sof_d;
            out_sol                <= out_sol_d;
            out_eol                <= out_eol_d;
            out_eof                <= out_eof_d;
            cfg_error              <= cfg_error_d;
        end
    end

endmodule

