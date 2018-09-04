import processing.net.*; 
import http.requests.*;
import java.sql.Timestamp;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.Timer;


import com.rabbitmq.client.*;
import java.io.IOException;
import java.util.concurrent.TimeoutException;
String EXCHANGE_NAME = "master_exchange";
String message = "";

color a, b, c, d, e;
color active = color(164, 223, 254);
color inactive = color(107, 128, 194);
boolean inUse = false, finished = false, interrupted = false, doorAjar = false, available = false; 
String dataIn = "";

//Timer
long timeEnd_mr = 0;
long timeStart_mr =0;
boolean started_mr = false;
long eventDelay = 2000; //If event changes is not changed for 3 seconds, keep state active.

void setup(){  
  size(1280, 720);
  noLoop();  
  
  //*************************
  //Data from RabbitMQ
  try{
    ConnectionFactory factory = new ConnectionFactory();
    factory.setUsername("test");
    factory.setPassword("TeSt");
    factory.setVirtualHost("/");
    factory.setHost("128.237.158.26");
    factory.setPort(5672);
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT);
    String queueName = channel.queueDeclare().getQueue();
    channel.queueBind(queueName, EXCHANGE_NAME, "80ee9a0e-e420-4263-9629-46ce4c3f7ae4");

    System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

    Consumer consumer = new DefaultConsumer(channel) {
      @Override
      public void handleDelivery(String consumerTag, Envelope envelope,
                                 AMQP.BasicProperties properties, byte[] body) throws IOException {
        message = new String(body, "UTF-8");
        message = message.replace('\'','\"');
        message = message.replace("u\"","\"");
        redraw();
      }
    };
    channel.basicConsume(queueName, true, consumer);
  
   } catch(IOException i) {
     println(i);
   } catch(TimeoutException i) {
     println(i);
   }   
  
  
}
int i = 0;
void draw(){
  background(0);
  
  //Timestamp timestamp = new Timestamp(System.currentTimeMillis());
  //int time_now = Integer.parseInt(String.valueOf(timestamp.getTime()).substring(0, 10));
  //println("TimeNow: " + millis());
  
  Timer timer = new Timer();
  
    a = b = c = d = e = inactive;
  
  //*************************
  long eventTime = 0;
  if(message.length() != 0){
    JSONObject json = parseJSONObject(message);
    JSONObject fields = json.getJSONObject("fields");
    message = fields.getString("value");
    String dateD = String.valueOf(json.getString("time"));
    eventTime = parseTime(dateD); //Time in GMT
    //println(eventTime);
  } else println("No new data");
  dataIn = message;
  
  println(i + " " + dataIn);
  i++;
  //*************************
  
  fill(255);
  text(dataIn,20,40);
  
  //*************************
  
  //ToDo: Consider Start-End type of data with time delay.
  //Smoothen the data
  //Use the code from typing project V4
  
  
  
  //Conditions for state change
  if(dataIn.equals("START:Microwave Running") || dataIn.equals("END:Microwave Running")){
    if(dataIn.equals("START:Microwave Running")){
        started_mr = true;
        timeStart_mr = eventTime;
        resetStates();
        inUse = true;
      }
      if(dataIn.equals("END:Microwave Running") && started_mr){
        timeEnd_mr = eventTime; 
      }
      //smooth data when time delay should not be more than eventDelay
      if(timeStart_mr - timeEnd_mr > eventDelay){
        inUse = false;
        timeEnd_mr = 0;
        timeStart_mr = 0;
      }
  }
  if(dataIn.equals("START:Chime")){
    resetStates();
    finished = true;
  }
  
 if(inUse&&dataIn.equals("START:Door Open")){
   interrupted = true;   
 }
 if(!inUse&&dataIn.equals("START:Door Open")){
   resetStates();
   doorAjar = true;
 }
 if(dataIn.equals("START:Door Close")){
   resetStates();
   available = true;
 }
  
  //Update UI
  if(inUse){
    resetUI();
    c = active;
  }
  if(finished){
    resetUI();
    e = active;
  }
  if(interrupted){
    resetUI();
    d = active;
  }
  if(doorAjar){
    resetUI();
    a = active;
  }
  if(available){
    resetUI();
    b = active;
  }
 
  //*************************
  // UI Elements
  
  fill(a);
  ellipse(156, 300, 200, 200);
  
  fill(b);
  ellipse(482, 300, 200, 200);
  
  fill(c);
  ellipse(798, 300, 200, 200);
  
  fill(d);
  ellipse(1124, 300, 200, 200);
  
  fill(e);
  ellipse(640, 555, 200, 200);

  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(265,275,110,0);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(375,325,110,180);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(590,300,100,0);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(907,275,110,0);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(1017,325,110,180);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(748,395,85,135);
  
  stroke(255,255,255);
  strokeWeight(5);
  drawArrow(582,460,85,225);
  
  //Header Text
  textSize(64);
  fill(active);
  text("MICROWAVE TRACKER", 280, 100);
  
  textSize(32);
  fill(0);
  text("Door Ajar", 80, 312);
  
  textSize(32);
  fill(0);
  text("Door Closed", 385, 312);
  
  textSize(32);
  fill(0);
  text("In-Use", 750, 312);
  
  textSize(32);
  fill(0);
  text("Interrupted", 1040, 312);
  
  textSize(32);
  fill(0);
  text("Finished", 580, 567);
  
  
} //Draw ends here


void resetUI(){
  a = b = c = d = e = inactive;
}
void resetStates(){
    inUse = finished =  interrupted = doorAjar =  available = false;
}

void drawArrow(int cx, int cy, int len, float angle){
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0,0,len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}

//Parse time from string and change it to unix timestamp
public long parseTime(String date){
  String[] arrOfStr = date.split("T|Z");
  String dat = arrOfStr[0] + " " + arrOfStr[1];
  String timestamp_data = "0";
  SimpleDateFormat datetimeFormatter1 = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
  try {
    Date lFromDate1 = datetimeFormatter1.parse(dat);
    Timestamp fromTS1 = new Timestamp(lFromDate1.getTime());

    timestamp_data = String.valueOf(fromTS1.getTime());
  }catch (java.text.ParseException e) {
    e.printStackTrace();
  }
  return Long.parseLong(String.valueOf(timestamp_data)) - 14400000;
  //return Integer.parseInt(String.valueOf(timestamp_data).substring(0, 10));
}
