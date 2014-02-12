//	2009 Spring CSE 141 Project #1
//  Assembler Framework
//  Written by Hung-Wei Tseng
//
//  Modified for the Vanilla ISA by Moein Khazraee 2013

import java.io.IOException;
import java.io.*;
import java.util.*;

/** main calss of the Assembler */
public class vanillaAssembler
{
  
  /** main function which makes a new assmbler and calls its 
    * constructor with the input arguments from terminal.
    */
  public static void main(String[] args) throws IOException{
  vanillaAssembler asm = new vanillaAssembler(args);
		asm.AssembleCode(args);
	}

  /** constructor which gets the terminal inputs and make a readbuffer from input 
    * and a output buffer for the data memory file which is shared among kernels.
    */
  vanillaAssembler(String[] args) throws IOException
  {
  	if(args.length < 2)
  	{
  	  System.out.println("Usage: java Assembler input_filename output_file_prefix ");
  	  return;
  	}
    out_data   = new BufferedWriter(new FileWriter(args[1]+"_d.hex"));
  	sourceFile = new BufferedReader(new FileReader(args[0]));
  	if(args.length == 3)
      if (args[2].equals("debug"))
        debug = true;
  }

  /** file buffers */
  public BufferedWriter out_data;
  public BufferedReader sourceFile;
  /** keywords of the asseblemly language.*/
  public String[] keywords;
  /** memory table*/
  public Memory memory = new Memory();
  /** the current section of code (e.g text, data). */
  public int currentCodeSection = 0; // 0 for text, 1 for data
  /** The next data memory address */
  public int dataMemoryAddress = 0;
  /** The number of lines scanned */
  int currentSourceCodeline = 0;
  /** True if label replacement was successful */
  boolean isLabelReplaceSuccessful = true;
  /** current kernel index */
  public int kernel_num = -1 ;
  /** an arrayList of kernels */
  ArrayList<kernel> kernels = new ArrayList<kernel>();
  /** a pointer to current kernel. */
  kernel current_kernel;
	/** A symbol table for label -> address in data part */
	HashMap<String, Integer> dataLabelTable = new HashMap<String, Integer>(); 
  /** a variable which is set when debug argument is passed through terminal. */
  boolean debug = false; 
  /** instruction address requiring replacement with lbl pseudo instruction */
  ArrayList<Integer> pseudoRequiredAt = new ArrayList<Integer>();

  /** 
   * Get the next line from input file
   */
  public String getNextInputLine() throws IOException 
  {
  if(sourceFile == null)
    System.out.println("The source code file handler is not initialized");

  if(out_data == null)
    System.out.println("The output memory file handler is not initialized");

  	while(sourceFile.ready()) 
  	{
  	  currentSourceCodeline++;
  	  // get the next line. 
  	  String sourceCodeLine = sourceFile.readLine().trim();
  	  // get rid of the comments
  	  if(sourceCodeLine.startsWith("//"))
  	  {
  	  	continue;
    }
  	  if(sourceCodeLine.indexOf("//") != -1)
  	  {
  	  sourceCodeLine = sourceCodeLine.substring(0,sourceCodeLine.indexOf("//")).trim();
    }
    // trim the leading spaces and return the source code line.
    sourceCodeLine = sourceCodeLine.trim();
  	  /* remove the comments */
  	  if(sourceCodeLine.length() == 0)
  	  {
  	  	continue;
    }
  	  return sourceCodeLine;
  	}
  	  return null;
  }
  
  /** 
   * Check if the input line contains a keyword
   */
  boolean isKeyword(String sourceCodeLine)
  {
  if(sourceCodeLine.startsWith("."))
  return true;
  else
  return false;
  }

  /**
   * Extract the input line with the keywords stored in keywords array
   */
  String extractKeyword(String sourceCodeLine)
  {
  for(int i = 0; i< keywords.length; i++)
  {
  if(sourceCodeLine.startsWith(keywords[i]))
  {
    return keywords[i];
  }
  }
  outputErrorMessage("Hey! The line does not contain any keyword!");
  return null;
  }

  /**
   *check if the input contains a label
   */
  boolean isLabel(String sourceCode)
  {
    if(sourceCode.lastIndexOf(":") >= 0)
    return true;
    else
    return false;
  }
  
  /** 
   * extract the label from a source code input
   */
  String extractLabel(String sourceCode)
  {
    if(sourceCode.lastIndexOf(":") >= 0)
    {
    String label = sourceCode.substring(0,sourceCode.lastIndexOf(":"));
    if(label.length()!=0)
    return label;
    else
    return null;
    }
    else
    return null;
  }
  
  /**
   * process the instruction 
   */
  Instruction processInstruction(String sourceCode)
  {
    Instruction instruction = new Instruction(sourceCode);
   
    return instruction;
  }
  
  /**
   * process the data.
   */
  void processData(String sourceCode)
  {
  if(sourceCode.toLowerCase().startsWith(".word"))
  {
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    int numberOfRemainingTokens = st.countTokens();
    /* Fill the words into memory */
    while(numberOfRemainingTokens > 0)
    {
    numberOfRemainingTokens--;
    String data = st.nextToken();
    if(data.toLowerCase().startsWith(".word"))
    continue;
    if (data.toLowerCase().startsWith("0x")){
    int len = data.length();
    for (int i=0;i<10-len;i++)
      data="0x0"+data.substring(2); 
    }
    if ((dataMemoryAddress%4)!=0)
    dataMemoryAddress+=4-(dataMemoryAddress%4);
    memory.add(data, dataMemoryAddress,4);
    dataMemoryAddress+=4;
    }
  }
  /* Process the .fill keyword */
  else if(sourceCode.toLowerCase().startsWith(".fillword"))
  {
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    if(st.countTokens() !=3 )
    {
    outputErrorMessage("Error: .fill should be in the form of .fill n data");
    }
    String data = st.nextToken();
    if(data.toLowerCase().startsWith(".fill"))
    {
    int numberOfRemainingElements = Integer.valueOf(st.nextToken()).intValue();
    String dataToFill = st.nextToken();
    if (dataToFill.toLowerCase().startsWith("0x")){
    int len = dataToFill.length();
    for (int i=0;i<10-len;i++)
      data="0x0"+dataToFill.substring(2); 
    }
    for(int i = 0;i<numberOfRemainingElements;i++)
    {
    if ((dataMemoryAddress%4)!=0)
    dataMemoryAddress+=4-(dataMemoryAddress%4);
    memory.add(dataToFill, dataMemoryAddress,4);
    dataMemoryAddress+=4;
    }
    }
  }
  else if (sourceCode.toLowerCase().startsWith(".byte"))
  {
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    int numberOfRemainingTokens = st.countTokens();
    /* Fill the words into memory */
    while(numberOfRemainingTokens > 0)
    {
    numberOfRemainingTokens--;
    String data = st.nextToken();
    if(data.toLowerCase().startsWith(".byte"))
    continue;
    if (data.toLowerCase().startsWith("0x")){
    int len = data.length();
    for (int i=0;i<4-len;i++)
      data="0x0"+data.substring(2); 
    }
    else
    {
    outputErrorMessage("Label must be a word");
    return;
    }
    memory.add(data, dataMemoryAddress,1);
    dataMemoryAddress+=1;
    }
  }
  else if(sourceCode.toLowerCase().startsWith(".fillbyte"))
  {
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    if(st.countTokens() !=3 )
    {
    outputErrorMessage("Error: .fill should be in the form of .fill n data");
    }
    String data = st.nextToken();
    if(data.toLowerCase().startsWith(".fillbyte"))
    {
    int numberOfRemainingElements = Integer.valueOf(st.nextToken()).intValue();
    String dataToFill = st.nextToken();
    if (dataToFill.toLowerCase().startsWith("0x")){
    int len = dataToFill.length();
    for (int i=0;i<4-len;i++)
      data="0x0"+dataToFill.substring(2); 
    }
    else
    {
    outputErrorMessage("Label must be a word");
    return;
    }
 
    for(int i = 0;i<numberOfRemainingElements;i++)
    {
    memory.add(dataToFill, dataMemoryAddress,1);
    dataMemoryAddress+=1;
    }
    }
  }
  }

  /**
   * The static function returns the operand type.
   */
  public static String getOperandType(String operand)
  {
  if(operand.startsWith("$"))
  {
  return "register";
  }
  else if(operand.toLowerCase().startsWith("0x"))
  {
  return "immediate";
  }
  else if(operand.startsWith("%"))
  {
  return "constant";
  }
  else
  {
  return "label";
  }
  }

  /**
   * output an error message
   */
  public void outputErrorMessage(String errorMessage)
  {
  System.out.println("Line "+currentSourceCodeline+": "+errorMessage);
  }

  /**
   * processing the labels.
   */
	void processLabel(String label) {
		if (currentCodeSection == 0){
			if (current_kernel.memoryLabelTable.get(label)!=null)
    outputErrorMessage("label is used before");
    else
    	current_kernel.memoryLabelTable.put(label, current_kernel.instructionCount);
    }
		else if (currentCodeSection == 1){
			if (dataLabelTable.get(label)!=null)
    outputErrorMessage("label is used before");
			else
    dataLabelTable.put(label, dataMemoryAddress);
    }
	}

  /**
   * get the kernel corresponding to name
   */
  public int findKernel (String name){
  for (int i =0 ; i< kernels.size();i++)
    if (kernels.get(i).name.equals(name)){
    return i;
    }
  return -1;
  }
  

  /**
   * replacing the labels used in instruction
   */
	void replaceInstructionLabel(Instruction instruction) {
		Integer address = null;
		
		for(int i=0; i < instruction.operands.length; i++) {
			String currentOperandName = instruction.operands[i].name;
			String currentOperator = instruction.operator;
      
      
    if (currentOperandName.startsWith("%")){
    if (current_kernel.constNumber.get(currentOperandName.substring(1))!=null)
      instruction.operands[i].name = "$r"+ current_kernel.constNumber.get(currentOperandName.substring(1));
    else{
      outputErrorMessage(currentOperandName+" not found");
      return;
    }

    }
			else if(!(currentOperandName.startsWith("$") || 
					  currentOperandName.toLowerCase().startsWith("0x")||
      currentOperandName.startsWith("*") ||
      currentOperandName.startsWith("!") )) {
      int tempkernel = -1;
      if (currentOperandName.lastIndexOf(".")>=0)
      tempkernel = findKernel(currentOperandName.substring(0,currentOperandName.lastIndexOf(".")));
      if(tempkernel != -1)
					  address = kernels.get(tempkernel).memoryLabelTable.get(currentOperandName.substring(currentOperandName.lastIndexOf(".")+1));
      address = dataLabelTable.get(currentOperandName);
				  if (address == null) {
					  address = current_kernel.memoryLabelTable.get(currentOperandName);
					  // PC + offset addressing mode calculation
					  if (address == null){
        outputErrorMessage ("label not found");
        return;
      }
        
					  address -= current_kernel.programCounter; 
					  
					  // valid jump 6-bit immediate 
					  if (address <= 31 && address >= -31) {
					  	String prefix = (address < 0) ? "0x-" : "0x";
					  	address = (address < 0) ? address * -1 : address;
					  	instruction.operands[i].name = prefix + 
					  		Integer.toHexString(address);
					  }
					  else {
					  	/*
					  	 * The offset is larger than 6-bits and the assembler
					  	 * will notify which instructions require replacement
					  	 * with the label pseudo instruction
					  	 */
					  	isLabelReplaceSuccessful = false;
					  	pseudoRequiredAt.add(current_kernel.programCounter);
					  	instruction.operands[i].label = instruction.operands[i].name;
					  	instruction.operands[i].name = "000000";
					  }	
      }
      else
      {
      instruction.operands[i].name = "0x" + Integer.toHexString(address);
      }
    }
		}
	}

  /**
   * replacing the labels used in memory
   */
	void replaceMemoryLabel() {
		
		Integer address = null;
		
		for(int i = 0; i < memory.leng(); i++) {
			if(!memory.entries[i].data.toLowerCase().startsWith("0x")) {
				 int tempkernel = -1;
     if (memory.entries[i].data.lastIndexOf(".")>=0)
      tempkernel = findKernel(memory.entries[i].data.substring(0,memory.entries[i].data.lastIndexOf(".")));
     if(tempkernel != -1){
					 address = kernels.get(tempkernel).memoryLabelTable.get(memory.entries[i].data.substring(memory.entries[i].data.lastIndexOf(".")+1));
      }
     else
					 address = dataLabelTable.get(memory.entries[i].data);
     
     if (address == null) {
       address = current_kernel.memoryLabelTable.get(memory.entries[i].data);
				 }
     if (address == null) 
      System.out.println("Data Memory Label at "+i+" not found");
				 else{
      String temp = address.toString();
      int len=temp.length();
      for (int j=0;j<8-len;j++)
      temp="0"+temp;
      memory.entries[i].data = "0x" + temp; 
      }
			}
		}	
	}
  
  /**
   * TODO
   */
  void processAdditionalKeywords(String sourceCode)  
  {
  System.out.println("Keyword not found\n");
  }  

  /**
   * Extracts the number of the register in the operand.
   */
  int extractRegNum (String reg){
  if (reg.startsWith("$"))
    reg = reg.substring(1);
  if (!isNumber.isNumberD(reg.substring(1)))
    return (-1);
  if ((reg.charAt(0)=='c')||(reg.charAt(0)=='C'))
    return (32+Integer.parseInt(reg.substring(1)));
  else if ((reg.charAt(0)=='r')||(reg.charAt(0)=='R'))
    return (Integer.parseInt(reg.substring(1)));
  else
    return (-1);
  }

  /**
   * Process a register initializer keyword
   */
  void processRegister(String sourceCode) 
  {
  if (current_kernel==null){
    outputErrorMessage ("you must declare constants in a kernel");
    return;
  }
    
  if((sourceCode.toLowerCase().startsWith(".reg"))||(sourceCode.toLowerCase().startsWith(".constreg"))){
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    st.nextToken();
    //int numberOfRemainingTokens = st.countTokens();
    int number = extractRegNum(st.nextToken()); 
    if (number == -1){
    outputErrorMessage("Incorrect register");
    return;
    }
    if((sourceCode.toLowerCase().startsWith(".reg")&&(number>31))||(sourceCode.toLowerCase().startsWith(".constreg")&&(number<32))){
    outputErrorMessage("Inappropriate use of keyword");
    return;
    }
    if (current_kernel.regs[number].used){ 
    outputErrorMessage("Register $r"+number+"is used before");
    return;
    }
    
    else{
    String value = st.nextToken();
    if(value.toLowerCase().startsWith("0x"))
      current_kernel.regs[number].value = value.substring(2);
    else
      current_kernel.regs[number].value = Integer.toHexString(Integer.parseInt(value));
    current_kernel.regs[number].used = true;
    }
    }
  else if  (sourceCode.toLowerCase().startsWith(".const")){
    StringTokenizer st = new StringTokenizer(sourceCode," ,\t");
    st.nextToken();
    String name = st.nextToken();
    if (!(name.startsWith("%"))){
    outputErrorMessage("incorrect constant name");
    return;}
    name = name.substring(1);  
    String value = st.nextToken();
    int number;
    if (st.countTokens()==1){
    number = Integer.parseInt(st.nextToken())+32;
    if (current_kernel.regs[number].used){ 
      outputErrorMessage("Constant $c"+(number-32)+"is used before");
      return;
      }
    else
      current_kernel.regs[number].used = true;
    }
    else
    number = 0;
     
    if (current_kernel.constNumber.get(name)!=null){
    outputErrorMessage("Constant name is used before");
    return;
    }
		  current_kernel.constNumber.put(name, number);
		  current_kernel.constValue.put(name, value);
    }
  }

  /**
   * The core of our assembler */
  public void AssembleCode(String[] arg) throws IOException 
  {
	  if(arg.length < 2)
  	{
  	  return;
  	}
  	String keywordString = ".text .word .byte .data .fillbyte .fillword .reg .const .constreg .kernel";
  	keywords = keywordString.split(" ");
  	//Pass 1: Scan the source code line
  String sourceCodeLine = getNextInputLine();
  	while(sourceCodeLine != null) 
  	{
    if(isKeyword(sourceCodeLine))
  	  {
  	  /* Extract the keyword from scanned source code */
  	  String keyword = extractKeyword(sourceCodeLine);
  	  if(keyword == null)
  	  {
  	  outputErrorMessage("Error! It's not a valid keyword!");
  	  }
  	  else if (keyword.equalsIgnoreCase(".kernel"))
    {
    StringTokenizer st = new StringTokenizer(sourceCodeLine," ,\t");
    st.nextToken();
    int numberOfRemainingTokens = st.countTokens();
    if (numberOfRemainingTokens == 1){
      kernel temp = new kernel(arg[1],st.nextToken(),this);
      kernels.add(temp);
      kernel_num++;
      current_kernel = kernels.get(kernel_num);
    }
    else {
      outputErrorMessage("Inappropriate kernel name");
    }
    }
    /* Change the current code section to text */
  	  else if(keyword.equalsIgnoreCase(".text"))
  	  currentCodeSection = 0;
  	  /* Change the current code section to data */
    else if(keyword.equalsIgnoreCase(".data"))
    currentCodeSection = 1;
    else if(keyword.equalsIgnoreCase(".word") || keyword.equalsIgnoreCase(".fillword") || keyword.equalsIgnoreCase(".byte") || keyword.equalsIgnoreCase(".fillbyte"))
    {
    processData(sourceCodeLine); // Adds data to memory array
    }
    else if(keyword.equalsIgnoreCase(".reg") || keyword.equalsIgnoreCase(".const") || keyword.equalsIgnoreCase(".constreg"))
    {
    processRegister(sourceCodeLine); 
    }
    else
    {
    processAdditionalKeywords(sourceCodeLine);
    }
  	  }
  	  else if(isLabel(sourceCodeLine))
  	  {
  	  String label = extractLabel(sourceCodeLine); // Removes the semicolon terminating a label
  	  if(label != null){
  	  processLabel(label); // define this method w/ symbol table to maintain labels and their real address
    sourceCodeLine = sourceCodeLine.substring(sourceCodeLine.lastIndexOf(":")+1).trim();
    if (!(sourceCodeLine.equals("")))
      continue;
    }
    else{
    outputErrorMessage("The input line does not contains a label");
    }
  	  }
  	  else
  	  {
    if (current_kernel==null){
      outputErrorMessage ("you must enter code in a kernel");
      return;
    }
  	  	// If the current instruction is a Label pseudo instruction
  	  	if (sourceCodeLine.startsWith("!") || sourceCodeLine.startsWith("*")) {
  	  		for (int i = 0; i < 13; i++) {
  	  		  // adds instruction operator and operands list to the instruction array
      current_kernel.instructions[current_kernel.instructionCount] = processInstruction(sourceCodeLine);
      current_kernel.instructionCount++;
  	  		}
  	  	} else {
  	  		// adds instruction operator and operands list to the instruction array
      current_kernel.instructions[current_kernel.instructionCount] = processInstruction(sourceCodeLine);   	  		
      current_kernel.instructionCount++;
  	  	}
  	  }
    sourceCodeLine = getNextInputLine();
  }

  // Pass 2: Replace labels and output the code and memory.
  // output code
  for (int j=0; j < kernels.size(); j++){
    current_kernel=kernels.get(j);
    current_kernel.setConstants();
    //current_kernel.printregs();    
    current_kernel.outRegisters();
    for(int i=0; i < current_kernel.instructionCount; i++)
     {
     	 current_kernel.programCounter = i;
     replaceInstructionLabel(current_kernel.instructions[i]);	//  define replaces the label in an instruction with it's immediate value
     if (debug){
       System.out.print(i+": ");
       current_kernel.instructions[i].print();
     }
     String tempOutput = current_kernel.generateCode(current_kernel.instructions[i]); //  define replaces instruction object with machine code
     if(i < current_kernel.instructionCount-1)
     {
       current_kernel.out_code.write(tempOutput+"\n");
     }
     else
       current_kernel.out_code.write(tempOutput);
     }
  current_kernel.out_code.close();
  current_kernel.out_reg.close();
  current_kernel.out_info.close();
  }
  //memory.print();
  // replace labels in data field.
  replaceMemoryLabel();	//  define to replace labels used in data memory
  // output the memory states.
  if(isLabelReplaceSuccessful) {
	  out_data.write(memory.dump());
  }
  out_data.close();
  System.out.println((isLabelReplaceSuccessful)?"Finished Assembling" : 
					"!LABEL Instruction Required At:");
  }	
}
