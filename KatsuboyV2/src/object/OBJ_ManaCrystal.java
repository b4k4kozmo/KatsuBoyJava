package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_ManaCrystal extends Entity{

	GamePanel gp;
	public static final String objName = "Mana Crystal";
	public OBJ_ManaCrystal(GamePanel gp) {
		super(gp);
		this.gp = gp;
		
		type = type_pickupOnly;
		name = objName;
		value = 1;
		down1 = setup("/objects/gem",gp.tileSize,gp.tileSize);
		image = setup("/objects/gem",gp.tileSize,gp.tileSize);
		image2 = setup("/objects/gem_empty",gp.tileSize,gp.tileSize);
	}
	public boolean use(Entity entity) {
		soundNumber = 20;
		setSound();
		gp.playSE(2);
		gp.ui.addMessage("Mana +" + value);
		gp.player.mana += value;
		return true;
	}
}
