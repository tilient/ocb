
void main ()
{
  enum wiffel =
    "https://wiffel.stackstorage.com/remote.php/webdav/";
  enum wiffeltje =
    "https://wiffeltje.stackstorage.com/remote.php/webdav/";

  check("/home/wiffel/Videos/", wiffeltje ~ "media/Videos");
  check("/home/wiffel/Videos/", wiffel    ~ "media/Videos");
  check("/home/wiffel/Music/",  wiffel    ~ "media/Music");
  check("/home/wiffel/Music/",  wiffeltje ~ "media/Music");
}

void check(string fileroot, string webdavroot)
{
  import std.stdio;
  import std.file;
  import std.conv;

  writeln("==============================================");
  writeln(fileroot);
  writeln(webdavroot);
  writeln("==============================================");
  foreach (DirEntry e; dirEntries(fileroot, SpanMode.breadth))
  {
    auto shortName = e.name[fileroot.length .. $];
    auto displayName = shortName;
    if (displayName.length > 43)
      displayName =
        shortName[0 .. 20] ~ "..." ~ shortName[$-20 .. $];
    WebDavEntry entry;
    if (webdavFileInfo(webdavroot, shortName, entry))
    {
      if (entry.isDir)
      {
        //write("OK Dir");
      } else {
        if (e.size == entry.size)
        {
          //write("OK    ");
        } else {
          writeln("** Not OK");
          write("** ");
          writeln(e.name);
        }
      }
    } else {
      writeln("** Not Found");
      write("** ");
      writeln(e.name);
    }
    //writeln(" - '", displayName, "'");
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
  import std.stdio: stdin, writeln;
  import std.process: spawnProcess, pipe, wait;
  import std.xml: check, DocumentParser, ElementParser, Element;
  import std.uri: encodeComponent;
  import std.conv;
  import std.path;


  auto target = root;
  foreach(part; pathSplitter(trgt))
    target ~= "/" ~ part.encodeComponent;
  entry.name = trgt;
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
