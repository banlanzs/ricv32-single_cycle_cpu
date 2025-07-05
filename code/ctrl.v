`include "ctrl_encode_def.v"

module ctrl(
    input  [6:0] Op,
    input  [6:0] Funct7,
    input  [2:0] Funct3,
    input        Zero,

    output       RegWrite,
    output       MemWrite,
    output [5:0] EXTOp,
    output [4:0] ALUOp,
    output [2:0] NPCOp,
    output       ALUSrc,
    output [2:0] DMType,
    output [1:0] GPRSel,
    output [1:0] WDSel
);

    // --------------------
    // 指令类型识别
    // --------------------
    wire rtype   = (Op == 7'b0110011);
    wire itype   = (Op == 7'b0010011);
    wire itype_l = (Op == 7'b0000011);
    wire stype   = (Op == 7'b0100011);
    wire btype   = (Op == 7'b1100011);
    wire jal     = (Op == 7'b1101111);
    wire jalr    = (Op == 7'b1100111);
    wire lui     = (Op == 7'b0110111);
    wire auipc   = (Op == 7'b0010111);

    // --------------------
    // 功能指令识别
    // --------------------
    // R-type
    wire i_add  = rtype & (Funct3 == 3'b000) & (Funct7 == 7'b0000000);
    wire i_sub  = rtype & (Funct3 == 3'b000) & (Funct7 == 7'b0100000);
    wire i_sll  = rtype & (Funct3 == 3'b001);
    wire i_slt  = rtype & (Funct3 == 3'b010);
    wire i_sltu = rtype & (Funct3 == 3'b011);
    wire i_xor  = rtype & (Funct3 == 3'b100);
    wire i_srl  = rtype & (Funct3 == 3'b101) & (Funct7 == 7'b0000000);
    wire i_sra  = rtype & (Funct3 == 3'b101) & (Funct7 == 7'b0100000);
    wire i_or   = rtype & (Funct3 == 3'b110);
    wire i_and  = rtype & (Funct3 == 3'b111);

    // I-type
    wire i_addi  = itype & (Funct3 == 3'b000);
    wire i_slti  = itype & (Funct3 == 3'b010);
    wire i_sltiu = itype & (Funct3 == 3'b011);
    wire i_xori  = itype & (Funct3 == 3'b100);
    wire i_ori   = itype & (Funct3 == 3'b110);
    wire i_andi  = itype & (Funct3 == 3'b111);
    wire i_slli  = itype & (Funct3 == 3'b001) & (Funct7 == 7'b0000000);
    wire i_srli  = itype & (Funct3 == 3'b101) & (Funct7 == 7'b0000000);
    wire i_srai  = itype & (Funct3 == 3'b101) & (Funct7 == 7'b0100000);

    // Load
    wire i_lb  = itype_l & (Funct3 == 3'b000);
    wire i_lh  = itype_l & (Funct3 == 3'b001);
    wire i_lw  = itype_l & (Funct3 == 3'b010);
    wire i_lbu = itype_l & (Funct3 == 3'b100);
    wire i_lhu = itype_l & (Funct3 == 3'b101);

    // Store
    wire i_sb = stype & (Funct3 == 3'b000);
    wire i_sh = stype & (Funct3 == 3'b001);
    wire i_sw = stype & (Funct3 == 3'b010);

    // Branch
    wire i_beq  = btype & (Funct3 == 3'b000);
    wire i_bne  = btype & (Funct3 == 3'b001);
    wire i_blt  = btype & (Funct3 == 3'b100);
    wire i_bge  = btype & (Funct3 == 3'b101);
    wire i_bltu = btype & (Funct3 == 3'b110);
    wire i_bgeu = btype & (Funct3 == 3'b111);

    // --------------------
    // 控制信号输出
    // --------------------
    assign RegWrite = rtype | itype | itype_l | jal | jalr | lui | auipc;
    assign MemWrite = stype;
    assign ALUSrc   = itype | itype_l | stype | jalr | lui | auipc;

    assign EXTOp = 
        (itype & (Funct3 == 3'b001 || Funct3 == 3'b101)) ? `EXT_CTRL_ITYPE_SHAMT :
        itype | itype_l                                   ? `EXT_CTRL_ITYPE :
        stype                                              ? `EXT_CTRL_STYPE :
        btype                                              ? `EXT_CTRL_BTYPE :
        lui | auipc                                        ? `EXT_CTRL_UTYPE :
        jal                                                ? `EXT_CTRL_JTYPE :
        6'b000000;

    assign DMType = i_lh  ? `dm_halfword :
                    i_lhu ? `dm_halfword_unsigned :
                    i_lb  ? `dm_byte :
                    i_lbu ? `dm_byte_unsigned :
                    i_lw  ? `dm_word :
                    3'b000;

    assign GPRSel = `GPRSel_RD;

    assign WDSel = 
        itype_l               ? `WDSel_FromMEM :
        jal | jalr            ? `WDSel_FromPC  :
                                `WDSel_FromALU;

    assign NPCOp = 
        i_beq & Zero ? `NPC_BRANCH :
        jal          ? `NPC_JUMP   :
        jalr         ? `NPC_JALR   :
                       `NPC_PLUS4;

   assign ALUOp =
    lui     ? `ALUOp_lui   :
    auipc   ? `ALUOp_auipc :
    i_addi  ? `ALUOp_add   :
    i_slti  ? `ALUOp_slt   :
    i_sltiu ? `ALUOp_sltu  :
    i_xori  ? `ALUOp_xor   :
    i_ori   ? `ALUOp_or    :
    i_andi  ? `ALUOp_and   :
    i_slli  ? `ALUOp_sll   :
    i_srli  ? `ALUOp_srl   :
    i_srai  ? `ALUOp_sra   :
    i_add   ? `ALUOp_add   :
    i_sub   ? `ALUOp_sub   :
    i_sll   ? `ALUOp_sll   :
    i_slt   ? `ALUOp_slt   :
    i_sltu  ? `ALUOp_sltu  :
    i_xor   ? `ALUOp_xor   :
    i_srl   ? `ALUOp_srl   :
    i_sra   ? `ALUOp_sra   :
    i_or    ? `ALUOp_or    :
    i_and   ? `ALUOp_and   :
    btype   ? `ALUOp_sub   : // 比较类默认用减法
    auipc   ? `ALUOp_add   :
              `ALUOp_nop;

endmodule
