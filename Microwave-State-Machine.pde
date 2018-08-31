import processing.net.*; 
import http.requests.*;
import java.sql.Timestamp;
import java.util.Date;
import java.text.SimpleDateFormat;

color a, b, c, d, e;
color active = color(164, 223, 254);
color inactive = color(107, 128, 194);
boolean inUse = false, finished = false, interrupted = false, doorAjar = false, available = false; 
boolean typing = false, idle = false, drilling = false; 

Client myClient;
String dataIn = "";

int refresh = 250;

//Timer
long timeEnd_t = 0;
long timeStart_t =0;
boolean started_t = false;

long timeEnd_d = 0;
long timeStart_d =0;
boolean started_d = false;

long t1 = 0;


long eventDelay = 3000;

//Main Server
String cs_host = "https://bd-test.andrew.cmu.edu:81";
String ds_host = "https://bd-test.andrew.cmu.edu:82";
String client_id = "7fWty5k7fGOdaSLFlVwM5tDz5M63iQvCjXcNmhGL";
String client_secret = "OmQndEHWYpbqIM1zvp2SWvbyTbiqphWSbgjnNQpG80UZh6UJ2g";
String sensor_id = "80ee9a0e-e420-4263-9629-46ce4c3f7ae4";

JSONArray jval;
String accessToken = "";


void setup(){
  size(1280, 720);
  myClient = new Client(this, "127.0.0.1", 5204); 
  
  //Request for access token
  GetRequest getAccessToken = new GetRequest(cs_host + "/oauth/access_token/client_id=" + client_id + "/client_secret=" + client_secret);
  getAccessToken.send();
  JSONObject json = parseJSONObject(getAccessToken.getContent());
  accessToken = json.getString("access_token");
}

void draw(){
  background(0);
  
  println(frameCount);
  a = b = c = d = e = inactive;
  
    //Request for data
  Timestamp timestamp = new Timestamp(System.currentTimeMillis());
  int time_now = Integer.parseInt(String.valueOf(timestamp.getTime()).substring(0, 10));
  //println("TimeNow: " + time_now);
  int timestamp_start = time_now - 2;//Change to get only the latest values: Last n seconds
  GetRequest getData = new GetRequest(ds_host + "/api/sensor/" + sensor_id + "/timeseries?start_time=" + timestamp_start + "&end_time=" + time_now);
  getData.addHeader("Authorization", "Bearer " + accessToken);
  getData.addHeader("Accept", "application/json");
  getData.send();
  
  //Data
  String dataString = getData.getContent();
  JSONObject data_in = parseJSONObject(dataString);
  JSONObject data = data_in.getJSONObject("data");
  JSONArray jarr = data.getJSONArray("series");
  
  //If data is null just print "No data"  
  if(jarr != null){
  JSONObject jOV = jarr.getJSONObject(0);
  jval = jOV.getJSONArray("values");
  int l = jval.size();
  for(int i = 0; i < l; i++){
    
    JSONArray laste = jval.getJSONArray(i);
    dataIn = String.valueOf(laste.get(2));
    String dateD = String.valueOf(laste.get(0));
    long eventTime = parseTime(dateD); //Time in GMT
    if(t1 >= eventTime){
      //println(i + " Duplicate Found. Skipping value");
      continue;
    }
    println(i + " " + dateD + " " +dataIn);
    //println(i + " EventTime: "  + eventTime);
    textSize(32);fill(255);text(dataIn + " " + dateD, 10, 30);

    
    //**********************************
    if(dataIn.equals("START:typing") || dataIn.equals("END:typing")){
      if(dataIn.equals("START:typing")){
        started_t = true;
        timeStart_t = eventTime;
        resetStates();
        typing = true;
      }
      if(dataIn.equals("END:typing") && started_t){
        timeEnd_t = eventTime; 
      }
      if(timeEnd_t - timeStart_t > eventDelay){
        typing = false;
        idle = true;
        timeEnd_t = 0;
        timeStart_t = 0;
      }
     } 
       //Drill State
  else if(dataIn.equals("START:drill") || dataIn.equals("END:drill")){
    if(dataIn.equals("START:drill")){
      started_d = true;
      timeStart_d = eventTime;
      resetStates();
      drilling = true;
    }
    if(dataIn.equals("END:drill") && started_d){
      //timeEnd_d = eventTime;   
      drilling = false;
      idle = true;
      timeEnd_d = 0;
      timeStart_d = 0;
    }
    //if(timeEnd_d - timeStart_d > eventDelay){
    //  drilling = false;
    //  idle = true;
    //  timeEnd_d = 0;
    //  timeStart_d = 0;
    //}
  } else if(dataIn.equals("START:idle") || dataIn.equals("END:idle")){
    println("Ignoring");
  } else {
    resetStates();
    idle = true;
  }
    
  }
  t1 = parseTime(String.valueOf(jval.getJSONArray(l - 1).get(0)));
  
  
  } else {
    println("No new data"); 
    textSize(32);fill(255);text("No data", 10, 30);
    Timestamp timestamp1 = new Timestamp(System.currentTimeMillis());
    long time_now1 = Long.parseLong(String.valueOf(timestamp1.getTime()));
    if(typing && (time_now1 - timeEnd_t) > eventDelay){
      typing = false;
      idle = true;
      timeEnd_t = 0;
      timeStart_t = 0;
    }
    //if(drilling && (time_now1 - timeEnd_d) > eventDelay){
    //  drilling = false;
    //  idle = true;
    //  timeEnd_d = 0;
    //  timeStart_d = 0;
    //}
    }
  
  if (myClient.available() > 0) { 
    dataIn = myClient.readString(); 
  } 
  fill(255);
  text(dataIn,20,40);
  
  //*************************
  
  //ToDo: Consider Start-End type of data with time delay.
  //Smoothen the data
  //Use the code from typing project V4
  
  //Conditions for state change
  if(dataIn.equals("Mirowave Running")){
    resetStates();
    inUse = true;
  }
  if(dataIn.equals("Chime")){
    resetStates();
    finished = true;
  }
  
 if(inUse&&dataIn.equals("Door Open")){
   interrupted = true;   
 }
 if(!inUse&&dataIn.equals("Door Open")){
   doorAjar = true;
 }
 if(doorAjar&&dataIn.equals("Door Close")){
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
  text("Available", 415, 312);
  
  textSize(32);
  fill(0);
  text("In-Use", 750, 312);
  
  textSize(32);
  fill(0);
  text("Interrupted", 1040, 312);
  
  textSize(32);
  fill(0);
  text("Finished", 580, 567);
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

void drawArrow(int cx, int cy, int len, float angle){
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0,0,len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}
void resetUI(){
  a = b = c = d = e = inactive;
}
void resetStates(){
    inUse = finished =  interrupted = doorAjar =  available = false;
}
