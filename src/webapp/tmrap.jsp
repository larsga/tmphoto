<%--
  // Contract: variable varname must refer to the Ontopia variable holding
               the topic to look up

  try {
    TopicIF event = (TopicIF) ContextUtils.getSingleValue(varname, pageContext);
    Collection servers = new ArrayList();
    servers.add(tmrap_url);
    TMRAP tmrap = new TMRAP(servers);
    Collection model = tmrap.query(event);
    pageContext.setAttribute("servers", model);
    pageContext.setAttribute("pages", tmrap.getAllPages(model));
%>
<c:if test="${not empty pages}">
<p><b>Blog entries:</b></p>

<ul>
<c:forEach items="${pages}" var="page">
  <li><a href="<c:out value="${page.URI}"/>"
    ><c:out value="${page.name}" escapeXml="false"/></a><br>
</c:forEach>
</ul>
</c:if>
<%
  } catch (java.io.IOException e) {
    out.write("<p><b>TMRAP error: </b> " + e + "</p>");
  }
--%>
