package environment;

import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RadialGradientPaint;
import java.awt.Shape;
import java.awt.geom.Area;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;

import main.GamePanel;

public class Lighting {

	GamePanel gp;
	BufferedImage darknessFilter;
	public int dayCounter;
	public float filterAlpha = 0;
	
	public final int day = 0;
	public final int dusk = 1;
	public final int night = 2;
	public final int dawn = 3;
	public int dayState = day;
	
	public Lighting(GamePanel gp) {
		this.gp = gp;
		setLightSource();
	
	}
	public void setLightSource() {
		
		// Create a buffered image
		darknessFilter = new BufferedImage(gp.screenWidth, gp.screenHeight, BufferedImage.TYPE_INT_ARGB);
		Graphics2D g2 = (Graphics2D)darknessFilter.getGraphics();
		
		
		if(gp.player.currentLight == null) {
			g2.setColor(new Color(26,2,43,240));
		}
		else {
			// Get the center x and y of the light circle
			int centerX = gp.player.screenX + (gp.tileSize)/2;
			int centerY = gp.player.screenY + (gp.tileSize)/2;
			
			// Create a gradation effect within the light circle
			Color color[]  = new Color[5];
			float fraction[] = new float[5];
			
			color[0] = new Color(26,2,43,25); //kamiblack at various opacities 
			color[1] = new Color(26,2,43,75);
			color[2] = new Color(26,2,43,150);
			color[3] = new Color(26,2,43,225);
			color[4] = new Color(26,2,43,240);
			
			fraction[0] = 0f;
			fraction[1] = 0.25f;
			fraction[2] = 0.5f;
			fraction[3] = 0.75f;
			fraction[4] = 1f;
			
			// Create a gradation paint setting for the light circle
			RadialGradientPaint gPaint = new RadialGradientPaint(centerX, centerY, gp.player.currentLight.lightRadius, fraction, color);
			
			// Set the gradient data for g2
			g2.setPaint(gPaint);
		}

		
		g2.fillRect(0, 0, gp.screenWidth, gp.screenHeight);
		
		g2.dispose();
	}
	public void update() {
		
		if(gp.player.lightUpdated == true) {
			setLightSource();
			gp.player.lightUpdated = false;
		}
		
		//Check the state of the day
		if(dayState == day) {
			
			dayCounter++;
			
			if(dayCounter > 9000) {
				dayState = dusk;
				dayCounter = 0;
			}
		}
		if(dayState == dusk) {
			
			filterAlpha += 0.001f;
			
			if(filterAlpha > 1f) {
				filterAlpha = 1f;
				dayState = night;
			}
		}
		if(dayState == night) {
			
			dayCounter++;
			
			if(dayCounter > 4800) {
				dayState = dawn;
				dayCounter = 0;
			}
		}
		if(dayState == dawn) {
			
			filterAlpha -= 0.001f;
			
			if(filterAlpha < 0f) {
				filterAlpha = 0f;
				dayState = day;
			}
		}
	}
	public void draw(Graphics2D g2) {
		
		g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, filterAlpha));
		g2.drawImage(darknessFilter, 0, 0, null);
		g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 1f));
		
		// DEBUG
		String situation = "";
		
		switch(dayState) {
		case day: situation = "Day"; break;
		case dusk: situation = "Dusk"; break;
		case night: situation = "Night"; break;
		case dawn: situation = "Dawn"; break;
		}
		g2.setColor(gp.ui.kamiwhite);
		g2.setFont(g2.getFont().deriveFont(50f));
		g2.drawString(situation, 800, 500);
	}
}
