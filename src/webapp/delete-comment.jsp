<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<%
response.setHeader("Cache-control", "no-cache");
// 1. Interpret parameter
  int id = Integer.parseInt(request.getParameter("id"));

// 2. Delete the comment
  CommentManager.deleteComment(id);

// 3. Redirect somewhere else
  response.sendRedirect(request.getHeader("Referer"));
%>
</tolog:context>
