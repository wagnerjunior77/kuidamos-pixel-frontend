`timescale 1ns/1ps

module tb_scan_shift;
    logic clk = 0, reset_n = 0, scan_enable = 0, scan_in = 0;
    logic frame_pixel = 0;
    wire scan_out, pixel_out_valid, out_sof, out_sol, out_eol, out_eof, cfg_error;
    wire [7:0] pixel_out;

    kuidamos_pixel_frontend dut (
        .clk(clk), .reset_n(reset_n),
        .scan_enable(scan_enable), .scan_in(scan_in), .scan_out(scan_out),
        .pixel_r(8'hff), .pixel_g(8'hff), .pixel_b(8'hff), .pixel_valid(frame_pixel),
        .in_sof(frame_pixel), .in_sol(frame_pixel), .in_eol(frame_pixel), .in_eof(frame_pixel),
        .cfg_in_width(11'd1), .cfg_in_height(11'd1), .cfg_crop_enable(1'b0),
        .cfg_x_start(11'd0), .cfg_y_start(11'd0),
        .cfg_crop_width(11'd1), .cfg_crop_height(11'd1),
        .cfg_resize_x2(1'b0), .cfg_resize_y2(1'b0),
        .cfg_threshold_enable(1'b0), .cfg_threshold(8'd0),
        .pixel_out(pixel_out), .pixel_out_valid(pixel_out_valid),
        .out_sof(out_sof), .out_sol(out_sol), .out_eol(out_eol), .out_eof(out_eof),
        .cfg_error(cfg_error)
    );

    // Gerado a partir da ordem medida nas conexões pós-inserção.
    `include "actual_chain.svh"
    logic [CHAIN_LENGTH-1:0] expected_q;
    int shifted = 0;

    task automatic pulse_functional();
        #45 clk = 1;
        #10 clk = 0;
        #45;
    endtask

    task automatic shift_bit(input logic value);
        logic expected_out;
        scan_in = value;
        expected_out = expected_q[CHAIN_LENGTH-1] ^ SCAN_OUT_INVERTED[CHAIN_LENGTH-1];
        #44;
        if (scan_out !== expected_out)
            $fatal(1, "scan_out cycle=%0d expected=%b observed=%b", shifted, expected_out, scan_out);
        #1 clk = 1;
        expected_q = ((expected_q ^ SCAN_OUT_INVERTED) << 1);
        expected_q[0] = value;
        #1;
        if (observed_q !== expected_q)
            $fatal(1, "Chain state cycle=%0d expected=%h observed=%h", shifted, expected_q, observed_q);
        #9 clk = 0;
        #45;
        shifted++;
    endtask

    initial begin
        // Inicialização síncrona no modo funcional.
        pulse_functional();
        if (observed_q !== '0) $fatal(1, "Reset funcional não zerou os 115 SDFFs");
        reset_n = 1;
        scan_enable = 1;
        expected_q = '0;
        for (int i = 0; i < CHAIN_LENGTH; i++) shift_bit(0);
        for (int i = 0; i < CHAIN_LENGTH; i++) shift_bit(1);
        for (int i = 0; i < CHAIN_LENGTH; i++) shift_bit(i % 2 == 0);

        scan_enable = 0;
        reset_n = 0;
        pulse_functional();
        reset_n = 1;
        frame_pixel = 1;
        pulse_functional();
        if ({pixel_out_valid, out_sof, out_sol, out_eol, out_eof, cfg_error, pixel_out}
            !== {6'b111110, 8'hff}) $fatal(1, "Captura funcional 1x1 branca falhou");
        if (^observed_q === 1'bx || observed_q == '0 || observed_q == '1)
            $fatal(1, "Estado capturado não é um padrão conhecido e misto");
        expected_q = observed_q;
        frame_pixel = 0;
        scan_enable = 1;
        for (int i = 0; i < CHAIN_LENGTH; i++) shift_bit(0);
        if (shifted != 4 * CHAIN_LENGTH) $fatal(1, "Contagem de ciclos de shift incorreta");
        $display("SHIFT_PASS length=%0d shift_clocks=%0d phases=zeros,ones,alternating,capture_unload",
                 CHAIN_LENGTH, shifted);
        $finish;
    end
endmodule
