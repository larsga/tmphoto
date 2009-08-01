
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.awt.geom.AffineTransform;

import javax.imageio.ImageIO;

/**
 * Processor which calls uses the java.awt APIs to scale an image.
 */
public class AWTProcessor implements ImageProcessor {

  public void scaleImage(File source, File destination, int maxside)
    throws IOException {
    ImageIO.setUseCache(false);
    BufferedImage bsrc = ImageIO.read(source);

    double ratio = (double) maxside / Math.max(bsrc.getHeight(), bsrc.getWidth());
    int width = (int) (bsrc.getWidth() * ratio);
    int height = (int) (bsrc.getHeight() * ratio);
    
    BufferedImage bdest = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
    Graphics2D g = bdest.createGraphics();
    AffineTransform at =
      AffineTransform.getScaleInstance(ratio, ratio);
    g.drawRenderedImage(bsrc, at);
    ImageIO.write(bdest, "JPG", destination);

    bsrc.flush();
    bdest.flush();
    g.dispose();
  }
}