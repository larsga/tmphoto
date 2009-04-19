<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:if var="nouser">
  <jsp:forward page="hidden.jsp"/>
</tolog:if>

<template:insert template='template.jsp'>
<template:put name='title'>
Users by votes
</template:put>

<template:put name="body">

<table>
<tr><th>User <th> <th>Votes <th> <th>Average

<%
  int total = 0;
  Iterator it = ScoreManager.getVotingStats().iterator();
  while (it.hasNext()) {
    ScoreManager.UserInList data = (ScoreManager.UserInList) it.next();
    pageContext.setAttribute("userdata", data);
%>

<tr>
<td><a href="user-favourites.jsp?user=<c:out value="${userdata.user}"/>"
      ><c:out value="${userdata.user}"/></a>
<td>&nbsp;&nbsp;&nbsp;
<td><c:out value="${userdata.votes}"/>
<% total += data.getVotes(); %>
<td>&nbsp;&nbsp;&nbsp;
<td><c:out value="${userdata.average}"/>

<% } %>

<tr><td>Total <td> <td><%= total %>
</table>

</template:put>
</template:insert>
</tolog:context>
