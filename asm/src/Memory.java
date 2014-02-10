import java.io.IOException;
import java.io.*;
import java.util.*;

/** Memory class stores values for data memory. */
class Memory
{

  /** MemoryEntry is inner class of Memory class which has 
  * the required fields for each data.
  */
  class MemoryEntry
  {
    /** data field which stores the data value or the label. */
    String data;
    /** address field stores the address of the memory entry. */
    int address;
    /** length field indicates if the data is a byte or word. */ 
    int length;
  }

  /** indicates the size of data memory. */
	int size,j;
  /** a list of data memory entries for storing the values. */
	MemoryEntry[] entries;

  /** default constructor considering memory size of 4KB. */
	Memory()	
	{
	  entries = new MemoryEntry[4096];
	  for(int j=0;j<4096;j++)
	    entries[j] = new MemoryEntry();
		size=0;
	}

  /** constructor which gets the size of data memory. */
	Memory(int n)
	{
	  entries = new MemoryEntry[n];
	  for(int j=0;j<n;j++)
	    entries[j] = new MemoryEntry();
		size=0;
	}

  /** add method puts the new value in the next memory entry. */
	public void add(String data,int address,int length)
	{
	  entries[size].data = data;
	  entries[size].length = length;
	  entries[size++].address = address;
	}

  /** find method returns the value stored in an address. */
	public String find(int address)
	{
		for(j=0;j<size;j++)
			if(address == entries[j].address)
				return entries[j].data;
		return null;		
  }

  /** print method prints every entries of the memory, for further debugging. */
	public void print()
	{
		for(j=0;j<size;j++)
			System.out.println(Integer.toHexString(entries[j].address)+"\t"+entries[j].data);
	}

  /** dump method merges all the entris in one signle String to be written to output file,
  *   in addition it inserts zero values to adjust the addresses in word sizes.
  */
	public String dump()
	{
    int bytecounter = 0;
    String output="";
    String buffer="";
		for(j=0;j<size;j++)
		{
      String tempOutput = entries[j].data.substring(entries[j].data.lastIndexOf("0x")+2,entries[j].data.length()); 
		  if (entries[j].length==4)
        if(j<size-1)
	  		output+=tempOutput+"\n";
        else
			  output+=tempOutput;
      else{
      bytecounter++;
      buffer=tempOutput+buffer;
      if (bytecounter==4){
        if(j<size-1)
         	  output+=buffer+"\n";
        else
			    output+=buffer;  
        buffer="";
        bytecounter=0;
        }
      else if (j<size-1){
        if (entries[j+1].length==4){
          for(int k=0;k<4-bytecounter;k++)
            buffer="00"+buffer;
         	  output+=buffer+"\n";
          bytecounter=0;
          buffer = "";
        }
      }
      else{
        for(int k=0;k<4-bytecounter;k++)
          buffer="00"+buffer;
         	output+=buffer;
      }
      }
    }
    return output;
	}

  /** leng method return the size of the data memory. */
	public int leng()
	{
		return size;
	}

}


