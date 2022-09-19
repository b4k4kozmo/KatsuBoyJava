package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Shield_Puffa extends Entity{

	public OBJ_Shield_Puffa(GamePanel gp) {
		super(gp);
		
		type = type_shield;
		name = "Puffa Shield";
		down1 = setup("/objects/puffa",gp.tileSize,gp.tileSize);
		defenseValue = 1;
		description = "[" + name + "]\nPuffa....J?";
	}

}
