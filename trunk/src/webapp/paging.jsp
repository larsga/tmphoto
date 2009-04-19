<tolog:set var="paging">
<c:if test="${list.hasMultiplePages}">
  <c:set var="pagelist" value="${list.pageList}"/>
<p>
  <!-- BACK BUTTON -->
  <c:if test="${pagelist.showBackButton}">
    <a href="<c:out value="${pagelink}"/>&n=<c:out value="${pagelist.previous}"/>"
      ><img src="resources/nav_prev.gif" border="0"></a>
  </c:if>
  <!-- LIST OF LINKS -->
  <c:forEach items="${pagelist.pages}" var="page">
    <c:choose>
      <c:when test="${page.current}">
        <b><c:out value="${page.pageNumber}"/></b>
      </c:when>
      <c:otherwise>
        <a href="<c:out value="${pagelink}"/>&n=<c:out value="${page.pageNumber}"/>"
          ><c:out value="${page.pageNumber}"/></a>
      </c:otherwise>
    </c:choose>
  </c:forEach>  
  <!-- FORWARD BUTTON -->
  <c:if test="${pagelist.showNextButton}">
    <a href="<c:out value="${pagelink}"/>&n=<c:out value="${pagelist.next}"/>"
      title="next"><img src="resources/nav_next.gif" border="0"></a>
  </c:if>
</c:if>
</tolog:set>
