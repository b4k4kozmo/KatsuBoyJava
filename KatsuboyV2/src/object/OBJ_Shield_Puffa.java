package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Shield_Puffa extends Entity{

	public OBJ_Shield_Puffa(GamePanel gp) {
		super(gp);
		
		name = "Puffa Shield";
		down1 = setup("/objects/puffa",gp.tileSize,gp.tileSize);
		defenseValue = 2;
		description = "[" + name + "]\nPuffa....J?";
	}

}
