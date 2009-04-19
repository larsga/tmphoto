<%@ include file="declarations.jsp"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<%
  response.setHeader("Cache-control", "no-cache");
%>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:choose>
<tolog:when var="username">
Logout
</tolog:when>

<tolog:otherwise>
Login
</tolog:otherwise>
</tolog:choose>
</template:put>

<template:put name="body">

<form method="post" action="process-login.jsp">
<% if (request.getHeader("referer") != null) { %>
  <input type=hidden name=goto value="<%= request.getHeader("referer") %>">
<% } %>

<tolog:choose>
<tolog:when var="username">
<p>You are logged in as <b><tolog:out var="username"/></b>.
<p><input type=submit name=logout value="Log out">
</tolog:when>

<tolog:otherwise>
<table>
<tr><td>Username
    <td><input type=text name=username size=10>
<tr><td>Password
    <td><input type=password name=password size=10>
<tr><td colspan=2>
    <input type=submit name=login value="Login">
    <input type=submit name=cancel value="Cancel">
</table>

<p>Don't have a password? If so, email me, and I'll send you one.
</tolog:otherwise>
</tolog:choose>
</form>

</template:put>

</template:insert>
</tolog:context>
