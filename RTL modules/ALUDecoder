module RISC_V_Pipeline_ALUDecoder (
    input  logic       Opcode_5,
    input  logic [1:0] ALUOp,
    input  logic [2:0] funct3,
    input  logic       funct7_5,

    output logic [2:0] ALUControl
);

    always_comb begin
        case (ALUOp)

            2'b00: begin
                ALUControl = 3'b000;
            end

            2'b01: begin
                ALUControl = 3'b001;
            end

            default: begin
                case (funct3)

                    3'b000: begin
                        if ((Opcode_5 == 1'b1) && (funct7_5 == 1'b1))
                            ALUControl = 3'b001;
                        else
                            ALUControl = 3'b000;
                    end

                    3'b010: begin
                        ALUControl = 3'b101;
                    end

                    3'b110: begin
                        ALUControl = 3'b011;
                    end

                    3'b111: begin
                        ALUControl = 3'b010;
                    end

                    default: begin
                        ALUControl = 3'b000;
                    end

                endcase
            end

        endcase
    end

endmodule
