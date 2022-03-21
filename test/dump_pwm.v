module dump();
    initial begin
        $dumpfile ("pwm.vcd");
        $dumpvars (0, hsv_pwm);
        #1;
    end
endmodule
