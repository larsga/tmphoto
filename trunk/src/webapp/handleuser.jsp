<%
  String username = (String) session.getAttribute("username");
  if (username != null)
    ContextUtils.setSingleValue("username", pageContext, username);
  else
    ContextUtils.setSingleValue("nouser", pageContext, username);
  Logger.log(username, request);
%>
