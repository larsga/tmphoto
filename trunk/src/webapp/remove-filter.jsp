<%
  if (request.getParameter("filter") != null) {
    String id = request.getParameter("filter");
    session.setAttribute("filter", id);

    String origin = request.getRequestURL().toString() + "?" +
                    request.getQueryString();
    int ix = origin.indexOf('&');
    origin = origin.substring(0, ix);
    response.setHeader("Location", origin);
    response.sendError(HttpServletResponse.SC_MOVED_PERMANENTLY);
    return;
  }
%>
