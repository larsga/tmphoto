<%--

This page just removes the session parameter used to set the current
filter, then returns to the referring page.

--%>
<%
  String attr = request.getParameter("attr");
  String origin = request.getHeader("Referer"); 
  session.setAttribute(attr, null);
  response.sendRedirect(origin);
%>
