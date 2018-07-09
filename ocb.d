
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
  writeln(" =>");
  writeln(webdavroot);
  writeln("==============================================");
  foreach (DirEntry e; dirEntries(fileroot, SpanMode.breadth))
  {
    if (e.isDir)
      continue;
    auto shortName = e.name[fileroot.length .. $];
    auto displayName = shortName;
    if (displayName.length > 63)
      displayName =
        shortName[0 .. 30] ~ "..." ~ shortName[$-30 .. $];
    WebDavEntry entry;
    writeln(displayName);
    if (webdavFileInfo(webdavroot, shortName, entry))
    {
      if (entry.isFile && (e.size != entry.size))
      {
        writeln("** Not OK");
        writeln("-- ", e.size, " <> ", entry.size);
        write("-- ");
        writeln(e.name);

        auto ttt = webdavUri(webdavroot, shortName);
        writeln("curl -n -T '" ~ e.name ~ "' '" ~ ttt ~ "'");
        writeln();
      }
    } else {
      writeln("** Not Found");
      write("-- ");
      writeln(e.name);

      auto ttt = webdavUri(webdavroot, shortName);
      writeln("curl -n -T '" ~ e.name ~ "' '" ~ ttt ~ "'");
      writeln();
    }
  }
}

struct WebDavEntry
{
  string name   = "";
  ulong  size   = -1;
  bool   isFile = true;
}

string webdavUri(string root, string target)
{
  import std.path : pathSplitter;
  import std.uri : encodeComponent;

  auto uri = root;
  foreach(part; pathSplitter(target))
    uri ~= "/" ~ part.encodeComponent;
  return uri;
}

bool webdavFileInfo(string root, string trgt,
                    ref WebDavEntry entry)
{
  import std.stdio: stdin, writeln;
  import std.process: spawnProcess, pipe, wait;
  import std.xml: check, DocumentParser, ElementParser, Element;
  import std.conv;

  entry.name = trgt;

  auto p = pipe();
  auto pid = spawnProcess([
               "curl", "-s", "--anyauth", "-n",
               "-X", "PROPFIND", "-H", "Depth:0",
               webdavUri(root, trgt)],
               stdin, p.writeEnd);
  scope(exit) wait(pid);

  string xmlStr;
  foreach (line; p.readEnd.byLine)
    xmlStr ~= line;
  if (xmlStr == "Not Found")
    return false;

  check(xmlStr);
  auto xml = new DocumentParser(xmlStr);
  xml.onStartTag["d:response"] = (ElementParser xml)
  {
    xml.onEndTag["d:resourcetype"] = (in Element e) {
      entry.isFile = e.text() == "";
    };
    xml.onEndTag["d:getcontentlength"] = (in Element e) {
      entry.size =  to!ulong(e.text);
    };
    xml.parse();
  };
  xml.parse();
  return true;
}
