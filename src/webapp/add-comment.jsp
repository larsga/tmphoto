<%@ include file="declarations.jsp"%>
<%
  String id = request.getParameter("id");
  String username = (String) session.getAttribute("username");
  String comment = net.ontopia.utils.StringUtils.transcodeUTF8(request.getParameter("comment"));
  String referrer = "photo.jsp?id=" + id;
  String name = request.getParameter("name");
  String url = request.getParameter("url");
  String email = request.getParameter("email");
  boolean isspam = request.getParameter("clever2") != null;
  boolean isnotspam = request.getParameter("clever") != null;
  boolean spam = (!isspam && isnotspam && username == null);

  if (request.getParameter("preview") == null) {
    // user pressed "add"; so we do

    if (username != null)
      // user is logged in
      CommentManager.addComment(id, username, comment);
    else {
      // user is not logged in	    
      if (spam)
        // failed spam check
	out.write("<p>This is spam. Go away.</p>");
      else {
        CommentManager.addComment(id, name, email, url, comment);
	referrer += "&commentadded=true";
      }
    }
  } else {
    // user pressed "preview"; so we redirect back
    referrer += "&preview=" + net.ontopia.utils.URIUtils.urlEncode(comment, "utf-8");
    if (username == null) {
      if (name != null)
        referrer += "&name=" + name;
      if (email != null)
        referrer += "&email=" + email;
      if (url != null)
        referrer += "&url=" + url;
    }
    referrer += "#comment";
  }

  // finished!
  if (!spam)
    response.sendRedirect(referrer);
  else
    out.write("<p>Spam is true, somehow.");
%>
