<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="photo" reqparam="id"/>
<tolog:set var="nextphoto" reqparam="photo"/>
<%
response.setHeader("Cache-control", "no-cache");

// 1. Delete the file
TopicIF topic = (TopicIF) ContextUtils.getSingleValue("photo", pageContext);
LocatorIF loc = (LocatorIF) topic.getSubjectLocators().iterator().next();
String file = loc.getAddress().substring(6);
new File(file).delete();

// 2. Delete the topic
topic.remove();

// 3. Redirect somewhere else
%>
<tolog:if var="nextphoto">
  <%
    response.sendRedirect("/tmphoto/photo.jsp?id=" +
                          request.getParameter("photo"));
  %>
</tolog:if>
</tolog:context>
