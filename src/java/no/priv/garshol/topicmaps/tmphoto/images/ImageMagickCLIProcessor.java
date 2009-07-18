
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;

/**
 * Processor which calls ImageMagick on the command-line.
 */
public class ImageMagickCLIProcessor implements ImageProcessor {

  public void scaleImage(File source, File destination, int maxside)
    throws IOException {
    String size = "" + maxside + "x" + maxside;
    String[] cmd = new String[] {"convert",
                                 "-size",
                                 size,
                                 "-resize",
                                 size,
                                 source.getPath(),
                                 destination.getPath() };
    Process convert = Runtime.getRuntime().exec(cmd, null, null);
    try {
      convert.waitFor();
    } catch (InterruptedException e) {
    }
  }

}