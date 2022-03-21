module dump();
    initial begin
        $dumpfile ("debounce.vcd");
        $dumpvars (0, hsv_debounce);
        #1;
    end
endmodule
