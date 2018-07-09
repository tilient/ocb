
void main ()
{
  import std.stdio;
  import std.file;
  import std.conv;

  auto cnt = 0;
  enum fileroot = "/mnt/c/wiffel/public/";
  enum webdavroot =
    "https://wiffel.stackstorage.com/remote.php/webdav/public/";
  foreach (DirEntry e; dirEntries(fileroot, SpanMode.breadth))
  {
    cnt++;
    if (cnt < 8)
      continue;

    auto shortName = e.name[fileroot.length .. $];
    auto displayName = shortName;
    if (displayName.length > 43)
      displayName =
        shortName[0 .. 20] ~ "..." ~ shortName[$-20 .. $];
    writeln(e.isDir ? "D - " : "F - ",
            "(", e.isDir ? "" : to!string(e.size), ") ",
            "'", displayName, "'",);
    //writeln(shortName);
    webdavFileInfo(webdavroot, shortName);
    writeln("---------------------------");
    // if (cnt > 119)
    //   break;
  }

//   enum webdavroot =
//     "https://wiffel.stackstorage.com/remote.php/webdav/";
//   enum username = "wiffel";
//   enum password = "brol";
//
//   auto target = webdavroot ~ "media/ttt";
//   auto pid = spawnProcess([
//       "curl",
//       "-u", username ~ ":" ~ password,
//       "--anyauth",
//       "-X", "MKCOL",
//       target]);
//   wait(pid);
//
//   pid = spawnProcess([
//       "curl",
//       "-u", username ~ ":" ~ password,
//       "--anyauth",
//       "-X", "DELETE",
//       target]);
//   wait(pid);
//
//
//   target = webdavroot ~ "wiffel/desktop";
//   auto p = pipe();
//   pid = spawnProcess([
//       "curl",
//       "-s",
//       "--anyauth",
//       "-u", username ~ ":" ~ password,
//       "-X", "PROPFIND",
//       "-H", "Depth:1",
//       target], std.stdio.stdin, p.writeEnd);
//   scope(exit) wait(pid);
//   string xmlStr;
//   foreach (line; p.readEnd.byLine)
//     xmlStr ~= line;
//   writeln("\n---");
//   // writeln(xmlStr);
//   // writeln("---");
//   check(xmlStr);
//   auto xml = new DocumentParser(xmlStr);
//
//   xml.onStartTag["d:response"] = (ElementParser xml)
//   {
//     auto displayname = "";
//     auto resourcetype = "";
//     xml.onEndTag["d:displayname"] =
//       (in Element e) { displayname = e.text(); };
//     xml.onEndTag["d:resourcetype"] =
//       (in Element e) { resourcetype = e.text(); };
//     xml.parse();
//     auto rt = resourcetype == "" ? "file" : "directory";
//     writeln(displayname, " (", rt, ")");
//   };
//   xml.parse();
}

bool webdavFileInfo(string root, string trgt)
{
  import std.stdio: writeln, stdin;
  import std.process: spawnProcess, pipe, wait;
  import std.xml: check, DocumentParser, ElementParser, Element;
  import std.uri: encodeComponent;

  auto target = root ~ trgt.encodeComponent;
  enum username = "wiffel";
  enum password = "brol";
  auto p = pipe();
  auto pid = spawnProcess([
      "curl",
      "-s",
      "--anyauth",
      "-u", username ~ ":" ~ password,
      "-X", "PROPFIND",
      "-H", "Depth:0",
      target], stdin, p.writeEnd);
  scope(exit) wait(pid);
  string xmlStr;
  foreach (line; p.readEnd.byLine)
    xmlStr ~= line;
  // writeln("-+-");
  // writeln(xmlStr);
  // writeln("---");
  if (xmlStr == "Not Found")
  {
    writeln("Not Found");
    writeln("======");
    writeln(target);
    writeln("======");
    return false;
  }

  check(xmlStr);
  auto xml = new DocumentParser(xmlStr);

  xml.onStartTag["d:response"] = (ElementParser xml)
  {
    auto displayname = "";
    auto resourcetype = "";
    auto contentLength = "";
    xml.onEndTag["d:displayname"] =
      (in Element e) { displayname = e.text(); };
    xml.onEndTag["d:resourcetype"] =
      (in Element e) { resourcetype = e.text(); };
    xml.onEndTag["d:getcontentlength"] =
      (in Element e) { contentLength = e.text(); };
    xml.parse();
    auto rt = resourcetype == "" ? "F" : "D";
    writeln(rt, " - (", contentLength, ")");
  };
  xml.parse();
  return true;
}
