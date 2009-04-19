<%-- $Id: save.jsp,v 1.1 2008/07/18 18:32:33 larsga Exp $ --%> 
<%@ page language="java" import="
    java.io.File,
    net.ontopia.topicmaps.nav2.core.NavigatorApplicationIF,
    net.ontopia.topicmaps.nav2.utils.*,
    net.ontopia.topicmaps.core.*,
    net.ontopia.topicmaps.xml.XTMTopicMapWriter" %>
<%
   response.setHeader("Cache-control", "no-cache");
   response.setContentType("text/html; charset=utf-8");

   String tmid = "metadata.xtm";
   String filename = "metadata.xtm";

   NavigatorApplicationIF navApp = NavigatorUtils.getNavigatorApplication(pageContext);
   TopicMapIF tm = navApp.getTopicMapById(tmid);

   File webapps = new File(pageContext.getServletContext().getRealPath("index.html")).getParentFile().getParentFile();
   File outfile = new File(webapps, "omnigator" + File.separator + "WEB-INF" + File.separator + "topicmaps" + File.separator + filename);
   XTMTopicMapWriter writer = new XTMTopicMapWriter(outfile);
   writer.write(tm);
%>
wrote to <%= outfile %>
