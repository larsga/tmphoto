<%@ page language="java" 
    import="java.text.*"
%><%!
  private final static NumberFormat formatter =
    new DecimalFormat("###,###,###,###");
%>
     <p class="comment">Memory used by the Java Virtual Machine in
        which this web application is running:</p>
     <table cellspacing="5">
       <%
         long free = Runtime.getRuntime().freeMemory();
         long tot = Runtime.getRuntime().totalMemory();
       %>
       <tr class="comment">
         <td rowspan="2">&nbsp; &nbsp;</td>
         <td>Free Memory:</td>
         <td align="right"><%= formatter.format(free) %> bytes</td>
       </tr>
       <tr class="comment">
         <td>Allocated Memory:</td>
         <td align="right"><%= formatter.format(tot) %> bytes</td>
       </tr>
     </table>
