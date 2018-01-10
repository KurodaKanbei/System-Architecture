//#include "simulator.h"
#include <cassert>

enum Opcode
{
	LUI		= 0b0110111,
	AUIPC	= 0b0010111,
	JAL		= 0b1101111,
	JALR	= 0b1100111,
	BRANCH	= 0b1100011,
	LOAD	= 0b0000011,
	STORE	= 0b0100011,
	ALUI	= 0b0010011,
	ALU		= 0b0110011,
	FENCE	= 0b0001111
};

enum Funct3 : std::uint32_t
{
	EQ		= 0b000,
	NE		= 0b001,
	LT		= 0b100,
	GE		= 0b101,
	LTU		= 0b110,
	GEU		= 0b111,

	BYTE	= 0b000,
	HALF	= 0b001,
	WORD	= 0b010,
	BYTEU	= 0b100,
	HALFU	= 0b101,

	ADD		= 0b000,
	SLT		= 0b010,
	SLTU	= 0b011,
	XOR		= 0b100,
	OR		= 0b110,
	AND		= 0b111,
	SLL		= 0b001,
	SRL		= 0b101,
};

std::uint32_t & Simulator::getReg(std::uint32_t id)
{
	assert(id <= 32);
	static std::uint32_t zero;
	if (id == 0)
	{
		zero = 0;
		return zero;
	}
	return reg[id];
}

bool Simulator::branchCond(Funct3 funct3, std::uint32_t regRS1, std::uint32_t regRS2)
{
	switch (funct3)
	{
	case EQ:
		return regRS1 == regRS2;
	case NE:
		return regRS1 != regRS2;
	case LT:
		return std::int32_t(regRS1) < std::int32_t(regRS2);
	case GE:
		return std::int32_t(regRS1) >= std::int32_t(regRS2);
	case LTU:
		return regRS1 < regRS2;
	case GEU:
		return regRS1 >= regRS2;
	default:
		throw CPUException("Branch: Invalid Funct3");
	}
}

std::uint32_t Simulator::load(Funct3 funct3, std::uint32_t addr)
{
	addr_t readAddr = addr & ~0x3;
	std::uint32_t data = env->ReadMemory(readAddr);
	switch (funct3)
	{
	case BYTE:
		return std::int32_t(std::uint8_t((data >> 8 * (addr - readAddr)) & 0xff));
	case HALF:
		if (addr & 0x1)
			throw CPUException("Load Half: Misaligned data access not supported");
		return std::int32_t(std::uint16_t((data >> 8 * (addr - readAddr)) & 0xffff));
	case WORD:
		if (addr & 0x3)
			throw CPUException("Load Word: Misaligned data access not supported");
		return data;
	case BYTEU:
		return (data >> 8 * (addr - readAddr)) & 0xff;
	case HALFU:
		if (addr & 0x1)
			throw CPUException("Load Half Unsigned: Misaligned data access not supported");
		return (data >> 8 * (addr - readAddr)) & 0xffff;
	default:
		throw CPUException("Load: Invalid Funct3");
	}
}

void Simulator::store(Funct3 funct3, std::uint32_t addr, std::uint32_t data)
{
	addr_t writeAddr = addr & ~0x3;
	switch (funct3)
	{
	case BYTE:
		env->WriteMemory(writeAddr, data << 8 * (addr - writeAddr), 0x1 << (addr - writeAddr));
		break;
	case HALF:
		if (addr & 0x1)
			throw CPUException("Store Half: Misaligned data access not supported");
		env->WriteMemory(writeAddr, data << 8 * (addr - writeAddr), 0x3 << (addr - writeAddr));
		break;
	case WORD:
		if (addr & 0x3)
			throw CPUException("Store Word: Misaligned data access not supported");
		env->WriteMemory(addr, data, 0xf);
		break;
	default:
		throw CPUException("Store: Invalid Funct3");
	}
}

std::uint32_t Simulator::alu(Funct3 funct3, std::uint32_t op1, std::uint32_t op2, std::uint32_t funct7)
{
	switch (funct3)
	{
	case ADD:
		if (funct7)
			return op1 - op2;
		else
			return op1 + op2;
	case SLT:
		return std::int32_t(op1) < std::int32_t(op2);
	case SLTU:
		return op1 < op2;
	case XOR:
		return op1 ^ op2;
	case OR:
		return op1 | op2;
	case AND:
		return op1 & op2;
	case SLL:
		return op1 << op2;
	case SRL:
		if (funct7)
			return std::int32_t(op1) >> op2;
		else
			return op1 >> op2;
	default:
		throw CPUException("ALU: Invalid Funct3");
	}
}
void Simulator::RunInsn()
{
	std::uint32_t insn = env->ReadMemory(PC+PC_SHIFT);

	std::cerr<<"instr : ";
	for(int i=31;i>=0;i--)
		std::cerr<<(insn>>i&1);
	std::cerr<<std::endl;
	
	Opcode opcode = Opcode(insn & 0x7f);
	std::uint32_t rd = (insn >> 7) & 0x1f;
	Funct3 funct3 = Funct3((insn >> 12) & 0x7);
	std::uint32_t rs1 = (insn >> 15) & 0x1f;
	std::uint32_t rs2 = (insn >> 20) & 0x1f;
	std::uint32_t funct7 = insn >> 25;

	std::int32_t immI = std::int32_t(insn) >> 20;
	std::int32_t immS = rd | ((std::int32_t(insn) >> 25) << 5);
	std::int32_t immB = (((insn >> 8) & 0xf) << 1) | (((insn >> 25) & 0x3f) << 5) | (((insn >> 7) & 0x1) << 11) | ((std::int32_t(insn) >> 31) << 12);
	std::int32_t immU = insn & 0xfffff000;
	std::int32_t immJ = (((insn >> 21) & 0xf) << 1) | (((insn >> 25) & 0x3f) << 5) | (((insn >> 20) & 0x1) << 11) | (((insn >> 12) & 0xff) << 12) | ((std::int32_t(insn) >> 31) << 20);

	std::uint32_t &regRD = getReg(rd);
	std::uint32_t &regRS1 = getReg(rs1);
	std::uint32_t &regRS2 = getReg(rs2);

	switch (opcode)
	{
	case LUI:
		cerr<<"LUI"<<endl;
		cerr<<"rd="<<rd<<" "<<"imm="<<immU<<endl;
		regRD = immU;
		break;

	case AUIPC:
		cerr<<"AUIPC"<<endl;
		cerr<<"rd="<<rd<<" "<<"imm="<<immU<<endl;
		regRD = PC + immU;
		break;

	case JAL:
		cerr<<"JAL"<<endl;
		cerr<<"rd="<<rd<<" "<<"imm="<<immJ<<endl;
		regRD = PC + 4;
		PC = PC + immJ;
		if (PC & 0x3)
			throw CPUException("JAL: PC not aligned");
		return;

	case JALR:
		cerr<<"JALR"<<endl;
		cerr<<"rd="<<rd<<" "<<"imm="<<immJ<<endl;
		regRD = PC + 4;
		PC = (regRS1 + immI) & ~0x1;
		if(PC & 0x3)
			throw CPUException("JALR: PC not aligned");
		return;

	case BRANCH:
	{
		cerr<<"BRANCH"<<endl;
		cerr<<"rs1="<<rs1<<" rs2="<<rs2<<" fun3="<<funct3<<" imm="<<immB<<endl;
		bool cond = branchCond(funct3, regRS1, regRS2);
		if (cond)
		{
			PC = PC + immB;
			if (PC & 0x3)
				throw CPUException("BRANCH: PC not aligned");
			return;
		}
		break;
	}

	case LOAD:
		cerr<<"LOAD"<<endl;
		cerr<<"rd="<<rd<<" fun3="<<funct3<<" rs1="<<rs1<<" imm="<<immI<<endl;
		regRD = load(funct3, regRS1 + immI);
		break;

	case STORE:
		cerr<<"STORE"<<endl;
		cerr<<"rs2="<<rs2<<" fun3="<<funct3<<" rs1="<<rs1<<" imm="<<immS<<endl;
		store(funct3, regRS1 + immS, regRS2);
		break;

	case ALUI:
		cerr<<"ALUI"<<endl;
		if (funct3 == SLL || funct3 == SRL){
			cerr<<"rd="<<rd<<" fun3="<<funct3<<" rs1="<<rs1<<" "<<"rs2="<<rs2<<endl;
			regRD = alu(funct3, regRS1, rs2, funct7);
		}
		else{
			regRD = alu(funct3, regRS1, immI, 0);
			cerr<<"rd="<<rd<<" fun3="<<funct3<<" rs1="<<rs1<<" "<<"imm="<<immI<<endl;
		}	
		break;

	case ALU:
		cerr<<"ALU"<<endl;
		regRD = alu(funct3, regRS1, regRS2, funct7);
		cerr<<"rd="<<rd<<" fun3="<<funct3<<" rs1="<<rs1<<" "<<"rs2="<<rs2<<" fun7="<<funct7<<endl;
		break;

	case FENCE:
		break;

	default:
		//cerr<<"inv"<<endl;
		throw CPUException("Invalid Opcode");
	}

	PC += 4;
}
