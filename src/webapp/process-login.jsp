<%@ include file="declarations.jsp"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%
 // build user registry
 Map pws = new HashMap();
%>
<tolog:foreach query="
  instance-of($USER, op:Person),
  userman:username($USER, $NAME),
  userman:password($USER, $PASSWORD)?">
  <% pws.put(ContextUtils.getSingleValue("NAME", pageContext),
             ContextUtils.getSingleValue("PASSWORD", pageContext)); %>
</tolog:foreach>
<%
 // did the user press cancel?
 String cancel = request.getParameter("cancel");
 if (cancel != null) {
   response.sendRedirect("/tmphoto/");
   return;
 }

 // did the user want to log out?
 String logout = request.getParameter("logout");
 if (logout != null) {
   session.setAttribute("username", null);
   response.sendRedirect("/tmphoto/");
   return;
 }

 // ok, we are logging in
 String username = request.getParameter("username");
 String password = request.getParameter("password");
 String message = null;
 if (username == null)
   message = "You must provide a user name.";
 else if (password == null)
   message = "You must provide a password.";
 else {
   String correct = (String) pws.get(username);
   if (correct != null && correct.equals(password)) {
     session.setAttribute("username", username);

     String url = request.getParameter("goto");
     if (url == null)
       url = "/tmphoto/";

     response.sendRedirect(url);
     return;
   } else
     message = "Incorrect username or password.";
 }
%>
<template:insert template='template.jsp'>
<template:put name='title'>Login failure</template:put>

<template:put name="body">

<p><%= message %> <a href="login.jsp">Retry</a>.

</template:put>

</template:insert>
</tolog:context>
