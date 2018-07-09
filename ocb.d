
void main ()
{
  import std.process;
  import std.stdio;
  import std.xml;

  enum webdavroot =
    "https://wiffel.stackstorage.com/remote.php/webdav/";
  enum username = "wiffel";
  enum password = "ttT1l1ent";

  auto target = webdavroot ~ "media/ttt";
  auto pid = spawnProcess([
      "curl",
      "-u", username ~ ":" ~ password,
      "--anyauth",
      "-X", "MKCOL",
      target]);
  wait(pid);

  pid = spawnProcess([
      "curl",
      "-u", username ~ ":" ~ password,
      "--anyauth",
      "-X", "DELETE",
      target]);
  wait(pid);


  target = webdavroot ~ "wiffel/desktop";
  auto p = pipe();
  pid = spawnProcess([
      "curl",
      "-s",
      "--anyauth",
      "-u", username ~ ":" ~ password,
      "-X", "PROPFIND",
      "-H", "Depth:1",
      target], std.stdio.stdin, p.writeEnd);
  scope(exit) wait(pid);
  string xmlStr;
  foreach (line; p.readEnd.byLine)
    xmlStr ~= line;
  writeln("\n---");
  // writeln(xmlStr);
  // writeln("---");
  check(xmlStr);
  auto xml = new DocumentParser(xmlStr);

  xml.onStartTag["d:response"] = (ElementParser xml)
  {
    auto displayname = "";
    auto resourcetype = "";
    xml.onEndTag["d:displayname"] =
      (in Element e) { displayname = e.text(); };
    xml.onEndTag["d:resourcetype"] =
      (in Element e) { resourcetype = e.text(); };
    xml.parse();
    auto rt = resourcetype == "" ? "file" : "directory";
    writeln(displayname, " (", rt, ")");
  };
  xml.parse();
}
