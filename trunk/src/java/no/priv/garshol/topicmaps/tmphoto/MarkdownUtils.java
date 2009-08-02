
package no.priv.garshol.topicmaps.tmphoto;

import javax.servlet.jsp.PageContext;
import net.ontopia.topicmaps.nav2.utils.ContextUtils;
import com.petebevin.markdown.MarkdownProcessor;

public class MarkdownUtils {
  private static MarkdownProcessor proc = new MarkdownProcessor();

  public static String format(String markdown) {
    return proc.markdown(markdown);
  }

  public static String format(PageContext pageContext, String variable) {
    return format((String) ContextUtils.getSingleValue(variable, pageContext));
  }
}
