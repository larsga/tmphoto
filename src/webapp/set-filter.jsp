<%--

This page just sets the filter parameter used by some photo list page,
then returns to the referring page (which will be that photo list
page).

--%>
<%
  String id = request.getParameter("id");
  String origin = request.getHeader("Referer"); 
  session.setAttribute("filter", id);
  response.sendRedirect(origin);
%>
