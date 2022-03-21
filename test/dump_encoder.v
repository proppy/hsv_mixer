module dump();
    initial begin
        $dumpfile ("encoder.vcd");
        $dumpvars (0, hsv_encoder);
        #1;
    end
endmodule
