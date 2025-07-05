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
    input  [15:0]  sw_i,       // 新增�?16位开关输�?
    //input  [4:0]   reg_sel,
    output [7:0]   disp_seg_o, // 新增：数码管段�??
    output [7:0]   disp_an_o // 新增：数码管位�??
    //output [31:0]  reg_data    // 保留：寄存器调试输出
);
   
   // ---- 实例化消抖模�? ----
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
   // 确保�?有输出端口有实际驱动
   wire [31:0] reg_data;
assign disp_seg_o = U_DISP.seg;  // 直接绑定到子模块输出
assign disp_an_o = U_DISP.an;
assign reg_data = U_SCPU.reg_data; // 直连SCPU输出
   
   wire [31:0]    instr;
   wire [31:0]    PC;
   wire           MemWrite;
   wire [31:0]    dm_addr, dm_din, dm_dout;  
   wire rst = ~rstn_i;
    // 时钟分频逻辑
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
   reg [31:0] disp_reg; // 数码管显示寄存器

    always @(posedge clk) begin
        if (MemWrite && dm_addr == 32'hFFFF000C)
            disp_reg <= dm_dout; // 捕获写入数码管的数据
    end

    // 外设数据路由
    //wire [31:0] peripheral_data;
    assign peripheral_data = 
        (dm_addr == 32'hFFFF0004) ? {16'b0, sw_i} : // �?关输�?
        (dm_addr == 32'hFFFF000C) ? disp_reg       : // 数码管输�?
        dm_dout;                                    // 默认存储器数�?

    // 新增数码管显示控�?
    reg [31:0] display_value;

always @(*) begin
    if (sw_db[5]) begin
        // SW5=1：显示寄存器�?
        display_value = reg_data;
    end else begin
        // SW5=0：根据SW[4:0]选择显示内容
        case (sw_db[4:0])
            5'b00000: display_value = (disp_reg != 0) ? disp_reg : 32'hAA5555AA;  // 七段数码管写入�?�（CPU写入0xFFFF000C�?
            5'b00001: display_value = PC >> 2;        // 指令编号
            5'b00010: display_value = PC;             // 指令地址
            5'b00011: display_value = instr;          // 指令
            5'b00100: display_value = dm_addr;        // 地址
            5'b00101: display_value = dm_din;         // 写入数据
            5'b00110: display_value = dm_dout;        // 读出数据
            5'b00111: display_value = dm_addr;        // 再次地址
            5'b1????: display_value = 32'hFFFFFFFF;   // sw[4]=1时统�?处理
            default:  display_value = 32'hAA5555AA;   // 默认�?
        endcase
    end
end

    // 数码管驱动实例化
    seg7_display U_DISP(
        .clk(clk),
        .data(display_value),
        .seg(disp_seg_o),
        .an(disp_an_o)
    );      
endmodule
