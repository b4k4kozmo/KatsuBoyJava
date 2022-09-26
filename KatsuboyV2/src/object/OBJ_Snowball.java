package object;

import java.awt.Color;

import entity.Entity;
import entity.Projectile;
import main.GamePanel;

public class OBJ_Snowball extends Projectile {

	GamePanel gp;
	
	public OBJ_Snowball(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		name = "Snow-ball";
		speed = 4;
		maxLife = 40;
		life = maxLife;
		attack = 3;
		useCost = 1;
		alive = false;
		getImage();
	}
	
	public void getImage() {
		up1 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		up2 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		down1 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		down2 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		left1 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		left2 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		right1 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
		right2 = setup("/projectile/snowball1",gp.tileSize,gp.tileSize);
	}

	public boolean haveResource(Entity user) {
	
		boolean haveResource = false;
		if(user.ammo >= useCost) {
			haveResource = true;
		}
		return haveResource; 
	}
	public void subtractResource(Entity user) {
	user.ammo -= useCost;
	
	}
	public Color getParticleColor() {
		Color color = gp.ui.kamiwhite;
		return color;
	}
	public int getParticleSize() {
		int size = 10; // pixel size
		return size;
	}
	public int getParticleSpeed() {
		int speed = 1;
		return speed;
	}
	public int getParticleMaxLife() {
		int maxLife = 20;
		return maxLife;
	}
}