// -----------------------------------------------------------------------------
// Module: tb_kuidamos_pixel_frontend
// Project: KUIDAMOS Pixel Front-End — Group 6C (Milestones M3–M7)
// Description:
//   Self-checking SystemVerilog Testbench and Scoreboard for
//   kuidamos_pixel_frontend.
//   Executes:
//     1. Official M2 functional/temporal vector suite (vectors/m2/*.stim.txt
//        and *.expect.txt, 9 scenarios, 522 cycles).
//     2. M7 directed edge-case suite covering remaining requirements from
//        docs/spec_v1.md §7 (1x1 interior ROI discarding input SOF/EOF,
//        threshold T-1/T/T+1 neighborhood, max dimension 2047 with factor-2
//        and 12-bit sum 4094 overflow check, zero input dimensions, unexpected
//        mid-frame SOF recovery, and bubbles at all boundary positions).
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_kuidamos_pixel_frontend;

    localparam time CLK_PERIOD = 10ns; // 100 MHz initial analysis reference

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        reset_n;

    logic [7:0]  pixel_r;
    logic [7:0]  pixel_g;
    logic [7:0]  pixel_b;
    logic        pixel_valid;
    logic        in_sof;
    logic        in_sol;
    logic        in_eol;
    logic        in_eof;

    logic [10:0] cfg_in_width;
    logic [10:0] cfg_in_height;
    logic        cfg_crop_enable;
    logic [10:0] cfg_x_start;
    logic [10:0] cfg_y_start;
    logic [10:0] cfg_crop_width;
    logic [10:0] cfg_crop_height;
    logic        cfg_resize_x2;
    logic        cfg_resize_y2;
    logic        cfg_threshold_enable;
    logic [7:0]  cfg_threshold;

    logic [7:0]  pixel_out;
    logic        pixel_out_valid;
    logic        out_sof;
    logic        out_sol;
    logic        out_eol;
    logic        out_eof;
    logic        cfg_error;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    kuidamos_pixel_frontend u_dut (
        .clk                  (clk),
        .reset_n              (reset_n),
        .pixel_r              (pixel_r),
        .pixel_g              (pixel_g),
        .pixel_b              (pixel_b),
        .pixel_valid          (pixel_valid),
        .in_sof               (in_sof),
        .in_sol               (in_sol),
        .in_eol               (in_eol),
        .in_eof               (in_eof),
        .cfg_in_width         (cfg_in_width),
        .cfg_in_height        (cfg_in_height),
        .cfg_crop_enable      (cfg_crop_enable),
        .cfg_x_start          (cfg_x_start),
        .cfg_y_start          (cfg_y_start),
        .cfg_crop_width       (cfg_crop_width),
        .cfg_crop_height      (cfg_crop_height),
        .cfg_resize_x2        (cfg_resize_x2),
        .cfg_resize_y2        (cfg_resize_y2),
        .cfg_threshold_enable (cfg_threshold_enable),
        .cfg_threshold        (cfg_threshold),
        .pixel_out            (pixel_out),
        .pixel_out_valid      (pixel_out_valid),
        .out_sof              (out_sof),
        .out_sol              (out_sol),
        .out_eol              (out_eol),
        .out_eof              (out_eof),
        .cfg_error            (cfg_error)
    );

    // -------------------------------------------------------------------------
    // SVA monitor instantiation
    // -------------------------------------------------------------------------
    kuidamos_pixel_frontend_sva u_sva (
        .clk                    (clk),
        .reset_n                (reset_n),
        .pixel_valid            (pixel_valid),
        .in_sof                 (in_sof),
        .in_sol                 (in_sol),
        .in_eol                 (in_eol),
        .in_eof                 (in_eof),
        .pixel_out              (pixel_out),
        .pixel_out_valid        (pixel_out_valid),
        .out_sof                (out_sof),
        .out_sol                (out_sol),
        .out_eol                (out_eol),
        .out_eof                (out_eof),
        .cfg_error              (cfg_error),
        .frame_active_q         (u_dut.frame_active_q),
        .x_q                    (u_dut.x_q),
        .y_q                    (u_dut.y_q),
        .cfg_in_width_q         (u_dut.cfg_in_width_q),
        .cfg_in_height_q        (u_dut.cfg_in_height_q),
        .cfg_crop_enable_q      (u_dut.cfg_crop_enable_q),
        .cfg_x_start_q          (u_dut.cfg_x_start_q),
        .cfg_y_start_q          (u_dut.cfg_y_start_q),
        .cfg_crop_width_q       (u_dut.cfg_crop_width_q),
        .cfg_crop_height_q      (u_dut.cfg_crop_height_q),
        .cfg_resize_x2_q        (u_dut.cfg_resize_x2_q),
        .cfg_resize_y2_q        (u_dut.cfg_resize_y2_q),
        .cfg_threshold_enable_q (u_dut.cfg_threshold_enable_q),
        .cfg_threshold_q        (u_dut.cfg_threshold_q)
    );

    // -------------------------------------------------------------------------
    // Clock generation (100 MHz -> rising edge at 10ns, 20ns, 30ns, ...)
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Global scoreboard counters
    // -------------------------------------------------------------------------
    int unsigned total_cases_run       = 0;
    int unsigned total_cases_passed    = 0;
    int unsigned total_cycles_checked  = 0;
    int unsigned total_mismatches      = 0;
    int unsigned case_mismatches       = 0;
    int unsigned case_cycles           = 0;
    int unsigned case_in_valid         = 0;
    int unsigned case_out_registered   = 0;
    int unsigned case_out_consumed     = 0;
    int unsigned case_cfg_errors       = 0;
    logic        prev_pixel_out_valid  = 1'b0;

    // -------------------------------------------------------------------------
    // Core cycle execution and Scoreboard check task
    // Follows docs/evidencias/M2_vetores.md edge convention:
    //   1. Present stimulus before rising edge n
    //   2. At rising edge n, check consume_valid = (reset_n && prev_out_valid)
    //   3. After register update on edge n, compare registered outputs against
    //      expected_after
    // -------------------------------------------------------------------------
    task automatic apply_and_check_cycle(
        input string       case_name,
        input int          cyc,
        input logic        s_reset_n,
        input logic        s_pixel_valid,
        input logic [7:0]  s_pixel_r,
        input logic [7:0]  s_pixel_g,
        input logic [7:0]  s_pixel_b,
        input logic        s_in_sof,
        input logic        s_in_sol,
        input logic        s_in_eol,
        input logic        s_in_eof,
        input logic [10:0] s_cfg_in_width,
        input logic [10:0] s_cfg_in_height,
        input logic        s_cfg_crop_enable,
        input logic [10:0] s_cfg_x_start,
        input logic [10:0] s_cfg_y_start,
        input logic [10:0] s_cfg_crop_width,
        input logic [10:0] s_cfg_crop_height,
        input logic        s_cfg_resize_x2,
        input logic        s_cfg_resize_y2,
        input logic        s_cfg_threshold_enable,
        input logic [7:0]  s_cfg_threshold,
        input logic        e_pixel_out_valid,
        input logic [7:0]  e_pixel_out,
        input logic        e_out_sof,
        input logic        e_out_sol,
        input logic        e_out_eol,
        input logic        e_out_eof,
        input logic        e_cfg_error,
        input logic        e_consume_valid
    );
        logic actual_consume_valid;

        // 1. Drive inputs prior to rising edge n
        reset_n              = s_reset_n;
        pixel_valid          = s_pixel_valid;
        pixel_r              = s_pixel_r;
        pixel_g              = s_pixel_g;
        pixel_b              = s_pixel_b;
        in_sof               = s_in_sof;
        in_sol               = s_in_sol;
        in_eol               = s_in_eol;
        in_eof               = s_in_eof;
        cfg_in_width         = s_cfg_in_width;
        cfg_in_height        = s_cfg_in_height;
        cfg_crop_enable      = s_cfg_crop_enable;
        cfg_x_start          = s_cfg_x_start;
        cfg_y_start          = s_cfg_y_start;
        cfg_crop_width       = s_cfg_crop_width;
        cfg_crop_height      = s_cfg_crop_height;
        cfg_resize_x2        = s_cfg_resize_x2;
        cfg_resize_y2        = s_cfg_resize_y2;
        cfg_threshold_enable = s_cfg_threshold_enable;
        cfg_threshold        = s_cfg_threshold;

        // 2. Wait for rising clock edge n and evaluate consumption of (n-1) output
        @(posedge clk);
        actual_consume_valid = (s_reset_n === 1'b1) && (prev_pixel_out_valid === 1'b1);

        // 3. Wait 1ns after rising edge for register NBA updates to settle
        #1ns;

        if ( pixel_out_valid      !== e_pixel_out_valid ||
             pixel_out            !== e_pixel_out       ||
             out_sof              !== e_out_sof         ||
             out_sol              !== e_out_sol         ||
             out_eol              !== e_out_eol         ||
             out_eof              !== e_out_eof         ||
             cfg_error            !== e_cfg_error       ||
             actual_consume_valid !== e_consume_valid ) begin
            $display("[SCOREBOARD FAIL] case=%s cycle=%0d", case_name, cyc);
            $display("  expected: valid=%0b out=%0d sof=%0b sol=%0b eol=%0b eof=%0b err=%0b consume=%0b",
                     e_pixel_out_valid, e_pixel_out, e_out_sof, e_out_sol,
                     e_out_eol, e_out_eof, e_cfg_error, e_consume_valid);
            $display("  actual:   valid=%0b out=%0d sof=%0b sol=%0b eol=%0b eof=%0b err=%0b consume=%0b",
                     pixel_out_valid, pixel_out, out_sof, out_sol,
                     out_eol, out_eof, cfg_error, actual_consume_valid);
            case_mismatches  = case_mismatches + 1;
            total_mismatches = total_mismatches + 1;
        end

        prev_pixel_out_valid = pixel_out_valid;
        case_cycles          = case_cycles + 1;
        total_cycles_checked = total_cycles_checked + 1;
        if (s_pixel_valid)        case_in_valid       = case_in_valid + 1;
        if (pixel_out_valid)      case_out_registered = case_out_registered + 1;
        if (actual_consume_valid) case_out_consumed   = case_out_consumed + 1;
        if (cfg_error)            case_cfg_errors     = case_cfg_errors + 1;
    endtask

    // -------------------------------------------------------------------------
    // Reset case counters before starting a new test scenario
    // -------------------------------------------------------------------------
    task automatic begin_case(input string name);
        case_mismatches      = 0;
        case_cycles          = 0;
        case_in_valid        = 0;
        case_out_registered  = 0;
        case_out_consumed    = 0;
        case_cfg_errors      = 0;
        prev_pixel_out_valid = 1'b0;
    endtask

    task automatic end_case(input string name);
        total_cases_run = total_cases_run + 1;
        if (case_mismatches == 0 && case_cycles > 0) begin
            total_cases_passed = total_cases_passed + 1;
            $display("[PASS] %-36s | cycles=%4d in_valid=%4d out_reg=%4d out_cons=%4d cfg_err=%1d",
                     name, case_cycles, case_in_valid, case_out_registered, case_out_consumed, case_cfg_errors);
        end else begin
            $display("[FAIL] %-36s | cycles=%4d mismatches=%0d",
                     name, case_cycles, case_mismatches);
        end
    endtask

    // -------------------------------------------------------------------------
    // Lookup expected cycle count for official M2 scenarios (0 = unknown/custom)
    // -------------------------------------------------------------------------
    function automatic int get_expected_m2_cycles(input string case_name);
        if      (case_name == "01_minimo_1x1")                    return 3;
        else if (case_name == "02_primarias_4x4")                 return 18;
        else if (case_name == "03_centro_f12_t0")                 return 66;
        else if (case_name == "04_borda_f21_t255")                return 66;
        else if (case_name == "05_impar_f22_t128_bolhas")         return 22;
        else if (case_name == "06_aleatorio_16x16")               return 258;
        else if (case_name == "07_config_e_quadros_consecutivos") return 34;
        else if (case_name == "08_reset_e_recuperacao")           return 35;
        else if (case_name == "09_invalidos_e_recuperacao")       return 20;
        else                                                      return 0;
    endfunction

    // -------------------------------------------------------------------------
    // Suite 1: Run an M2 vector scenario from <vector_dir>/<case_name>.{stim,expect}.txt
    // -------------------------------------------------------------------------
    task automatic run_m2_vector_case(
        input string vector_dir,
        input string case_name,
        input int    expected_cycles
    );
        string stim_path;
        string expect_path;
        int    fd_stim;
        int    fd_expect;
        string line_stim;
        string line_expect;
        int    n_stim;
        int    n_expect;
        int    expected_row_cycle;

        int    s_cycle, s_reset_n, s_pixel_valid, s_r, s_g, s_b;
        int    s_sof, s_sol, s_eol, s_eof;
        int    s_in_w, s_in_h, s_crop_en, s_x0, s_y0, s_cw, s_ch;
        int    s_rx2, s_ry2, s_th_en, s_th;

        int    e_cycle, e_out_valid, e_out, e_sof, e_sol, e_eol, e_eof, e_err, e_cons;

        stim_path   = {vector_dir, "/", case_name, ".stim.txt"};
        expect_path = {vector_dir, "/", case_name, ".expect.txt"};

        fd_stim   = $fopen(stim_path, "r");
        fd_expect = $fopen(expect_path, "r");

        if (fd_stim == 0 || fd_expect == 0) begin
            $fatal(1, "[ERROR] Unable to open vector files for case %s (%s, %s)",
                   case_name, stim_path, expect_path);
        end

        begin_case(case_name);
        expected_row_cycle = 0;

        // Read and validate '#' header lines
        if ($fgets(line_stim, fd_stim) == 0 || $fgets(line_expect, fd_expect) == 0) begin
            $display("[ERROR] Missing header line in case %s", case_name);
            case_mismatches  = case_mismatches + 1;
            total_mismatches = total_mismatches + 1;
        end

        while ($fgets(line_stim, fd_stim) != 0) begin
            if ($fgets(line_expect, fd_expect) == 0) begin
                $display("[ERROR] Premature EOF in %s at cycle %0d", expect_path, expected_row_cycle);
                case_mismatches  = case_mismatches + 1;
                total_mismatches = total_mismatches + 1;
            end else begin
                n_stim = $sscanf(
                    line_stim,
                    "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
                    s_cycle, s_reset_n, s_pixel_valid, s_r, s_g, s_b,
                    s_sof, s_sol, s_eol, s_eof,
                    s_in_w, s_in_h, s_crop_en, s_x0, s_y0, s_cw, s_ch,
                    s_rx2, s_ry2, s_th_en, s_th
                );
                n_expect = $sscanf(
                    line_expect,
                    "%d %d %d %d %d %d %d %d %d",
                    e_cycle, e_out_valid, e_out, e_sof, e_sol, e_eol, e_eof, e_err, e_cons
                );

                if (n_stim != 21 || n_expect != 9 ||
                    s_cycle != expected_row_cycle || e_cycle != expected_row_cycle) begin
                    $display("[ERROR] Malformed/out-of-sequence row in case %s: expected_cycle=%0d n_stim=%0d n_expect=%0d s_cycle=%0d e_cycle=%0d",
                             case_name, expected_row_cycle, n_stim, n_expect, s_cycle, e_cycle);
                    case_mismatches  = case_mismatches + 1;
                    total_mismatches = total_mismatches + 1;
                end else begin
                    apply_and_check_cycle(
                        case_name,
                        s_cycle,
                        s_reset_n[0],
                        s_pixel_valid[0],
                        s_r[7:0],
                        s_g[7:0],
                        s_b[7:0],
                        s_sof[0],
                        s_sol[0],
                        s_eol[0],
                        s_eof[0],
                        s_in_w[10:0],
                        s_in_h[10:0],
                        s_crop_en[0],
                        s_x0[10:0],
                        s_y0[10:0],
                        s_cw[10:0],
                        s_ch[10:0],
                        s_rx2[0],
                        s_ry2[0],
                        s_th_en[0],
                        s_th[7:0],
                        e_out_valid[0],
                        e_out[7:0],
                        e_sof[0],
                        e_sol[0],
                        e_eol[0],
                        e_eof[0],
                        e_err[0],
                        e_cons[0]
                    );
                end
                expected_row_cycle = expected_row_cycle + 1;
            end
        end

        // Check for extra unconsumed lines in expect file after stim file ended
        if ($fgets(line_expect, fd_expect) != 0) begin
            $display("[ERROR] Extra trailing line(s) in %s after %s ended at cycle %0d",
                     expect_path, stim_path, case_cycles);
            case_mismatches  = case_mismatches + 1;
            total_mismatches = total_mismatches + 1;
        end

        // Reject empty / header-only vector files
        if (case_cycles == 0) begin
            $display("[ERROR] Vector case %s executed 0 cycles (empty or header-only file)", case_name);
            case_mismatches  = case_mismatches + 1;
            total_mismatches = total_mismatches + 1;
        end

        // Validate expected cycle count to detect simultaneous truncation of stim and expect
        if (expected_cycles > 0 && case_cycles != expected_cycles) begin
            $display("[ERROR] Cycle count mismatch in case %s: executed=%0d expected=%0d (truncated or modified vector)",
                     case_name, case_cycles, expected_cycles);
            case_mismatches  = case_mismatches + 1;
            total_mismatches = total_mismatches + 1;
        end

        $fclose(fd_stim);
        $fclose(fd_expect);
        end_case(case_name);
    endtask

    // -------------------------------------------------------------------------
    // Suite 2: M7 Directed Edge-Case Scenarios (docs/spec_v1.md §7)
    // -------------------------------------------------------------------------

    // M7.1: 1x1 interior ROI in a 4x4 frame (both input SOF at (0,0) and input
    // EOF at (3,3) are discarded; single output pixel at (1,1) must regenerate
    // out_sof=out_sol=out_eol=out_eof=1).
    task automatic run_m7_01_roi_1x1_discard_first_last();
        string name;
        int    cyc;
        int    x, y, idx;
        logic  is_target;
        logic  prev_v;

        name = "m7_01_roi_1x1_discard_first_last";
        begin_case(name);
        cyc = 0;

        // Cycle 0: synchronous reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd4, 11'd4, 1'b1, 11'd1, 11'd1, 11'd1, 11'd1,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        prev_v = 1'b0;
        for (idx = 0; idx < 16; idx++) begin
            x = idx % 4;
            y = idx / 4;
            is_target = (x == 1) && (y == 1);
            // Send R=G=B=200 at (1,1) -> Y=200; R=G=B=50 elsewhere
            apply_and_check_cycle(
                name, cyc++, 1'b1, 1'b1,
                is_target ? 8'd200 : 8'd50,
                is_target ? 8'd200 : 8'd50,
                is_target ? 8'd200 : 8'd50,
                (idx == 0), (x == 0), (x == 3), (idx == 15),
                11'd4, 11'd4, 1'b1, 11'd1, 11'd1, 11'd1, 11'd1,
                1'b0, 1'b0, 1'b0, 8'd0,
                is_target, is_target ? 8'd200 : 8'd0,
                is_target, is_target, is_target, is_target,
                1'b0, prev_v
            );
            prev_v = is_target;
        end

        // Final idle bubble to consume any pending pixel
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd4, 11'd4, 1'b1, 11'd1, 11'd1, 11'd1, 11'd1,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, prev_v);
        end_case(name);
    endtask

    // M7.2: Threshold boundary neighborhood (Y = T-1 -> 0, Y = T -> 255, Y = T+1 -> 255)
    task automatic run_m7_02_threshold_neighborhood();
        string name;
        int    cyc;

        name = "m7_02_threshold_neighborhood";
        begin_case(name);
        cyc = 0;

        // Reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd3, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // Pixel 0 (x=0, y=0): R=G=B=99 -> Y=99 < 100 -> 0 (SOF=1, SOL=1)
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd99, 8'd99, 8'd99,
                              1'b1, 1'b1, 1'b0, 1'b0,
                              11'd3, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b1, 8'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        // Pixel 1 (x=1, y=0): R=G=B=100 -> Y=100 >= 100 -> 255
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd100, 8'd100, 8'd100,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd3, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b1, 8'd255, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        // Pixel 2 (x=2, y=0): R=G=B=101 -> Y=101 >= 100 -> 255 (EOL=1, EOF=1)
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd101, 8'd101, 8'd101,
                              1'b0, 1'b0, 1'b1, 1'b1,
                              11'd3, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b1, 8'd255, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1);

        // Trailing bubble
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd3, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        end_case(name);
    endtask

    // M7.3: Max dimension 2047x1 with factor-2 resize (1023 outputs at 0..2044)
    // and 12-bit sum overflow protection (x_start=2047 + crop_width=2047 = 4094)
    task automatic run_m7_03_max_dim_2047_and_12bit_sum();
        string name;
        int    cyc;
        int    x;
        logic  sel;
        logic  is_first, is_last;
        logic  prev_v;
        logic [7:0] val;

        name = "m7_03_max_dim_2047_and_12bit_sum";
        begin_case(name);
        cyc = 0;

        // Reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2047, 11'd1, 1'b1, 11'd2047, 11'd0, 11'd2047, 11'd1,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // Frame A1 (x_start=2047, crop_width=2047 -> boundary + 12-bit sum 4094 > 2047):
        // Must trigger cfg_error=1 and discard pixel
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd120, 8'd120, 8'd120,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd2047, 11'd1, 1'b1, 11'd2047, 11'd0, 11'd2047, 11'd1,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        // Frame A2 (Horizontal 12-bit sum overflow with valid x_start < in_width:
        // in_width=2047, x_start=2046, crop_width=3 -> 12-bit sum 2049 > 2047,
        // whereas 11-bit truncated sum wraps to 1 <= 2047):
        // Must trigger cfg_error=1 and discard pixel
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd120, 8'd120, 8'd120,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd2047, 11'd2047, 1'b1, 11'd2046, 11'd0, 11'd3, 11'd1,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        // Frame A3 (Vertical 12-bit sum overflow with valid y_start < in_height:
        // in_height=2047, y_start=2046, crop_height=3 -> 12-bit sum 2049 > 2047,
        // whereas 11-bit truncated sum wraps to 1 <= 2047):
        // Must trigger cfg_error=1 and discard pixel
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd120, 8'd120, 8'd120,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd2047, 11'd2047, 1'b1, 11'd0, 11'd2046, 11'd1, 11'd3,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        // Frame B: Valid 2047x1 with resize_x2=1 (W_out = 1023, selected x = 0,2,...,2044; x=2046 discarded)
        prev_v = 1'b0;
        for (x = 0; x < 2047; x++) begin
            sel      = ((x % 2) == 0) && (x <= 2044);
            is_first = (x == 0);
            is_last  = (x == 2044);
            val      = x[7:0];
            apply_and_check_cycle(
                name, cyc++, 1'b1, 1'b1, val, val, val,
                (x == 0), (x == 0), (x == 2046), (x == 2046),
                11'd2047, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                1'b1, 1'b0, 1'b0, 8'd0,
                sel, sel ? val : 8'd0,
                sel && is_first, sel && is_first, sel && is_last, sel && is_last,
                1'b0, prev_v
            );
            prev_v = sel;
        end

        // Final idle bubble
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2047, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b1, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, prev_v);

        end_case(name);
    endtask

    // M7.4: Invalid zero input dimensions (in_width=0 or in_height=0) followed by valid recovery
    task automatic run_m7_04_zero_input_dims();
        string name;
        int    cyc;

        name = "m7_04_zero_input_dims";
        begin_case(name);
        cyc = 0;

        // Reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd0, 11'd4, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // SOF with cfg_in_width = 0 -> cfg_error = 1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd80, 8'd80, 8'd80,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd0, 11'd4, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        // SOF with cfg_in_height = 0 -> cfg_error = 1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd80, 8'd80, 8'd80,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd4, 11'd0, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        // Valid 1x1 recovery frame
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd42, 8'd42, 8'd42,
                              1'b1, 1'b1, 1'b1, 1'b1,
                              11'd1, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd42, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0);

        // Trailing bubble
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd1, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        end_case(name);
    endtask

    // M7.5: Unexpected valid in_sof mid-frame without reset (restarts capture and (0,0) coordinates)
    task automatic run_m7_05_unexpected_sof_recovery();
        string name;
        int    cyc;

        name = "m7_05_unexpected_sof_recovery";
        begin_case(name);
        cyc = 0;

        // Reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd4, 11'd4, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // Start 4x4 frame (send only 2 pixels: (0,0) and (1,0))
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd10, 8'd10, 8'd10,
                              1'b1, 1'b1, 1'b0, 1'b0,
                              11'd4, 11'd4, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd10, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd20, 8'd20, 8'd20,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd4, 11'd4, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd20, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        // Unexpected in_sof=1 starts a new 2x1 frame with threshold=100 enabled!
        // Pixel (0,0) of new frame: R=G=B=150 -> 255, SOF=1, SOL=1, EOL=0, EOF=0
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd150, 8'd150, 8'd150,
                              1'b1, 1'b1, 1'b0, 1'b0,
                              11'd2, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b1, 8'd255, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1);

        // Pixel (1,0) of new 2x1 frame: R=G=B=50 -> 0, SOF=0, SOL=0, EOL=1, EOF=1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd50, 8'd50, 8'd50,
                              1'b0, 1'b0, 1'b1, 1'b1,
                              11'd2, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b1, 8'd0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1);

        // Trailing bubble
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd1, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b1, 8'd100,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        end_case(name);
    endtask

    // M7.6: Bubbles at every boundary position (before SOF, after SOF, after EOL, before EOF, after EOF)
    task automatic run_m7_06_bubbles_all_positions();
        string name;
        int    cyc;

        name = "m7_06_bubbles_all_positions";
        begin_case(name);
        cyc = 0;

        // Reset
        apply_and_check_cycle(name, cyc++, 1'b0, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // Bubble before SOF
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // Pixel (0,0) SOF=1, SOL=1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd11, 8'd11, 8'd11,
                              1'b1, 1'b1, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd11, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        // Bubble after SOF (consumes pixel (0,0))
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        // Pixel (1,0) EOL=1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd22, 8'd22, 8'd22,
                              1'b0, 1'b0, 1'b1, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd22, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);

        // Bubble after EOL (consumes pixel (1,0))
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        // Pixel (0,1) SOL=1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd33, 8'd33, 8'd33,
                              1'b0, 1'b1, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd33, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        // Bubble before EOF (consumes pixel (0,1))
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        // Pixel (1,1) EOL=1, EOF=1
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b1, 8'd44, 8'd44, 8'd44,
                              1'b0, 1'b0, 1'b1, 1'b1,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b1, 8'd44, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0);

        // Bubble after EOF (consumes pixel (1,1))
        apply_and_check_cycle(name, cyc++, 1'b1, 1'b0, 8'd0, 8'd0, 8'd0,
                              1'b0, 1'b0, 1'b0, 1'b0,
                              11'd2, 11'd2, 1'b0, 11'd0, 11'd0, 11'd0, 11'd0,
                              1'b0, 1'b0, 1'b0, 8'd0,
                              1'b0, 8'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        end_case(name);
    endtask

    // -------------------------------------------------------------------------
    // Main test orchestration and optional waveform dumping
    // -------------------------------------------------------------------------
    string vector_dir;
    string single_case;
    string vcd_file;
    int    custom_expect_cycles;

    initial begin
        if (!$value$plusargs("VECTOR_DIR=%s", vector_dir)) begin
            vector_dir = "vectors/m2";
        end
        if (!$value$plusargs("EXPECT_CYCLES=%d", custom_expect_cycles)) begin
            custom_expect_cycles = -1;
        end
        if ($test$plusargs("DUMP_VCD")) begin
            if (!$value$plusargs("VCD_FILE=%s", vcd_file)) begin
                vcd_file = "outputs/tb_kuidamos_pixel_frontend.vcd";
            end
            $dumpfile(vcd_file);
            $dumpvars(0, tb_kuidamos_pixel_frontend);
        end

        // Initialize inputs cleanly before time 0
        reset_n              = 1'b0;
        pixel_valid          = 1'b0;
        pixel_r              = 8'd0;
        pixel_g              = 8'd0;
        pixel_b              = 8'd0;
        in_sof               = 1'b0;
        in_sol               = 1'b0;
        in_eol               = 1'b0;
        in_eof               = 1'b0;
        cfg_in_width         = 11'd1;
        cfg_in_height        = 11'd1;
        cfg_crop_enable      = 1'b0;
        cfg_x_start          = 11'd0;
        cfg_y_start          = 11'd0;
        cfg_crop_width       = 11'd0;
        cfg_crop_height      = 11'd0;
        cfg_resize_x2        = 1'b0;
        cfg_resize_y2        = 1'b0;
        cfg_threshold_enable = 1'b0;
        cfg_threshold        = 8'd0;

        $display("====================================================================================");
        $display(" KUIDAMOS Pixel Front-End (Group 6C) — Functional Verification & Scoreboard (M3–M7)");
        $display("====================================================================================");

        if ($value$plusargs("CASE=%s", single_case)) begin
            run_m2_vector_case(
                vector_dir,
                single_case,
                (custom_expect_cycles >= 0) ? custom_expect_cycles : get_expected_m2_cycles(single_case)
            );
        end else begin
            $display("--- [Suite 1] Official M2 Vector Scenarios (%s) ---", vector_dir);
            run_m2_vector_case(vector_dir, "01_minimo_1x1",                    3);
            run_m2_vector_case(vector_dir, "02_primarias_4x4",                 18);
            run_m2_vector_case(vector_dir, "03_centro_f12_t0",                 66);
            run_m2_vector_case(vector_dir, "04_borda_f21_t255",                66);
            run_m2_vector_case(vector_dir, "05_impar_f22_t128_bolhas",         22);
            run_m2_vector_case(vector_dir, "06_aleatorio_16x16",               258);
            run_m2_vector_case(vector_dir, "07_config_e_quadros_consecutivos", 34);
            run_m2_vector_case(vector_dir, "08_reset_e_recuperacao",           35);
            run_m2_vector_case(vector_dir, "09_invalidos_e_recuperacao",       20);

            $display("--- [Suite 2] Directed M7 Edge-Case Scenarios (docs/spec_v1.md §7) ---");
            run_m7_01_roi_1x1_discard_first_last();
            run_m7_02_threshold_neighborhood();
            run_m7_03_max_dim_2047_and_12bit_sum();
            run_m7_04_zero_input_dims();
            run_m7_05_unexpected_sof_recovery();
            run_m7_06_bubbles_all_positions();
        end

        $display("====================================================================================");
        $display(" SUMMARY: cases_passed=%0d/%0d | cycles_checked=%0d | scoreboard_mismatches=%0d | sva_errors=%0d (sva_checks=%0d)",
                 total_cases_passed, total_cases_run, total_cycles_checked,
                 total_mismatches, u_sva.sva_error_count, u_sva.sva_check_count);
        $display("====================================================================================");

        if (total_mismatches == 0 && u_sva.sva_error_count == 0 &&
            total_cases_run > 0 && total_cases_passed == total_cases_run) begin
            $display("OVERALL RESULT: PASS");
            $finish(0);
        end else begin
            $display("OVERALL RESULT: FAIL");
            $fatal(1, "Verification failed: cases_passed=%0d/%0d scoreboard_mismatches=%0d sva_errors=%0d",
                   total_cases_passed, total_cases_run, total_mismatches, u_sva.sva_error_count);
        end
    end

endmodule

