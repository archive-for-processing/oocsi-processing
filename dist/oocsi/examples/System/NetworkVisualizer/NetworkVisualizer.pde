import nl.tue.id.oocsi.*;
import java.util.*;
import java.util.concurrent.*;

// ******************************************************
// This example requires a running OOCSI server!
//
// How to do that? Check: Examples > Tools > LocalServer
//
// More information how to run an OOCSI server
// can be found here: https://iddi.github.io/oocsi/)
// ******************************************************

// data structure to store nodes (outer circle)
Map<String, Node> nodes = new ConcurrentHashMap<String, Node>();

// data structure to store channels (inner circle)
Map<String, Node> channels = new ConcurrentHashMap<String, Node>();

// event queue
Queue<OOCSIEvent> events = new LinkedList<OOCSIEvent>();

// OOCSI connection
OOCSI oocsi;

void setup() {
  size(600, 400);
  frameRate(30);

  // create a unique name for the visualizer
  String name = "netvis" + random(20);
  
  // connect to a server running on the local machine
  // note: the network visualizer will only work fully, if this 
  // server has 'logging' switched on
  oocsi = new OOCSI(this, name, "localhost");  
  
  // subscribe to a channel with information about all connected clients
  oocsi.subscribe("OOCSI_clients");
  // subscribe to a channel that receives all sent events
  oocsi.subscribe("OOCSI_events");
  
  // optional: subscribe to a channel with connection information
  //oocsi.subscribe("OOCSI_connections");
}

void draw() {

  // fading effect
  noStroke();
  fill(0, 20);
  rect(0, 0, width, height);

  // draw everything from the center of the screen
  translate(width/2., height/2.);

  // draw all events as lines connecting sender and receiver, one-by-one
  while (!events.isEmpty()) {
    OOCSIEvent e = events.poll();
    String sender = e.getString("sender");
    String recipient = e.getString("recipient");

    // sender first, drawn in purple
    strokeWeight(2);
    stroke(#8800ff);
    if (nodes.containsKey(sender)) {
      PVector s = nodes.get(sender).pos;

      if (nodes.containsKey(recipient)) {
        PVector p = nodes.get(recipient).pos;
        line(p.x + random(-3, 3), p.y + random(-3, 3), s.x, s.y);
      } else if (channels.containsKey(recipient)) {
        PVector p = channels.get(recipient).pos;
        line(p.x + random(-3, 0), p.y + random(-3, 0), s.x, s.y);
      }
    }

    // recipient second, drawn in green
    stroke(#00ff66);
    if (channels.containsKey(sender)) {
      PVector s = channels.get(sender).pos;

      if (nodes.containsKey(recipient)) {
        PVector p = nodes.get(recipient).pos;
        line(p.x + random(0, 3), p.y + random(0, 3), s.x, s.y);
      }
    }
  }

  // draw all nodes on top of the event lines
  fill(250);
  noStroke();
  int i = 0;
  for (String key : nodes.keySet()) {
    Node n = nodes.get(key);

    if (n != null && n.isValid()) {
      n.update(180 * sin(radians((360/nodes.size()) * i)), 
        180 * cos(radians((360/nodes.size()) * i++)));
      ellipse(n.pos.x, n.pos.y, 6, 6);
      text(key, n.pos.x + 5, n.pos.y + 5);
    } else {
      channels.remove(key);
      return;
    }
  }

  // channels draw all channels on top of nodes and events
  i = 0;
  for (String key : channels.keySet()) {
    Node n = channels.get(key);
    if (n.isValid()) {
      n.update(50 * sin(radians(360/channels.size() * i + frameCount/10.)), 
        50 * cos(radians(360/channels.size() * i++ + frameCount/10.)));
      ellipse(n.pos.x, n.pos.y, 6, 6);
      text(key, n.pos.x + 5, n.pos.y + 5);
    } else {
      channels.remove(key);
      return;
    }
  }
}

void OOCSI_clients(OOCSIEvent evt) {
  nodes.clear();
  for (String str : evt.getString("clients").split(",")) {
    if (!nodes.containsKey(str)) {
      nodes.put(str, new Node());
      channels.remove(str);
    }
  }
}

void OOCSI_events(OOCSIEvent evt) {
  // method sender recipient
  events.offer(evt);

  String channel = evt.getString("recipient");
  if (!channels.containsKey(channel) && !nodes.containsKey(channel)) {
    channels.put(channel, new Node());
  }

//void OOCSI_connections(OOCSIEvent evt) {
//  println(evt.keys(), evt.getString("channel"));
//}

}

class Node {
  private PVector pos = new PVector(0, 0);
  private long lastUpdate = millis();

  void update(float x, float y) {
    pos.x = x;
    pos.y = y;
    lastUpdate = millis();
  }

  boolean isValid() {
    return lastUpdate > millis() - 3000;
  }
}