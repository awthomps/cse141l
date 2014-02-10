import java.io.IOException;
import java.io.*;
import java.util.*;

/** kernel class stores instructions and labels and register values for each kernel.
  * Moreover, it prodeuces the required binary forms and output hex files.
  */
class kernel{
    
   
    /** RegValues is a inner class for storing values and name of constants and registers
      * used for initializing registers in vanilla core.
      */
    class RegValues
    {
        /** used field is used to determine which registers are used, for assigning 
          * a register to each constant value label.
          */
        public boolean used;
        /** value field stores the value of the constant which could be a label at first. */
        public String value;

        /** constructor for initializing the registers to not used and empty. */
        RegValues()
        {
            used = false;
            value = "";
        }
    }

    /** fields for outputting .hex files. */
    public BufferedWriter out_code, out_reg, out_info;
    /** field for storing instructions */
    public Instruction instructions[] = new Instruction[1024];
    /** number of scanned instructions */
    public int instructionCount = 0;
    /** The next program counter */
    public int programCounter = 0;
    /** To store the register values */
    public RegValues[] regs = new RegValues[64];
    /** name of the kernel. */
    public String name;
    
    /** Hash map for constant label names to the destination register and its value. */ 
    HashMap<String, Integer> constNumber = new HashMap<String, Integer>();	
    HashMap<String, String> constValue = new HashMap<String, String>();	
	  
    /** A hash map for labels in the code part. */
    HashMap<String, Integer> memoryLabelTable = new HashMap<String, Integer>(); 
	  
    /** A hash map for opcodes table in binary. */
    static HashMap<String, String> opcodeTable = new HashMap<String, String>();
    /** a pointer to the covering assembler object for using its data memory labels. */
    private vanillaAssembler Assembler;
   	
    /** constructor which gets the kernel name and pointer to the covering assembler,
      * and makes output .hex files and sets the name and assembler fields.
      */
    kernel(String file_name, String kernel_name,vanillaAssembler Assem) throws IOException{
    	for (int i=0;i<64;i++)
            regs[i] = new RegValues();
        name = kernel_name;
        out_code = new BufferedWriter(new FileWriter(kernel_name+"_i.hex"));
        out_reg  = new BufferedWriter(new FileWriter(kernel_name+"_r.hex"));
        out_info = new BufferedWriter(new FileWriter(kernel_name+"_info.txt"));
        Assembler = Assem;
    	initialization();
    }

    /** An enumuration for opcodes */
    public static enum opcodes {
		ADDU, SUBU, SLLV, SRAV, SRLV, AND, OR, NOR, SLT, SLTU, MOV, LW, LBU, SW, SB, JALR,
        BEQZ, BNEQZ, BGTZ, BLTZ,
        DONE, BAR, NOTVALID;
  
    /** gets an String as opcode and outputs the corresponding opcode in form of the used enumeration. */
		public static opcodes toOpcode(String str)
		{
			try{
				return valueOf(str);
			}
			catch (Exception ex) {
				return NOTVALID;
			}
		}
	}
	

	/** initialize opcode table */
	public static void initialization() throws IOException {
		opcodeTable.put("ADDU" , "00000");
		opcodeTable.put("SUBU" , "00001");
		opcodeTable.put("SLLV" , "00010");
		opcodeTable.put("SRAV" , "00011");
		opcodeTable.put("SRLV" , "00100");
		opcodeTable.put("AND"  , "00101");
		opcodeTable.put("OR"   , "00110");
		opcodeTable.put("NOR"  , "00111");
		opcodeTable.put("SLT"  , "01000");
		opcodeTable.put("SLTU" , "01001");
		opcodeTable.put("JALR" , "10111");
		opcodeTable.put("MOV"  , "01010");
		opcodeTable.put("LW"   , "11000");
		opcodeTable.put("LBU"  , "11001");
		opcodeTable.put("SW"   , "11010");
		opcodeTable.put("SB"   , "11011");
		opcodeTable.put("BEQZ" , "10000");
		opcodeTable.put("BNEQZ", "10001");
		opcodeTable.put("BGTZ" , "10010");
		opcodeTable.put("BLTZ" , "10011");
		opcodeTable.put("DONE" , "01100");
		opcodeTable.put("BAR"  , "01100");
	}



  /** Converts the intrucion to binary machine code. */
	String generateCode(Instruction instruction) {
        String operator = instruction.operator.toUpperCase();
		String temp;
		int tempInt;
		StringBuilder mc = new StringBuilder();
    	int len;	
		// all instructions start with an opcode
		mc.append(opcodeTable.get(operator));
		
		switch(opcodes.toOpcode(operator)) {
			case ADDU:
	        case SUBU:
			case SLLV:
			case SRAV:
			case SRLV:
            case AND:
            case OR:
            case NOR: 
            case SLT:
            case SLTU:
            case JALR:
            case LW:
            case LBU:
            case SW:
            case SB:
            case MOV:
				if (instruction.operands.length!=2){
                    System.out.println("invalid number of operands in the following instruction");
                    instruction.print();
                    return "";
                }   
                tempInt = instruction.operands[0].registerNum();
				if (tempInt == -1){
                    System.out.println("incorrect register value for operand 0 in the following instruction");
                    instruction.print();
                    return "";
                }
                temp = Integer.toBinaryString(tempInt);
                len = temp.length();
				for (int i = 0; i < 5 - len; i++) 
					mc.append("0");
				mc.append((temp.length() > 5) ? 
					    temp.substring(temp.length()-5,temp.length()) : temp);
            	
                tempInt = instruction.operands[1].registerNum();	
				if (tempInt == -1){
                    System.out.println("incorrect register value for operand 1 in the following instruction");
                    instruction.print();
                    return "";
                }
				temp = Integer.toBinaryString(tempInt);
                len = temp.length();
				for (int i = 0; i < 6 - len; i++) 
					mc.append("0");
				mc.append((temp.length() > 6) ? 
					    temp.substring(temp.length()-6,temp.length()) : temp);
				break;
            
            case BEQZ:
			case BNEQZ:
			case BGTZ:
			case BLTZ:
				if (instruction.operands.length!=2){
                    System.out.println("invalid number of operands in the following instruction");
                    instruction.print();
                    return "";
                }   
       			tempInt = instruction.operands[0].registerNum();
				if (tempInt == -1){
                    System.out.println("incorrect register value in the following instruction");
                    instruction.print();
                    return "";
                }
				temp = Integer.toBinaryString(tempInt);
                len = temp.length();
				for (int i = 0; i < 5 - len; i++) 
					mc.append("0");
				mc.append((temp.length() > 5) ? 
					    temp.substring(temp.length()-5,temp.length()) : temp);
            	
                tempInt = instruction.operands[1].immediateVal();
				if (tempInt == -10000){
                    System.out.println("incorrect immediate value in the following instruction");
                    instruction.print();
                    return "";
                }
				temp = Integer.toBinaryString(tempInt);
                len = temp.length();
				for (int i = 0; i < 6 - len; i++) 
					mc.append("0");
				mc.append((temp.length() > 6) ? 
						temp.substring(temp.length()-6,temp.length()) : temp);
				break;	

		    case BAR:
				if (instruction.operands.length!=1){
                    System.out.println("invalid number of operands in the following instruction");
                    instruction.print();
                    return "";
                }   
				mc.append("10000");
			    tempInt = instruction.operands[0].registerNum();	
				if (tempInt == -1){
                    System.out.println("incorrect register value in the following instruction");
                    instruction.print();
                    return "";
                }
				temp = Integer.toBinaryString(tempInt);
                len = temp.length();
				for (int i = 0; i < 6 - len; i++) 
					mc.append("0");
				mc.append((temp.length() > 6) ? 
					    temp.substring(temp.length()-6,temp.length()) : temp);
                
                break;

			case DONE:
				if (instruction.operands.length!=0){
                    System.out.println("invalid number of operands in the following instruction");
                    instruction.print();
                    return "";
                }   
                mc.append("00000000000");
				break;

			case NOTVALID:
                            System.out.println("Invalid operator: " + instruction.operator);
                            System.exit(-1);
                            break;
			default:
				return null;
		}
		tempInt = Integer.parseInt(mc.toString(), 2);
		temp = Integer.toHexString(tempInt);
		mc = new StringBuilder();
		//mc.append("0");//Making instructions 17 bits
		for (int i = 0; i < 4 - temp.length(); i++)
			mc.append("0");
		mc.append(temp);
		temp = mc.toString().toUpperCase();
		return temp;
	}
    
  /** updates the program counter. */
	void updateProgramCounter(Instruction instruction) {
		programCounter++;	
	}  

    /** setConstants computes value of each register, based on labels and constant valuess.
      * and outputs the info file which indicates each constant is mapped to which register,
      * for further debugging.
      */
    void setConstants() throws IOException{
        String value;
        int free = 32;
        int number;
        Integer address= null;
        for (String name : constNumber.keySet()){
            value = constValue.get(name);
            number = constNumber.get(name);       
            if (value.toLowerCase().startsWith("0x"))
                value=value.substring(2);
            else if (isNumber.isNumberD(value))
                value=Integer.toHexString(Integer.parseInt(value));
            else{
    			address = Assembler.dataLabelTable.get(value);
				if (address == null) 
					address = memoryLabelTable.get(value);
                if (address == null){
                    System.out.println("label "+value+" not found");
                }
                else
                    value=Integer.toHexString(address);
            }
            if (number!=0)
                regs[number].value=value;
            else{
                while (regs[free].used){
                    free++;}
                if (free>63){
                    System.out.println("constant overload in kernel "+name);
                    return;}
                else{
                    regs[free].used = true;
                    regs[free].value = value;
                    out_info.write("$r"+free+" used for "+name+"\n");
                    constNumber.put(name,free);
                    }
            }    
        }
        for (int i = 1 ; i<64 ; i++)
            if (regs[i].value!=""){
                int len = regs[i].value.length();
                for (int j=0;j<8-len;j++)
                    regs[i].value="0"+regs[i].value;
                    }
    } 
  
    /** printregs prints out the register values for further debugging. */
    void printregs(){
        for (int i=0 ; i<64; i++)
            System.out.println ("reg["+i+"]= "+regs[i].value);
    }   

    /** outRegisters outputs the register values to .hex file. */
    void outRegisters() throws IOException{
        for (int i=0;i<63;i++){
		    String temp = Integer.toHexString(i);
            for (int j = 0; j < 2 - temp.length(); j++)
			    temp="0"+temp;
            if (regs[i].value=="")
                temp+="00000000";
            else
                temp+=(regs[i].value);
            out_reg.write(temp+"\n");
        }
        String temp = Integer.toHexString(63);
        for (int j = 0; j < 2 - temp.length(); j++)
			temp="0"+temp;
        if (regs[63].value=="")
            temp+="00000000";
        else
            temp+=(regs[63].value);
        out_reg.write(temp);
    }
  
}


