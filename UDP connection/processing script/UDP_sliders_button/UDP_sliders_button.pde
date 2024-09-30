import hypermedia.net.*;
import processing.serial.*;

int PORT = 9877;
String HOST_IP = "localhost"; //IP Address of the PC in which this App is running
UDP udp; //Create UDP object for recieving

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port
int slider_1 = 0;
int slider_1_val = 0;
int slider_2 = 1;
int slider_2_val = 0;
int button_1 = 2;
String button_1_val = "2";
char button_1_value = button_1_val.charAt(0);
int button_2 = 3;
String button_2_val = "2";
char button_2_value = button_2_val.charAt(0);
int button_3 = 4;
String button_3_val = "2";
char button_3_value = button_3_val.charAt(0);
int button_4 = 5;
String button_4_val = "2";
char button_4_value = button_4_val.charAt(0);

void setup(){
  udp = new UDP(this);  
  udp.log(true);
  udp.listen(true);
  
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
}

void draw() {
  if (myPort.available() > 0) { 
    val = myPort.readStringUntil('\n');
    //println(val);
    if (val != null){
      String [] list = splitTokens(val,": ");
      int interaction = int(list[0]);
      int value = int(list[1]);
      String value_char = list[1];
      char first = value_char.charAt(0);
      
      if ((interaction == slider_1  & (value != slider_1_val))){
        slider_1_val = value;
        udp.send(str(interaction) + "," + str(value),HOST_IP,PORT);
      } else if ((interaction == slider_2  & (value!= slider_2_val))){
        slider_2_val = value;
        udp.send(str(interaction) + "," + str(value),HOST_IP,PORT);
      } else if ((interaction == button_1  & (first != button_1_value))){
        button_1_value = first;
        println("1");
        udp.send(str(interaction) + "," + str(first),HOST_IP,PORT);
      } else if ((interaction == button_2  & (first != button_2_value))){
        button_2_value = first;
        println("2");
        udp.send(str(interaction) + "," + str(first),HOST_IP,PORT);
      } else if ((interaction == button_3  & (first != button_3_value))){
        button_3_value = first;
        println("3");
        udp.send(str(interaction) + "," + str(first),HOST_IP,PORT);
      } else if ((interaction == button_4  & (first != button_4_value))){
        button_4_value = first;
        println("4");
        udp.send(str(interaction) + "," + str(first),HOST_IP,PORT);
      }
    }  
  } 
}
