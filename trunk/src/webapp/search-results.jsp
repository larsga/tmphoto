<%@ include file="declarations.jsp"%>
<%@ page
  import="java.util.Properties,
          org.python.util.PythonInterpreter,
          net.ontopia.utils.*,
          net.ontopia.topicmaps.core.*,
          net.ontopia.topicmaps.utils.*,
          net.ontopia.topicmaps.nav2.utils.*,
          net.ontopia.topicmaps.query.utils.*,
          net.ontopia.topicmaps.classify.*,
          net.ontopia.topicmaps.nav2.core.*"
%>
<html>
<head>
  <title>Search results</title> 
  <link rel="stylesheet" type="text/css" href="tmphoto.css"></link>
  <link rel="alternate" type="application/rss+xml" title="RSS" 
      href="http://www.garshol.priv.no/tmphoto/rss.jsp">
  </link>
  <meta http-equiv="content-type" content="text/html; charset=utf-8"></meta>
</head>

<body>

<table width="100%"><tr><td>
  <h1>Search results</h1>
<td align=right class=linkbar>
  <a href="/tmphoto/">Home</a> |
  <a href="people.jsp">People</a> |
  <a href="events.jsp">Events</a> |
  <a href="places.jsp">Places</a> |
  <a href="categories.jsp">Categories</a> |
  <a href="login.jsp">Log in</a>
</table>

<%
  String tmid = "metadata.xtm"; //"photos.xtm";
  String query = StringUtils.transcodeUTF8(request.getParameter("search"));

  NavigatorApplicationIF navApp = NavigatorUtils.getNavigatorApplication(pageContext);
  TopicMapIF topicmap = navApp.getTopicMapById(tmid);

  StringifierIF strify = TopicStringifiers.getDefaultStringifier();

  Properties props = new Properties();
  props.setProperty("python.path", "/usr/local/java/jython-2.5/Lib");
  PythonInterpreter.initialize(System.getProperties(), props,
                             new String[] {""});

  PythonInterpreter interpreter = new PythonInterpreter();
  interpreter.set("stoplist", Language.getLanguage("en").getStopListAnalyzer());
  interpreter.set("query", query);
  interpreter.set("tm", topicmap);
  interpreter.set("tmid", tmid);
  interpreter.set("strify", strify);
  interpreter.set("TopicStringifiers", TopicStringifiers.class);
  interpreter.set("qp", QueryUtils.getQueryProcessor(topicmap));
  interpreter.setOut(out);
  interpreter.execfile("webapps/tmphoto/sem-search.py");
%>

<p>
<hr>

<address>
tmphoto app built with OKS.
<%
  Object username = session.getAttribute("username");
  if (username != null) {
%>
  You are logged in as <b><%= username %></b>.
  <a href="login.jsp">Log out</a>.
<%
  }
%>
</address>
</body>
</html>
