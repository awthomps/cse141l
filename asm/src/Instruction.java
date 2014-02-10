import java.io.IOException;
import java.io.*;
import java.util.*;

/** This class is designed for storing each instruction's values. */
class Instruction
{
  /** This inner class contains each operand of a instruction,
  * which could be a label, a register or a constant.
  */
  class Operand
  {
    /** fields for storing the operand as a string for register,
    *   or label for labels or offset for instructions with offset
    */
    public String name;
    public String label;
    public int offset;
    
    /** the constructors, which initialize name and offset fields. */
    Operand()
    {
    name = "";
    offset = 0;
    }

    Operand(String i_name, int i_offset)
    {
    name = i_name;
    offset = i_offset;
    }
  
    /** registerNum method extracts the index of register or constant used 
    *  as a number indexing only the registers. If there is any problem 
    *  with the value it will return -1. 
    */ 
    public int registerNum ()
    {
    if (name.startsWith("$")&&(isNumber.isNumberH(name.substring(2)))){
      if ((name.charAt(1)=='r')||(name.charAt(1)=='R'))
        return Integer.parseInt(name.substring(2));
      else if ((name.charAt(1)=='c')||(name.charAt(1)=='C'))
        return (Integer.parseInt(name.substring(2))+32);
      else
        return -1;
      }
    else
      return -1;
    }
  
    /** imediateVal method extracts the number in immediate value. 
    *   If there is any problem with the value it will return -10000.
    *   (-1 could be the real value in the immediate).
    */ 
    public int immediateVal()
    { 
      if ((name.toLowerCase().startsWith("0x")&&(isNumber.isNumberH(name.substring(2))))
        ||(name.toLowerCase().startsWith("0x-")&&(isNumber.isNumberH(name.substring(3)))))
        return Integer.parseInt(name.substring(2),16); 
      else
        return -10000;
    }
  
    /** getOperandType returns the type of the operand */
    public String getOperandType()
    {
    if(name.startsWith("$"))
    {
      return "register";
    }
    else if(name.toLowerCase().startsWith("0x"))
    {
      return "immediate";
    }
    else if(name.startsWith("%"))
    {
      return "constant";
    }
    else
    {
      return "label";
    }
    }
  }

  /** Each instruction has one operator and several operands. */
	public String operator;
	public Operand operands[];
	
	/** constructor getting an operator in String and operands as 
  *   list of operand objects.
  */
  Instruction(String i_operator, Operand i_operands[])
	{
	  operator = i_operator;
	  operands = new Operand[i_operands.length];
	  for(int i=0;i<i_operands.length;i++)
	  {
	  operands[i] = new Operand();
	  operands[i].name = i_operands[i].name;
	  operands[i].offset = i_operands[i].offset;
    }
	}
	
  /** Constructor which get a line of code and extracts its instruction */
  Instruction(String sourceCodeLine)
	{
    StringTokenizer st = new StringTokenizer(sourceCodeLine," ,\t");
    int numberOfTokens = st.countTokens();
    if(numberOfTokens > 0) // The first argument is operator
    {
      operator=st.nextToken();
      //      System.out.println(operator);
      numberOfTokens--;
      operands = new Operand[numberOfTokens];
      for(int i = 0; i < numberOfTokens; i++)
      {
      operands[i] = new Operand();
      operands[i].name = st.nextToken();
      if(operands[i].name.lastIndexOf("(") >= 0)
      {
        operands[i].offset = Integer.valueOf(operands[i].name.substring(0,operands[i].name.lastIndexOf("("))).intValue();
        operands[i].name = operands[i].name.substring(operands[i].name.lastIndexOf("(")+1, operands[i].name.lastIndexOf(")"));
      }
      }
    }
	}
	  
  /** print method prints out the instruction for further debugging. */
	public void print()
	{
	  String output="";
	  for(int i=0;i<operands.length;i++)
	  {  
	  output += i+":"+operands[i].name+" "/*+operands[i].offset*/+"\t";
	  }
    System.out.println(operator+"\t"+output);
	}
	
}


