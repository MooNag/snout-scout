import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:server/edit_lock.dart';
import 'dart:io';

import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

//TODO implement https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag

final env = DotEnv(includePlatformEnvironment: true)..load();
int serverPort = 6749;
Map<String, EventData> loadedEvents = {};
//To keep things simple we will just have 1 edit lock for all loaded events.
EditLock editLock = EditLock();

//Stuff that should be done for each event that is loaded.
class EventData {
  EventData(this.file);

  File file;
  List<WebSocket> listeners = [];
}

//Load all events from disk and instantiate an event data class for each one
Future loadEvents() async {
  final dir = Directory('events');
  final List<FileSystemEntity> allEvents = await dir.list().toList();
  for (final event in allEvents) {
    if (event is File) {
      print(event.uri.pathSegments.last);
      loadedEvents[event.uri.pathSegments.last] = EventData(event);
    }
  }
}

void main(List<String> args) async {
  if (env.isDefined('X-TBA-Auth-Key') == false) {
    print(
        "NO X-TBA-Auth-Key detected. Create a .env or set env to X-TBA-Auth-Key=key");
  }

  //REALLY JANK PING PONG SYSTEM
  //I SHOULD BE USING listener.pingInterval BUT THE CLIENT ISNT RESPONING
  //TO THE PING MESSAGES FOR SOME REASON (RESULTING IN THE CONNECTION CLOSING AFTER 1.5 DURATIONS)
  //BY THE SERVER. IF I LEAVE PING DURATION NULL THE CONNECTION CLOSES 1006 AFTER 60 seconds
  //I think this is a client side or proxy side thing.
  Timer.periodic(Duration(seconds: 30), (timer) {
    for (final event in loadedEvents.values) {
      for (final listener in event.listeners) {
        listener.add("PING");
      }
    }
  });

  await loadEvents();

  HttpServer server =
      await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
  //Enable GZIP compression since every byte counts and the performance hit is
  //negligable for the 30%+ compression depending on how much of the data is image
  server.autoCompress = true;

  print('Server started: ${server.address} port ${server.port}');

  //Listen for requests
  server.listen((HttpRequest request) async {
    print(request.uri);

    //CORS stuff
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Headers', '*');
    request.response.headers.add('Access-Control-Allow-Methods', '*');
    request.response.headers.add('Access-Control-Request-Method', '*');
    if (request.method == "OPTIONS") {
      request.response.close();
      return;
    }

    //Handle listener requests
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'listen') {
      WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
        final event = request.uri.pathSegments[1];
        //Set the ping interval to keep the connection alive for many browser's and proxy's default behavior.
        //For some reason this doesnt work client side so the server will just close the connection after 16 hours
        //the client will reconnect though so it "works". If pingInterval is fixed on the client side this can be reduced
        //and used as the primary connection indicator. Maybe 30 seconds
        websocket.pingInterval = Duration(hours: 12);
        //Remove the websocket from the listeners when it is closed for any reason.
        websocket.done
            .then((value) => loadedEvents[event]?.listeners.remove(websocket));
        loadedEvents[event]?.listeners.add(websocket);
      });
      return;
    }

    if (request.uri.toString() == "/edit_lock") {
      return handleEditLockRequest(request);
    }

    if (request.uri.toString() == "/events") {
      request.response.write(json.encode(loadedEvents.keys.toList()));
      request.response.close();
      return;
    }

    // event/some_name
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'events') {
      final eventID = request.uri.pathSegments[1];
      File? f = loadedEvents[eventID]?.file;
      if (f == null || await f.exists() == false) {
        request.response.statusCode = 404;
        request.response.write('Event not found');
        request.response.close();
        return;
      }
      var event = SnoutDB.fromJson(json.decode(await f.readAsString()));

      //I KNOW THIS IS HARD CODED PATH OVERRIDE BUT I DONT CARE
      if (request.uri.pathSegments.length == 3 &&
          request.uri.pathSegments[2] == "patchDiff") {
            print("WEEYEYYEEYWWYYWYWE");
        // length of client patch database.
        final clientHead = request.headers.value("head");

        if (clientHead == null) {
          request.response.statusCode = 406;
          request.response.write('send head');
          request.response.close();
          return;
        }

        int clientHeadInt = int.parse(clientHead);

        if (clientHeadInt < 1) {
          request.response.statusCode = 406;
          request.response.write('head cannot be less than 1');
          request.response.close();
          return;
        }

        final range =
            event.patches.getRange(clientHeadInt, event.patches.length);

        request.response.headers.contentType =
            new ContentType('application', 'json', charset: 'utf-8');
        request.response.write(json.encode(range.toList()));
        request.response.close();
        return;
      }

      if (request.method == 'GET') {
        if (request.uri.pathSegments.length > 2 &&
            request.uri.pathSegments[2] != "") {
          //query was for a specific sub-item. Path segments with a trailing zero need to be filtered
          //events/2022mnmi2 is not the same as event/2022mnmi2/
          try {
            var dbJson = json.decode(json.encode(event));
            final pointer = JsonPointer(
                '/${request.uri.pathSegments.sublist(2).join("/")}');
            dbJson = pointer.read(dbJson);
            request.response.headers.contentType =
                new ContentType('application', 'json', charset: 'utf-8');
            request.response.write(json.encode(dbJson));
            request.response.close();
            return;
          } catch (e) {
            print(e);
            request.response.statusCode = 500;
            request.response.write(e);
            request.response.close();
            return;
          }
        }

        request.response.headers.contentType =
            new ContentType('application', 'json', charset: 'utf-8');
        request.response.write(json.encode(event));
        request.response.close();
        return;
      }

      if (request.method == "PUT") {
        try {
          String content = await utf8.decodeStream(request);
          Patch patch = Patch.fromJson(json.decode(content));

          event.addPatch(patch);
          //Write the new DB to disk
          await f.writeAsString(json.encode(event));
          request.response.close();

          print(json.encode(patch));

          //Successful patch, send this update to all listeners
          for (final listener in loadedEvents[eventID]?.listeners ?? []) {
            listener.add(json.encode(patch));
          }

          return;
        } catch (e) {
          print(e);
          request.response.statusCode = 500;
          request.response.write(e);
          request.response.close();
          return;
        }
      }
      return;
    }

    request.response.statusCode = 404;
    request.response.write("Not Found");
    request.response.close();
  });
}

void handleEditLockRequest(HttpRequest request) {
  final key = request.headers.value("key");
  if (key == null) {
    request.response.write("invalid key");
    request.response.close();
    return;
  }
  if (request.method == "GET") {
    final lock = editLock.get(key);
    if (lock) {
      request.response.write(true);
      request.response.close();
      return;
    }
    request.response.write(false);
    request.response.close();
    return;
  }
  if (request.method == "POST") {
    editLock.set(key);
    request.response.close();
    return;
  }
  if (request.method == "DELETE") {
    editLock.clear(key);
    request.response.close();
    return;
  }
}
