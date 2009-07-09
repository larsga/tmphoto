<%@ include file="declarations.jsp"%>

<html>
<head>
  <title><template:get name="title"/></title> 
  <link rel="stylesheet" type="text/css" href="resources/stylesheet.css"></link>
  <link rel="alternate" type="application/rss+xml" title="Event RSS" 
      href="http://www.garshol.priv.no/tmphoto/rss.jsp">
  <link rel="alternate" type="application/rss+xml" title="Eventless photos RSS" 
      href="http://www.garshol.priv.no/tmphoto/rss-eventless.jsp">
  </link>
  <meta http-equiv="content-type" content="text/html; charset=utf-8"></meta>
  <template:get name="headertags"/>
  <script type="text/javascript" src="resources/swap.js"></script>
</head>

<body <template:get name="bodyattrs"/>>

<table width="100%"><tr><td>
  <h1><template:get name="title"/></h1>
<td align=right class=linkbar>
  <a href="/tmphoto/">Home</a> |
  <a href="people.jsp">People</a> |
  <a href="events.jsp">Events</a> |
  <a href="places.jsp">Places</a> |
  <a href="categories.jsp">Categories</a> |
  <a href="search-form.jsp">Search</a> |
  <tolog:choose>
    <tolog:when var="nouser">
      <a href="login.jsp">Log in</a>
    </tolog:when>
    <tolog:otherwise>
      <a href="login.jsp">Log out</a>
    </tolog:otherwise>
  </tolog:choose><br>
  <tolog:if var="username">
  <tolog:if query='{ %username% = "larsga" | %username% = "stine" |
                     %username% = "silje" }?'>
    <a href="user-votes.jsp">Vote stats</a> |
    <a href="recent-votes.jsp">Recent votes</a>
  </tolog:if>
  </tolog:if>
</table>

<template:get name="body"/>

<p>
<hr>

<address>
<a href="http://code.google.com/p/tmphoto/">tmphoto</a> app built with 
<a href="http://www.ontopia.net">Ontopia</a>.
<%
  Object username = session.getAttribute("username");
  if (username != null) {
%>
  You are logged in as <b><%= username %></b>.
  <a href="login.jsp">Log out</a>.
<%
  } else {
%>
  You are <b>not logged in</b>.
  <a href="login.jsp">Log in</a>.
<%
  }
%>
<a href="terms.jsp">Using these photos</a>.
</address>
</body>
</html>

