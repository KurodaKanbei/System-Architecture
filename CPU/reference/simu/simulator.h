
enum Funct3 : std::uint32_t;

using namespace std;
typedef std::uint32_t addr_t;
typedef std::uint32_t data_t;
const addr_t addrInput = 0x100;
const addr_t addrOutput = 0x104;
const addr_t addrFinish = 0x108;
const addr_t addrHighMem = 0x1000;

const int PC_SHIFT=0;//4096*16;
string ww;
class IEnvironment{
public:
	IEnvironment(){
		is_running=0;
		is_timing=0;
		verbose=0;
	}
	bool is_running, is_timing;
	bool verbose;
	std::vector<std::uint8_t> memory;

	std::istream *ioIn;
	std::ostream *ioOut;
	
	data_t ReadMemory(addr_t addr)
	{
		
		if (addr & 0x3){
			cerr<<"throw AddressUnalignedException(addr, false)"<<endl;;
		}
		if (addr >= memory.size()){
			cerr<<"throw AddressOutofRangeException(addr, false)"<<endl;
		}
		data_t data = memory.at(addr) |
			(memory.at(addr + 1) << 8) |
			(memory.at(addr + 2) << 16) |
			(memory.at(addr + 3) << 24);
	
		if (addr == addrInput)
		{
			if (!(*ioIn))
			{
				logWarn("Input EOF reached");
				data = 0xffffffff;
			}
			else
			{
				char rbuf;
				ioIn->read(&rbuf, 1);
				data = std::uint8_t(rbuf);
			}
		}
		else if (addr == addrOutput)
			logWarn("Trying to read the output port");
	
		if(data)logDebug(string("Read Memory ") +to_string(addr) +" "+ to_string(data));
	
		return data;
	}
	
	void WriteMemory(addr_t addr, data_t data, int mask)
	{
		if(addr & 0x3)
			cerr<<" AddressUnalignedException(addr, true) " <<endl;
		if (addr >= memory.size())
			cerr<<" AddressOutofRangeException(addr, true) " <<endl;
	
	//	logDebug(format("Write Memory\t0x%08x: %08x, mask=%x") % addr % data % mask);
		logDebug(string("Write Memory ") +to_string(addr) +" "+ to_string(data)+" "+to_string(mask));
		if (addr == addrInput)
		{
			logWarn("Trying to write input port");
			return;
		}
		else if (addr == addrOutput)
		{
			if (mask & 0x1)
			{
				
				char wbuf = char(data & 0xff);
				ww+=char(data & 0xff);
				ioOut->write(&wbuf, 1);
			}
			else
				logWarn("Trying to write output port but the mask doesn't include the lowest bit");
			return;
		}
		else if (addr == addrFinish)
		{
			if ((mask & 0x1) && (data & 0xff) == 0xff)
			{
				is_running = false;
			}
			return;
		}
		else if (addr < addrHighMem)
		{
			logWarn("Trying to write low memory");
			return;
		}
	
		if (mask & 0x1){
			memory.at(addr) = data & 0xff;
			std::cerr<<"try at "<<addr<<" "<<(int)data<<std::endl;
		}
		if (mask & 0x2)
			memory.at(addr + 1) = (data >> 8) & 0xff;
		if (mask & 0x4)
			memory.at(addr + 2) = (data >> 16) & 0xff;
		if (mask & 0x8)
			memory.at(addr + 3) = (data >> 24) & 0xff;
	}


	template<typename T, typename ...Tother>
	void log_impl(T &&arg, Tother &&...other)
	{
		std::cerr << std::forward<T>(arg);
		log_impl(std::forward<Tother>(other)...);
	}
	void log_impl() {}

	template<typename ...T>
	void log(T &&...args)
	{
		if (is_timing)
		{
				
		}
		else
			std::cerr << "[---] ";
		log_impl(std::forward<T>(args)...);
		std::cerr << std::endl;
	}

	template<typename ...T>
	void logError(T &&...args)
	{
		log("[ERROR] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logWarn(T &&...args)
	{
		log("[WARN] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logInfo(T &&...args)
	{
		log("[INFO] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logDebug(T &&...args)
	{
		if (verbose)
		{
			log("[DEBUG] ", std::forward<T>(args)...);
		}
	}
};

class Simulator
{
public:
	class CPUException : public std::exception
	{
	public:
		std::string description;
		CPUException(std::string str) : description(std::move(str)) {}

		const char *what() const noexcept
		{
			return description.c_str();
		}
	};
public:
	Simulator() : env(nullptr), PC(0) {}

	void RunInsn();
	void setEnvironment(IEnvironment *env) { this->env = env; }

public:
	std::uint32_t & getReg(std::uint32_t id);
	bool branchCond(Funct3 funct3, std::uint32_t regRS1, std::uint32_t regRS2);
	std::uint32_t load(Funct3 funct3, std::uint32_t addr);
	void store(Funct3 funct3, std::uint32_t addr, std::uint32_t data);
	std::uint32_t alu(Funct3 funct3, std::uint32_t op1, std::uint32_t op2, std::uint32_t funct7);

public:
	IEnvironment *env;

	std::uint32_t reg[32];
	std::uint32_t PC;
};

