
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
    WebDavEntry entry;
    if (webdavFileInfo(webdavroot, shortName, entry))
    {
      writeln(entry.isDir ? "D - " : "F - ",
            "(", e.isDir ? "" : to!string(entry.size), ") ");
    } else {
      writeln("Not Found");
    }
    writeln("---------------------------");
    // if (cnt > 119)
    //   break;
  }

//   enum webdavroot =
//     "https://wiffel.stackstorage.com/remote.php/webdav/";
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
}

struct WebDavEntry
{
  string name  = "";
  ulong  size  = -1;
  bool   isDir = false;
}

bool webdavFileInfo(string root, string trgt,
                    ref WebDavEntry entry)
{
  import std.stdio: stdin;
  import std.process: spawnProcess, pipe, wait;
  import std.xml: check, DocumentParser, ElementParser, Element;
  import std.uri: encodeComponent;
  import std.conv;

  entry.name = trgt;
  auto target = root ~ trgt.encodeComponent;
  auto p = pipe();
  auto pid = spawnProcess([
               "curl", "-s", "--anyauth", "-n",
               "-X", "PROPFIND", "-H", "Depth:0",
               target], stdin, p.writeEnd);

  string xmlStr;
  foreach (line; p.readEnd.byLine)
    xmlStr ~= line;
  if (xmlStr == "Not Found")
    return false;

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
      (in Element e) {
        entry.isDir = e.text() != "";
      };
    xml.onEndTag["d:getcontentlength"] =
      (in Element e) {
        contentLength = e.text();
        entry.size =  to!ulong(e.text);
      };
    xml.parse();
  };
  xml.parse();
  return true;
}
