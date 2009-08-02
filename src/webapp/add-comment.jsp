<%@ include file="declarations.jsp"%>
<%
  String id = request.getParameter("id");
  String username = (String) session.getAttribute("username");
  String comment = request.getParameter("comment");
  String referrer = "photo.jsp?id=" + id;

  if (request.getParameter("preview") == null) {
    // user pressed "add"; so we do
    CommentManager.addComment(id, username, comment);
  } else {
    // user pressed "preview"; so we redirect back
    referrer += "&preview=" + net.ontopia.utils.URIUtils.urlEncode(comment, "utf-8") + "#comment";
  }

  // finished!
  response.sendRedirect(referrer);
%>
