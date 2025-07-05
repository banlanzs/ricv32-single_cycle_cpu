`include "ctrl_encode_def.v"
// data memory
module dm(
    input         clk,
    input         DMWr,
    input  [8:2]  addr,
    input  [2:0]  DMType,  // 新增
    input  [31:0] din,
    output [31:0] dout
);

     
   reg [31:0] dmem[127:0];
   wire [31:0] dout_raw;
   assign dout_raw = dmem[addr[8:2]];
   assign dout = 
        (DMType == `dm_byte)              ? {{24{dout_raw[7]}},  dout_raw[7:0]} :
        (DMType == `dm_halfword)          ? {{16{dout_raw[15]}}, dout_raw[15:0]} :
        (DMType == `dm_byte_unsigned)     ? {24'b0, dout_raw[7:0]} :
        (DMType == `dm_halfword_unsigned) ? {16'b0, dout_raw[15:0]} :
                                            dout_raw;  // 默认：word
  always @(posedge clk) begin
        if (DMWr) begin
            case (DMType)
                `dm_byte: begin
                    dmem[addr[8:2]][7:0] <= din[7:0];
                    $display("SB  @%h <= 0x%02x", addr << 2, din[7:0]);
                end
                `dm_halfword: begin
                    dmem[addr[8:2]][15:0] <= din[15:0];
                    $display("SH  @%h <= 0x%04x", addr << 2, din[15:0]);
                end
                default: begin
                    dmem[addr[8:2]] <= din;
                    $display("SW  @%h <= 0x%08x", addr << 2, din);
                end
            endcase
        end
    end
    
endmodule
