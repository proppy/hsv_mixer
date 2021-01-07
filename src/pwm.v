`default_nettype none
`timescale 1ns/1ns
module pwm #(
    parameter WIDTH = 8,
    parameter INVERT = 0
    ) (
    input wire clk,
    input wire reset,
    output wire out,
    input wire [WIDTH-1:0] level
    );

    reg [WIDTH-1:0] count;
    wire pwm_on = count < level;

    always @(posedge clk or posedge reset) begin
        if(reset) 
            count <= 0;
        else
            count <= count + 1;
    end

    assign out = reset ? 0:
        INVERT == 0 ? pwm_on : ! pwm_on;

endmodule
