import "package:polymorphic_bot/api.dart";
import "package:http/http.dart" as http;
import "dart:async";
import "dart:convert";

BotConnector bot;
const String BASE_DARTDOC = "http://www.dartdocs.org/documentation/";
http.Client httpClient = new http.Client();

void main(_, Plugin plugin) {
  bot = plugin.getBot();

  bot.command("whatis", (event) {
    APIDocs.handleWhatIsCmd(event);
  });

  bot.command("dartdoc", (event) {
    if (event.args.length > 2 || event.args.length < 1) {
      event.reply("> Usage: dartdoc <package> [version]");
    } else {
      String package = event.args[0];
      String version = event.args.length == 2 ? event.args[1] : "latest";
      dartdocUrl(event.args[0], version).then((url) {
        if (url == null) {
          event.reply("> package not found '${package}@${version}'");
        } else {
          event.reply("> Documentation: ${url}");
        }
      });
    }
  });
  
  bot.command("pub-latest", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-latest <package>");
    } else {
      latestPubVersion(event.args[0]).then((version) {
        if (version == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Latest Version: ${version}");
        }
      });
    }
  });
  
  bot.command("pub-description", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-description <package>");
    } else {
      pubDescription(event.args[0]).then((desc) {
        if (desc == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Description: ${desc}");
        }
      });
    }
  });
  
  bot.command("pub-downloads", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-downloads <package>");
    } else {
      String package = event.args[0];
      pubPackage(package).then((info) {
        if (info == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Download Count: ${info["downloads"]}");
        }
      });
    }
  });
  
  bot.command("pub-uploaders", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-uploaders <package>");
    } else {
      String package = event.args[0];
      pubUploaders(package).then((authors) {
        if (authors == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Uploaders: ${authors.join(", ")}");
        }
      });
    }
  });
  
  APIDocs.init();
}

Future<String> dartdocUrl(String package, [String version = "latest"]) {
  if (version == "latest") {
    return latestPubVersion(package).then((version) {
      if (version == null) {
        return new Future.value(null);
      }
      return new Future.value("${BASE_DARTDOC}${package}/${version}");
    });
  } else {
    return new Future.value("${BASE_DARTDOC}${package}/${version}");
  }
}

Future<Map<String, Object>> pubPackage(String package) {
  return httpClient.get("https://pub.dartlang.org/api/packages/${package}").then((http.Response response) {
    if (response.statusCode == 404) {
      return new Future.value(null);
    } else {
      return new Future.value(JSON.decoder.convert(response.body));
    }
  });
}

Future<String> pubDescription(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["description"]);
    }
  });
}

Future<List<String>> pubUploaders(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["uploaders"]);
    }
  });
}

Future<List<String>> pubVersions(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      var versions = [];
      val["versions"].forEach((version) {
        versions.add(version["name"]);
      });
      return new Future.value(versions);
    }
  });
}

Future<String> latestPubVersion(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["version"]);
    }
  });
}

class APIDocs {
  static const String LIBRARY_LIST_URL = "https://api.dartlang.org/apidocs/channels/stable/docs/library_list.json";

  static Map<String, String> index = {};

  static void init() {
    http.get("https://api.dartlang.org/apidocs/channels/stable/docs/index.json").then((response) {
      index = JSON.decode(response.body);
    });
  }

  static void handleWhatIsCmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <id>");
      return;
    }

    String id = event.args.join(" ");

    if (index.containsKey(id)) {
      event.reply("> Type: ${index[id]}");
    } else {
      event.reply("> ID not found.");
    }
  }
}
