/** isNumber class contains some static functions for checking 
  * if the input String is a number
  */
class isNumber{

  /** isNumbrD checks if the input string is a decimal number. */
  static boolean isNumberD(String string) {
  try {
    Long.parseLong(string);
  } catch (Exception e) {
    return false;
  }
  return true;
  }
  
  /** isNumbrD checks if the input string is a hexadecimal number. */
  static boolean isNumberH(String string) {
  try {
    Long.parseLong(string,16);
  } catch (Exception e) {
    return false;
  }
  return true;
  }
 
 }

