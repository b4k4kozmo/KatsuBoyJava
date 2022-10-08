package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Coin extends Entity{
	
	GamePanel gp;
	public OBJ_Coin (GamePanel gp) {
		super(gp);
		this.gp = gp;
		
		type = type_pickupOnly;
		name = "Kami Coin";
		value = 1;
		down1 = setup("/objects/coin", gp.tileSize, gp.tileSize);
	}
	
	public boolean use(Entity entity) {
		
		gp.playSE(1);
		gp.ui.addMessage("You found "+value+" shiny "+name+"!");
		gp.player.coin += value;
		return true;
	}

}
