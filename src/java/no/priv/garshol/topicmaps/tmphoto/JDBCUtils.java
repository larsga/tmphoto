
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
import net.ontopia.utils.OntopiaRuntimeException;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.TopicIF;

public class JDBCUtils {
  private static ConnectionPool pool;

  private static Statement getStatement() throws SQLException {
    if (pool == null)
      pool = new ConnectionPool();
    return pool.getStatement();
  }

  public static void dumpPool() {
    pool.debug();
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
        pool.replaceStatement(stmt);
        if (rs != null)
          rs.close();
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
        pool.replaceStatement(stmt);
        if (rs != null)
          rs.close();
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
        pool.replaceStatement(stmt);
        if (rs != null)
          rs.close();
      }
    }
  }
  
  public static void update(String query) throws SQLException {
    Statement stmt = null;
    try {
      stmt = getStatement();
      stmt.executeUpdate(query);
    } finally {
      pool.replaceStatement(stmt);
    }    
  } 

  public static String quote(String value) {
    if (value == null)
      return null;
    else
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

  // ----- CONNECTION POOL

  // all manipulation of the free[] and statements[] arrays (after the
  // constructor) takes place in synchronization blocks.  this ensures
  // that there are no race conditions.
  
  static class ConnectionPool {
    private static final int INITIAL_SIZE      = 0;
    private static final int MAX_SIZE          = 5;
    private static final long MAX_FREE_TIME    = 15 * 60 * 1000; // milliseconds
    private static final long REFRESH_INTERVAL = MAX_FREE_TIME * 3;

    private Statement[] statements;
    private boolean[] free;
    private long[] lastused;
    private int count; // number of allocated statements at the moment
    private long lastrefresh; // time of last refresh (currentTimeMillis())

    private ConnectionPool() {
      statements = new Statement[MAX_SIZE];
      free = new boolean[MAX_SIZE];
      lastused = new long[MAX_SIZE];
      for (int ix = 0; ix < INITIAL_SIZE; ix++)
        allocateNewStatement();
      lastrefresh = System.currentTimeMillis();
    }

    private Statement getStatement() {
      synchronized (this) {
        // protecting so that we don't get several threads refreshing at
        // the same time
        if (System.currentTimeMillis() - lastrefresh > REFRESH_INTERVAL)
          refresh();
      }
      
      int ix = -1;
      do {
        synchronized (this) {
          ix = findFreeStatement();
          if (ix == -1 && count < MAX_SIZE)
            ix = allocateNewStatement();

          if (ix != -1) {
            free[ix] = false;
            lastused[ix] = System.currentTimeMillis();
          }
        }

        // need to wait a bit before we try again
        if (ix == -1) {
          try {
            Thread.sleep(10);
          } catch (InterruptedException e) {
            // well, so what?
          }
        }
      } while (ix == -1);

      return statements[ix];
    }

    private int allocateNewStatement() {
      free[count] = true;
      lastused[count] = System.currentTimeMillis();
      statements[count++] = createStatement();
      return count - 1;
    }

    private int findFreeStatement() {
      for (int ix = 0; ix < count; ix++)
        if (free[ix])
          return ix;
      return -1;
    }

    private Statement createStatement() {
      try {
        Class.forName("org.postgresql.Driver");

        Connection conn = DriverManager.getConnection(JDBCURL, USER, PASSWORD);
        return conn.createStatement();
      } catch (Exception e) {
        throw new OntopiaRuntimeException(e);
      }
    }

    private synchronized void replaceStatement(Statement stmt) {
      for (int ix = 0; ix < count; ix++)
        if (statements[ix] == stmt) {
          free[ix] = true;
          return;
        }
      throw new OntopiaRuntimeException("Unknown statement returned!");
    }

    private void debug() {
      System.out.println("Connection pool has " + count + " statements");
      for (int ix = 0; ix < count; ix++)
        System.out.println("[" + ix + "]: " + free[ix] + " " + lastused[ix]);
      System.out.println("Time now: " + System.currentTimeMillis());
    }

    private void refresh() {
      System.out.println("Refreshing connection pool");
      debug();
      for (int ix = 0; ix < count; ix++) {
        if ((!free[ix] &&
             (System.currentTimeMillis() - lastused[ix] > MAX_FREE_TIME)) ||
            (free[ix] && !validate(ix))) {
          // the connection has either been out of the pool for too long,
          // or it doesn't work any more. therefore we close it and create
          // a new one to replace it.
          if (!free[ix])
            System.out.println("Statement " + ix + " out for too long");
          else
            System.out.println("Statement " + ix + " broken");
          
          try {
            Connection c = statements[ix].getConnection();
            statements[ix].close();
            c.close();
          } catch (SQLException e) {
          }
          statements[ix] = createStatement();
          lastused[ix] = System.currentTimeMillis();
          free[ix] = true;
        }
      }
      lastrefresh = System.currentTimeMillis();
    }

    private boolean validate(int ix) {
      try {
        Connection c = statements[ix].getConnection();
        c.getMetaData();
        return true;
      } catch (SQLException e) {
        return false;
      }
    }
  }
}
