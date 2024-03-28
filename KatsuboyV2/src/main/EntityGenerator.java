package main;

import entity.Entity;
import object.OBJ_Boots;
import object.OBJ_Candle;
import object.OBJ_Chest;
import object.OBJ_Coin;
import object.OBJ_Door;
import object.OBJ_Heart;
import object.OBJ_Kami_Shield;
import object.OBJ_Kamiaxe;
import object.OBJ_Kamibokken;
import object.OBJ_Key;
import object.OBJ_ManaCrystal;
import object.OBJ_Potion_Green;
import object.OBJ_Shield_Puffa;
import object.OBJ_Shuriken;
import object.OBJ_Snowball;
import object.OBJ_Sword_Normal;
import object.OBJ_Tent;

public class EntityGenerator {

	GamePanel gp;
	
	public EntityGenerator(GamePanel gp) {
		this.gp = gp;
	}
public Entity getObject(String itemName) {
		
		Entity obj = null;
		
		switch(itemName) {
		case OBJ_Candle.objName: obj = new OBJ_Candle(gp); break;
		case OBJ_Boots.objName: obj = new OBJ_Boots(gp); break;
		case OBJ_Kami_Shield.objName: obj = new OBJ_Kami_Shield(gp); break;
		case OBJ_Kamiaxe.objName: obj = new OBJ_Kamiaxe(gp); break;
		case OBJ_Kamibokken.objName: obj = new OBJ_Kamibokken(gp); break;
		case OBJ_Key.objName: obj = new OBJ_Key(gp); break;
		case OBJ_Door.objName: obj = new OBJ_Door(gp); break;
		case OBJ_Chest.objName: obj = new OBJ_Chest(gp); break;
		case OBJ_Potion_Green.objName: obj = new OBJ_Potion_Green(gp); break;
		case OBJ_Shield_Puffa.objName: obj = new OBJ_Shield_Puffa(gp); break;
		case OBJ_Sword_Normal.objName: obj = new OBJ_Sword_Normal(gp); break;
		case OBJ_Tent.objName: obj = new OBJ_Tent(gp); break;
		case OBJ_Coin.objName: obj = new OBJ_Coin(gp); break;
		case OBJ_Heart.objName: obj = new OBJ_Heart(gp); break;
		case OBJ_ManaCrystal.objName: obj = new OBJ_ManaCrystal(gp); break;
		case OBJ_Shuriken.objName: obj = new OBJ_Shuriken(gp); break;
		case OBJ_Snowball.objName: obj = new OBJ_Snowball(gp); break;
		}
		return obj;
	}
	
}
