package main;

import entity.NPC_NanaMan;
import entity.NPC_OldMan;
import monster.MON_KamiJack;
import monster.MON_Slime;
import monster.MON_Snome;
import object.OBJ_Boots;
import object.OBJ_Carbo;
import object.OBJ_Coin;
import object.OBJ_Heart;
import object.OBJ_Kami_Shield;
import object.OBJ_Kamiaxe;
import object.OBJ_Kamibokken;
import object.OBJ_Key;
import object.OBJ_ManaCrystal;
import object.OBJ_Potion_Green;
import tile_interactive.IT_DryTree;


public class AssetSetter {
	
	GamePanel gp;
	
	public AssetSetter(GamePanel gp) {
		this.gp = gp;
	}
	
	public void setObject() {
		
		int i = 0;
		gp.obj[i] = new OBJ_Coin(gp);
		gp.obj[i].worldX = 50 * gp.tileSize;
		gp.obj[i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Carbo(gp);
		gp.obj[i].worldX = 52 * gp.tileSize;
		gp.obj[i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Key(gp);
		gp.obj[i].worldX = 96 * gp.tileSize;
		gp.obj[i].worldY = 96 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Coin(gp);
		gp.obj[i].worldX = 96 * gp.tileSize;
		gp.obj[i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Coin(gp);
		gp.obj[i].worldX = 97 * gp.tileSize;
		gp.obj[i].worldY = 90 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Kamibokken(gp);
		gp.obj[i].worldX = 98 * gp.tileSize;
		gp.obj[i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Kami_Shield(gp);
		gp.obj[i].worldX = 97 * gp.tileSize;
		gp.obj[i].worldY = 98 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Potion_Green(gp);
		gp.obj[i].worldX = 89 * gp.tileSize;
		gp.obj[i].worldY = 97 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Heart(gp);
		gp.obj[i].worldX = 95 * gp.tileSize;
		gp.obj[i].worldY = 91 * gp.tileSize;
		i++;
		gp.obj[i] = new OBJ_Kamiaxe(gp);
		gp.obj[i].worldX = 94 * gp.tileSize;
		gp.obj[i].worldY = 91 * gp.tileSize;
		i++;
	}
	public void setNPC() {
		
		gp.npc[0] = new NPC_OldMan (gp);
		gp.npc[0].worldX = gp.tileSize*90;
		gp.npc[0].worldY = gp.tileSize*15;
	
		gp.npc[2] = new NPC_OldMan (gp);
		gp.npc[2].worldX = gp.tileSize*96;
		gp.npc[2].worldY = gp.tileSize*95;
		
		gp.npc[3] = new NPC_NanaMan (gp);
		gp.npc[3].worldX = gp.tileSize*93;
		gp.npc[3].worldY = gp.tileSize*80;
	}
	
	public void setMonster() {
		
		
		int i = 0;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*82;
		gp.monster[i].worldY = gp.tileSize*95;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*58;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*55;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*51;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*46;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*35;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*84;
		gp.monster[i].worldY = gp.tileSize*93;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*90;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*88;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*79;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*78;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*76;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*85;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*76;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*88;
		gp.monster[i].worldY = gp.tileSize*77;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*92;
		gp.monster[i].worldY = gp.tileSize*73;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*27;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*79;
		gp.monster[i].worldY = gp.tileSize*52;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*66;
		gp.monster[i].worldY = gp.tileSize*45;
		i++;
	
	
	}
	public void setInteractiveTile() {
		
		int i = 0;
		gp.iTile[i] = new IT_DryTree(gp,86,97);i++;
		
		
	}
	
}
