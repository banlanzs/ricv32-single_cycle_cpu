module debounce(
    input clk,
    input btn_in,
    output reg btn_out
);
    reg [19:0] counter;
    reg btn_sync;
    
    always @(posedge clk) begin
        // Synchronize the button input to the clock domain
        btn_sync <= btn_in;
        
        // Debounce logic
        if (btn_out != btn_sync) begin
            counter <= counter + 1;
            if (&counter) btn_out <= btn_sync;
        end else begin
            counter <= 0;
        end
    end
endmodule
module sccomp(
    input          clk,
    input          rstn_i,
    input  [15:0]  sw_i,       // æ–°å¢žï¼?16ä½å¼€å…³è¾“å…?
    //input  [4:0]   reg_sel,
    output [7:0]   disp_seg_o, // æ–°å¢žï¼šæ•°ç ç®¡æ®µé??
    output [7:0]   disp_an_o // æ–°å¢žï¼šæ•°ç ç®¡ä½é??
    //output [31:0]  reg_data    // ä¿ç•™ï¼šå¯„å­˜å™¨è°ƒè¯•è¾“å‡º
);
   
   // ---- å®žä¾‹åŒ–æ¶ˆæŠ–æ¨¡å? ----
    wire [15:0] sw_db;
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin: debounce_gen
            debounce db_inst (
                .clk(clk),
                .btn_in(sw_i[i]),
                .btn_out(sw_db[i])
            );
        end
    endgenerate
    wire [4:0]    reg_sel=sw_i[4:0];
   // ç¡®ä¿æ‰?æœ‰è¾“å‡ºç«¯å£æœ‰å®žé™…é©±åŠ¨
   wire [31:0] reg_data;
assign disp_seg_o = U_DISP.seg;  // ç›´æŽ¥ç»‘å®šåˆ°å­æ¨¡å—è¾“å‡º
assign disp_an_o = U_DISP.an;
assign reg_data = U_SCPU.reg_data; // ç›´è¿žSCPUè¾“å‡º
   
   wire [31:0]    instr;
   wire [31:0]    PC;
   wire           MemWrite;
   wire [31:0]    dm_addr, dm_din, dm_dout;  
   wire rst = ~rstn_i;
    // æ—¶é’Ÿåˆ†é¢‘é€»è¾‘
    reg [31:0] clk_div;
    wire cpu_clk;
    always @(posedge clk) begin
        if (sw_i[15]) clk_div <= clk_div + 1;
        else clk_div <= 0;
    end
    assign cpu_clk = sw_i[15] ? clk_div[25] : clk;//clk_div15=3khz
    
    
  // instantiation of single-cycle CPU   
   SCPU U_SCPU(
         .clk(cpu_clk),                 // input:  cpu clock
         .reset(rst),                 // input:  reset
         .inst_in(instr),             // input:  instruction
         //.Data_in(dm_dout),        // input:  data to cpu  
         .Data_in(peripheral_data),
         .mem_w(MemWrite),       // output: memory write signal
         .PC_out(PC),                   // output: PC
         .Addr_out(dm_addr),          // output: address from cpu to memory
         .Data_out(dm_din),        // output: data from cpu to memory
         .reg_sel(reg_sel),         // input:  register selection
         .reg_data(reg_data)        // output: register data
         );
         
  // instantiation of data memory  
   dm    U_DM(
         .clk(clk),           // input:  cpu clock
         .DMWr(MemWrite),     // input:  ram write
         .addr(dm_addr[8:2]), // input:  ram address
         .din(dm_din),        // input:  data to ram
         .dout(dm_dout)       // output: data from ram
         );
         
  // instantiation of intruction memory (used for simulation)
   im    U_IM ( 
      .a(PC[8:2]),     // input:  rom address
      .spo(instr)        // output: instruction
   );
   reg [31:0] disp_reg; // æ•°ç ç®¡æ˜¾ç¤ºå¯„å­˜å™¨

    always @(posedge clk) begin
        if (MemWrite && dm_addr == 32'hFFFF000C)
            disp_reg <= dm_dout; // æ•èŽ·å†™å…¥æ•°ç ç®¡çš„æ•°æ®
    end

    // å¤–è®¾æ•°æ®è·¯ç”±
    //wire [31:0] peripheral_data;
    assign peripheral_data = 
        (dm_addr == 32'hFFFF0004) ? {16'b0, sw_i} : // å¼?å…³è¾“å…?
        (dm_addr == 32'hFFFF000C) ? disp_reg       : // æ•°ç ç®¡è¾“å‡?
        dm_dout;                                    // é»˜è®¤å­˜å‚¨å™¨æ•°æ?

    // æ–°å¢žæ•°ç ç®¡æ˜¾ç¤ºæŽ§åˆ?
    reg [31:0] display_value;

always @(*) begin
    if (sw_db[5]) begin
        // SW5=1ï¼šæ˜¾ç¤ºå¯„å­˜å™¨å€?
        display_value = reg_data;
    end else begin
        // SW5=0ï¼šæ ¹æ®SW[4:0]é€‰æ‹©æ˜¾ç¤ºå†…å®¹
        case (sw_db[4:0])
            5'b00000: display_value = (disp_reg != 0) ? disp_reg : 32'hAA5555AA;  // ä¸ƒæ®µæ•°ç ç®¡å†™å…¥å?¼ï¼ˆCPUå†™å…¥0xFFFF000Cï¼?
            5'b00001: display_value = PC >> 2;        // æŒ‡ä»¤ç¼–å·
            5'b00010: display_value = PC;             // æŒ‡ä»¤åœ°å€
            5'b00011: display_value = instr;          // æŒ‡ä»¤
            5'b00100: display_value = dm_addr;        // åœ°å€
            5'b00101: display_value = dm_din;         // å†™å…¥æ•°æ®
            5'b00110: display_value = dm_dout;        // è¯»å‡ºæ•°æ®
            5'b00111: display_value = dm_addr;        // å†æ¬¡åœ°å€
            5'b1????: display_value = 32'hFFFFFFFF;   // sw[4]=1æ—¶ç»Ÿä¸?å¤„ç†
            default:  display_value = 32'hAA5555AA;   // é»˜è®¤å€?
        endcase
    end
end

    // æ•°ç ç®¡é©±åŠ¨å®žä¾‹åŒ–
    seg7_display U_DISP(
        .clk(clk),
        .data(display_value),
        .seg(disp_seg_o),
        .an(disp_an_o)
    );      
endmodule
