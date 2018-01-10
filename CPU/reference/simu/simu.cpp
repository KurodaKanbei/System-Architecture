#include<bits/stdc++.h>
#include "simulator.h"
#include "simulator.cpp"
using namespace std;
Simulator simu;

map<char,int>num;
char to_byte(string s){
	return num[s[1]]+num[s[0]]*16;
}
int to_int(string s){
	int x=0;
	for(int i=0;i<s.length();i++)
		x=(x<<1) | (s[i]-'0');
	return x;
}
char bit_rev(char c){
	char ans=0;
	for(int i=0;i<8;i++)
		ans|=(c>>i&1)<<(7-i);
	return ans;
}

int main(){

	num['0']=0;
	num['1']=1;
	num['2']=2;
	num['3']=3;
	num['4']=4;
	num['5']=5;
	num['6']=6;
	num['7']=7;
	num['8']=8;
	num['9']=9;
	num['a']=10;
	num['b']=11;
	num['c']=12;
	num['d']=13;
	num['e']=14;
	num['f']=15;
	
	IEnvironment env;
	env.is_running=1;
	env.is_timing=1;
	env.verbose=1;
	
	env.memory.resize(1024*256);
	
	env.ioIn=new ifstream("haha.in");
	env.ioOut=new ofstream("haha.out");
	
	
	//freopen("instr.bin","r",stdin);
	freopen("test.in","r",stdin);
	freopen("test.txt","w",stdout);
	string instr1;
	string instr2;
	string instr3;
	string instr4;
	
	vector<char>ins_mem;
	while(cin>>instr1>>instr2>>instr3>>instr4){
	//	if(instr=="00000000")continue;
		//cerr<<instr1<<" "<<instr2<<" "<<instr3<<" "<<instr4<<endl;
		ins_mem.push_back(to_byte(instr1));
		ins_mem.push_back(to_byte(instr2));
		ins_mem.push_back(to_byte(instr3));
		ins_mem.push_back(to_byte(instr4));
		
		/*ins_mem.push_back(to_int(instr1));
		ins_mem.push_back(to_int(instr2));
		ins_mem.push_back(to_int(instr3));
		ins_mem.push_back(to_int(instr4));*/
		/*
		ins_mem.push_back(to_int(instr.substr(24,8)));
		ins_mem.push_back(to_int(instr.substr(16,8)));
		ins_mem.push_back(to_int(instr.substr(8,8)));
		ins_mem.push_back(to_int(instr.substr(0,8)));
		*/
		/*ins_mem.push_back(to_byte(instr.substr(0,2)));
		ins_mem.push_back(to_byte(instr.substr(2,2)));
		ins_mem.push_back(to_byte(instr.substr(4,2)));
		ins_mem.push_back(to_byte(instr.substr(6,2)));*/
	}
	for(int i=0;i<ins_mem.size();i++){
		env.memory[i+PC_SHIFT]=ins_mem[i];
	}
	
	simu.setEnvironment(&env);
	int T=0,i=0;
	while(simu.PC<ins_mem.size()){
		cerr<<"PC="<<simu.PC<<endl;
		simu.RunInsn();	
		if(i++>50)break;
	}
	/*while(simu.PC<ins_mem.size()){
		simu.PC=i*4;
		if(!simu.env->ReadMemory(simu.PC+PC_SHIFT)){
			i++;
			continue;
		}	
		if(157==simu.env->ReadMemory(simu.PC+PC_SHIFT)){
			i++;
			continue;
		}
		 
		//cerr<<"PC = "<<simu.PC<<endl;
		simu.RunInsn();	
		if(i++>1000)break;
	}
	cerr<<"kkdsaf"<<endl;
	*/
	//env.ioOut->close();
	
	for(int i=0;i<8;i++)
		fprintf(stderr,"reg[%d]=%d\n",i,simu.getReg(i));
		
		
	for(int i=0;i<32;i++)
		fprintf(stderr,"mem[4096+%d]=%d\n",i,env.memory[4096+i]);
	
	env.ioOut->flush();
	delete env.ioIn;
	delete env.ioOut;
	
//	for(int i=0;i<1024*4;i++)if(env.memory[i])
//		fprintf(stderr,"mem[%d]=%c\n",i,bit_rev(env.memory[i]));
	
	cerr<<ww<<endl;
	cerr<<addrHighMem<<endl;
	return 0;
}
