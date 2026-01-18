#include <HID-Project.h>

void slowWrite(const char* str) {
  for (int i = 0; str[i] != 0; i++) {
    BootKeyboard.write(str[i]); 
    delay(50);                   
  }
}

void setup() {
  BootKeyboard.begin();

  delay(4000);

  BootKeyboard.press(KEY_LEFT_GUI);
  BootKeyboard.press('r');
  delay(300);
  BootKeyboard.releaseAll();
  
  delay(1200); 

  // slowWrite("powershell");
  slowWrite("cmd");
  BootKeyboard.write(KEY_RETURN);
  
  delay(1000); 
  slowWrite("dir");
  BootKeyboard.write(KEY_RETURN);
  delay(1000);
  
  slowWrite("wmic startup get Name");
  BootKeyboard.write(KEY_RETURN); 
  
  delay(2000);

  slowWrite("exit");
  BootKeyboard.write(KEY_RETURN);

  BootKeyboard.end();
}

void loop() {
}