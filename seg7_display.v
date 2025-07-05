`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/28 18:49:35
// Design Name: 
// Module Name: seg7_display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seg7_display(
    input        clk,
    input [31:0] data,
    output reg [7:0] seg,
    output reg [7:0] an
);

    reg [3:0] digit;
    reg [19:0] cnt;

always @(posedge clk) begin
    cnt <= cnt + 1;
end

always @(posedge clk) begin
    case (cnt[19:17])
        3'b000: begin digit <= data[3:0];   an <= 8'b11111110; end
        3'b001: begin digit <= data[7:4];   an <= 8'b11111101; end
        3'b010: begin digit <= data[11:8];  an <= 8'b11111011; end
        3'b011: begin digit <= data[15:12]; an <= 8'b11110111; end
        3'b100: begin digit <= data[19:16]; an <= 8'b11101111; end
        3'b101: begin digit <= data[23:20]; an <= 8'b11011111; end
        3'b110: begin digit <= data[27:24]; an <= 8'b10111111; end
        3'b111: begin digit <= data[31:28]; an <= 8'b01111111; end
    endcase
        // 七段译码表
        case (digit)
            4'h0: seg <= 8'b11000000; // 0
            4'h1: seg <= 8'b11111001; // 1
            4'h2: seg <= 8'b10100100; // 2
            4'h3: seg <= 8'b10110000; // 3
            4'h4: seg <= 8'b10011001; // 4
            4'h5: seg <= 8'b10010010; // 5
            4'h6: seg <= 8'b10000010; // 6
            4'h7: seg <= 8'b11111000; // 7
            4'h8: seg <= 8'b10000000; // 8
            4'h9: seg <= 8'b10010000; // 9
            4'hA: seg <= 8'b10001000; // A
            4'hB: seg <= 8'b10000011; // B
            4'hC: seg <= 8'b11000110; // C
            4'hD: seg <= 8'b10100001; // D
            4'hE: seg <= 8'b10000110; // E
            4'hF: seg <= 8'b10001110; // F
            default: seg <= 8'b11111111; // 熄灭
        endcase
    end

endmodule
