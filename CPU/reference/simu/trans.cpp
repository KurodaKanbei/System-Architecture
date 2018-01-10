#include<bits/stdc++.h>
using namespace std;

string str(int x,int len){
	string s;
	for(int i=len-1;i>=0;i--)
		s=s+char('0'+(x>>i&1));
	return s;
}

string bit_sel(string s,int r,int l){
	string ans;
	for(int i=r;i>=l;i--)
		ans+=s[s.length()-i-1];
	return ans;
}

int reg[33];

int mem[2333];

//#define OP_IMM 0010011
//#define OP_RRR 0110011


map<string,char>CMD_TYPE;
map<string,string>OP_FUN3;

int main(){

	freopen("instr.txt","r",stdin);
	freopen("instr.bin","w",stdout);

	CMD_TYPE["addi"]='I';
	CMD_TYPE["andi"]='I';
	CMD_TYPE["ori"]='I';
	CMD_TYPE["xori"]='I';

	CMD_TYPE["add"]='R';
	CMD_TYPE["sub"]='R';
	CMD_TYPE["and"]='R';
	CMD_TYPE["or"]='R';
	CMD_TYPE["xor"]='R';


	CMD_TYPE["beq"]='B';
	CMD_TYPE["bne"]='B';
	CMD_TYPE["blt"]='B';
	CMD_TYPE["bge"]='B';



	string instr;
	string rd;
	while(cin>>instr){
		int rd,rs1,rs2,imm;
		string cmd;
		if(instr=="auipc"){
			cin>>rd>>imm;
			cmd=str(imm,20)+str(rd,5)+string("0010111");
		}
		if(instr=="jal"){
			cin>>rd>>imm;
			cmd=str(imm,20)+str(rd,5)+string("1101111");
		}
		if(instr=="jalr"){
			cin>>rd>>rs1>>imm;
			cmd=str(imm,12)+str(rs1,5)+string("000")+str(rd,5)+string("1100111");
		}
		if(instr=="lui"){
			cin>>rd>>imm;
			cmd=str(imm,20)+str(rd,5)+string("0110111");
		}
		if(instr=="lw"){
			cin>>rd>>rs1>>imm;
			string FUN3="010";
			reg[rd]=mem[(reg[rs1]+imm)/4];
			cmd=str(imm,12)+str(rs1,5)+FUN3+str(rd,5)+string("0000011");
		}
		if(instr=="sw"){
			cin>>rs2>>rs1>>imm;
			mem[(reg[rs1]+imm)/4]=reg[rs2];
			string IM=str(imm,12);
			/*
			cerr<<IM.substr(0,7)<<endl;
			cerr<<str(rs2,5)<<endl;
			cerr<<str(rs1,5)<<endl;
			cerr<<"010"<<endl;
			cerr<<IM.substr(7,5)<<endl;
			cerr<<"0100011"<<endl;*/
			cmd=IM.substr(0,7)+str(rs2,5)+str(rs1,5)+"010"+IM.substr(7,5)+string("0100011");
		}
	
		if(CMD_TYPE[instr]=='I'){
			cin>>rd>>rs1>>imm;
			string FUN3;
			if(instr=="addi")reg[rd]=reg[rs1]+imm,FUN3="000";
			if(instr=="xori")reg[rd]=reg[rs1]^imm,FUN3="100";
			if(instr=="ori")reg[rd]=reg[rs1]|imm,FUN3="110";
			if(instr=="andi")reg[rd]=reg[rs1]&imm,FUN3="111";
			
			cmd=str(imm,12)+str(rs1,5)+FUN3+str(rd,5)+string("0010011");
		}
		if(CMD_TYPE[instr]=='R'){
			cin>>rd>>rs1>>rs2;
			string FUN3;
			string fun7=str(0,7);
			if(instr=="add")reg[rd]=reg[rs1]+reg[rs2],FUN3="000";
			if(instr=="sub")reg[rd]=reg[rs1]-reg[rs2],FUN3="000",fun7="0100000";
			if(instr=="xor")reg[rd]=reg[rs1]^reg[rs2],FUN3="100";
			if(instr=="or")reg[rd]=reg[rs1]|reg[rs2],FUN3="110";
			if(instr=="and")reg[rd]=reg[rs1]&reg[rs2],FUN3="111";
			cmd=fun7+str(rs2,5)+str(rs1,5)+FUN3+str(rd,5)+string("0110011");
		}
		
		if(CMD_TYPE[instr]=='B'){
			cin>>rs1>>rs2>>imm;
			string FUN3;
			string fun7=str(0,7);
			if(instr=="beq")FUN3="000";
			if(instr=="bne")FUN3="001";
			if(instr=="blt")FUN3="100";
			if(instr=="bge")FUN3="101";
			string IM=str(imm,13);
			cmd=bit_sel(IM,12,12)+bit_sel(IM,10,5)+str(rs2,5)+str(rs1,5)+FUN3+bit_sel(IM,4,1)+bit_sel(IM,11,11)+string("1100011");
		}
		
		cout<<cmd.substr(24,8)<<" "<<cmd.substr(16,8)<<" "<<cmd.substr(8,8)<<" "<<cmd.substr(0,8)<<endl;
	}

	cerr<<"trans done"<<endl;

//	for(int i=0;i<8;i++)
//		fprintf(stderr,"reg[%d]=%x\n",i,reg[i]);
//	for(int i=0;i<8;i++)
//		fprintf(stderr,"mem[%d]=%x\n",i,mem[i]);
	

	return 0;
}
