module dump();
    initial begin
        $dumpfile ("hsv_mixer.vcd");
        $dumpvars (0, hsv_mixer);
        #1;
    end
endmodule
