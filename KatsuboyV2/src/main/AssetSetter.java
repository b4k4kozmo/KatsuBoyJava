package main;

import entity.NPC_Merchant;
import entity.NPC_NanaMan;
import entity.NPC_OldMan;
import monster.MON_KamiJack;
import monster.MON_Slime;
import monster.MON_Snome;
import object.OBJ_Boots;
import object.OBJ_Candle;
import object.OBJ_Carbo;
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
import object.OBJ_Tent;
import tile_interactive.IT_DryTree;


public class AssetSetter {
	
	GamePanel gp;
	
	public AssetSetter(GamePanel gp) {
		this.gp = gp;
	}
	
	public void setObject() {
		
		int mapNum = 0;
		int i = 0;
		gp.obj[mapNum][i] = new OBJ_Coin(gp);
		gp.obj[mapNum][i].worldX = 50 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Carbo(gp);
		gp.obj[mapNum][i].worldX = 52 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Key(gp);
		gp.obj[mapNum][i].worldX = 96 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 96 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Coin(gp);
		gp.obj[mapNum][i].worldX = 96 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Coin(gp);
		gp.obj[mapNum][i].worldX = 97 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 90 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Kamibokken(gp);
		gp.obj[mapNum][i].worldX = 98 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Kami_Shield(gp);
		gp.obj[mapNum][i].worldX = 97 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Potion_Green(gp);
		gp.obj[mapNum][i].worldX = 89 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Heart(gp);
		gp.obj[mapNum][i].worldX = 95 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 91 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Kamiaxe(gp);
		gp.obj[mapNum][i].worldX = 94 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 91 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Door(gp);
		gp.obj[mapNum][i].worldX = 85 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Chest(gp, new OBJ_Key(gp));
		gp.obj[mapNum][i].worldX = 91 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 92 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Candle(gp);
		gp.obj[mapNum][i].worldX = 92 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 92 * gp.tileSize;
		i++;
		gp.obj[mapNum][i] = new OBJ_Tent(gp);
		gp.obj[mapNum][i].worldX = 92 * gp.tileSize;
		gp.obj[mapNum][i].worldY = 93 * gp.tileSize;
		i++;
	}
	public void setNPC() {
		int mapNum = 0;
		int i = 0;

		gp.npc[mapNum][i] = new NPC_OldMan (gp);
		gp.npc[mapNum][i].worldX = gp.tileSize*96;
		gp.npc[mapNum][i].worldY = gp.tileSize*95;
		i++;
		
		mapNum=1;
		i = 0;
		gp.npc[mapNum][i] = new NPC_NanaMan (gp);
		gp.npc[mapNum][i].worldX = gp.tileSize*11;
		gp.npc[mapNum][i].worldY = gp.tileSize*23;
		i++;
		gp.npc[mapNum][i] = new NPC_Merchant (gp);
		gp.npc[mapNum][i].worldX = gp.tileSize*26;
		gp.npc[mapNum][i].worldY = gp.tileSize*18;
		i++;
		
	}
	
	public void setMonster() {
		
		int mapNum = 0;
		int i = 0;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*82;
		gp.monster[mapNum][i].worldY = gp.tileSize*95;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*58;
		gp.monster[mapNum][i].worldY = gp.tileSize*79;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*8;
		gp.monster[mapNum][i].worldY = gp.tileSize*55;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*8;
		gp.monster[mapNum][i].worldY = gp.tileSize*51;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*8;
		gp.monster[mapNum][i].worldY = gp.tileSize*46;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*8;
		gp.monster[mapNum][i].worldY = gp.tileSize*35;
		i++;
		gp.monster[mapNum][i] = new MON_Slime(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*84;
		gp.monster[mapNum][i].worldY = gp.tileSize*93;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*80;
		gp.monster[mapNum][i].worldY = gp.tileSize*90;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*80;
		gp.monster[mapNum][i].worldY = gp.tileSize*88;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*80;
		gp.monster[mapNum][i].worldY = gp.tileSize*87;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*79;
		gp.monster[mapNum][i].worldY = gp.tileSize*87;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*78;
		gp.monster[mapNum][i].worldY = gp.tileSize*87;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*77;
		gp.monster[mapNum][i].worldY = gp.tileSize*87;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*77;
		gp.monster[mapNum][i].worldY = gp.tileSize*86;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*77;
		gp.monster[mapNum][i].worldY = gp.tileSize*86;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*76;
		gp.monster[mapNum][i].worldY = gp.tileSize*86;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*77;
		gp.monster[mapNum][i].worldY = gp.tileSize*85;
		i++;
		gp.monster[mapNum][i] = new MON_Snome(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*76;
		gp.monster[mapNum][i].worldY = gp.tileSize*87;
		i++;
		gp.monster[mapNum][i] = new MON_KamiJack(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*88;
		gp.monster[mapNum][i].worldY = gp.tileSize*77;
		i++;
		gp.monster[mapNum][i] = new MON_KamiJack(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*92;
		gp.monster[mapNum][i].worldY = gp.tileSize*73;
		i++;
		gp.monster[mapNum][i] = new MON_KamiJack(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*27;
		gp.monster[mapNum][i].worldY = gp.tileSize*79;
		i++;
		gp.monster[mapNum][i] = new MON_KamiJack(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*79;
		gp.monster[mapNum][i].worldY = gp.tileSize*52;
		i++;
		gp.monster[mapNum][i] = new MON_KamiJack(gp);
		gp.monster[mapNum][i].worldX = gp.tileSize*66;
		gp.monster[mapNum][i].worldY = gp.tileSize*45;
		i++;
		
	
	
	}
	public void setInteractiveTile() {
		int mapNum = 0;
		int i = 0;
		gp.iTile[mapNum][i] = new IT_DryTree(gp,86,97);i++;
		
	}
	
}
