package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Candle extends Entity{
	
	public OBJ_Candle(GamePanel gp) {
		super(gp);
		
		type = type_light;
		name = "Candle";
		down1 = setup("/objects/candle", gp.tileSize,gp.tileSize);
		description = "["+name+"]\nLights up your world \ncan burn for an eternity.";
		price = 200;
		lightRadius = 250;
	}

}
