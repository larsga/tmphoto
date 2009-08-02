
package no.priv.garshol.topicmaps.tmphoto;

import java.util.List;
import java.util.Iterator;
import java.util.Collection;
import java.util.ArrayList;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.DriverManager;

import net.ontopia.utils.StringUtils;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.TopicIF;

public class JDBCUtils {

  public static Statement getStatement() throws SQLException {
    try {
      Class.forName("org.postgresql.Driver");
    } catch (Exception e) {
      throw new net.ontopia.utils.OntopiaRuntimeException(e);
    }
    
    Connection conn = DriverManager.getConnection(JDBCURL, USER, PASSWORD);
    return conn.createStatement();
  }

  public static int queryForInt(String query, int default_) throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute(query);
      rs = stmt.getResultSet();
      if (rs.next())
        return rs.getInt(1);
      else
        return default_;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  public static double queryForDouble(String query, double default_) throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute(query);
      rs = stmt.getResultSet();
      if (rs.next())
        return rs.getDouble(1);
      else
        return default_;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  public static List queryForList(String query, RowMapperIF mapper)
    throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute(query);
      rs = stmt.getResultSet();
      List list = new ArrayList();
      while (rs.next()) {
        Object o = mapper.map(rs);
        if (o != null)
          list.add(o);
      }
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }
  
  public static void update(String query) throws SQLException {
    Statement stmt = null;
    try {
      stmt = getStatement();
      stmt.executeUpdate(query);
    } finally {
      Connection conn = stmt.getConnection();
      stmt.close();
      conn.close();
    }    
  } 

  public static String quote(String value) {
    return "'" + StringUtils.replace(value, "'", "''") + "'";
  }

  public static String toParamList(Collection topics) {
    StringBuffer buf = new StringBuffer();
    Iterator it = topics.iterator();
    while (it.hasNext()) {
      TopicIF topic = (TopicIF) it.next();
      buf.append("'" + getId(topic) + "'");
      if (it.hasNext())
        buf.append(", ");
    }
    return buf.toString();
  }

  public static String getId(TopicIF photo) {
    Iterator it = photo.getItemIdentifiers().iterator();
    while (it.hasNext()) {
      LocatorIF loc = (LocatorIF) it.next();
      String url = loc.getAddress();
      int pos = url.indexOf('#');
      if (pos != -1)
        return url.substring(pos + 1);
    }
    return null;
  }
  
  public interface RowMapperIF {

    public Object map(ResultSet rs) throws SQLException;
    
  }

  /**
   * Called by declarations.jsp, using values from web.xml.
   */
  public static void init(String jdbcurl, String user, String password) {
    JDBCURL = jdbcurl;
    USER = user;
    PASSWORD = password;
  }
  
  private static String JDBCURL;
  private static String USER;
  private static String PASSWORD;  
}
