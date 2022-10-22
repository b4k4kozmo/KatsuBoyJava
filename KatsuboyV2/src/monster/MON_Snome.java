package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;
import object.OBJ_Coin;
import object.OBJ_Heart;
import object.OBJ_Potion_Green;
import object.OBJ_Snowball;

public class MON_Snome extends Entity{

	GamePanel gp;
	
	public MON_Snome(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_monster;
		name = "Snome";
		defaultSpeed = 1;
		speed = defaultSpeed;
		maxLife = 12;
		life = maxLife;
		attack = 2;
		defense = 2;
		exp = 3;
		projectile = new OBJ_Snowball(gp);
		
		solidArea.x = 3;
		solidArea.y = 18;
		solidArea.width = 42;
		solidArea.height = 30;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		getImage();
	}
	
	public void getImage() {
		
		up1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		up2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		down1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		left2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		right1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		right2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
	}

	public void setAction () {
		
		if(onPath == true) {
			
			// Check if stop chasing
			checkStopChasing(gp.player, 15, 100);
		
			// Search the direction to go
			searchPath(getGoalCol(gp.player),getGoalRow(gp.player));
			
			// Check if it shoot a projectile
			checkShooting(100,30);
		}
		else {
			// Check if it starts chasing
			checkStartChasing(gp.player, 5, 100); 
			
			// Get a random direction if not on path
			getRandomDirection();
		}
	}
	public void damageReaction() {
		actionLockCounter = 0;
		onPath = true;
		
	}
	public void checkDrop() {
		
		// CAST A DIE
		int i = new Random().nextInt(100)+1;
		
		//SET THE MONSTER DROP
		if(i< 50) {
			dropItem(new OBJ_Coin(gp));
		}
		if (i >= 50 && 1 < 75) {
			dropItem(new OBJ_Potion_Green(gp));
		}
		if (i >= 74 && i < 100) {
			dropItem(new OBJ_Heart(gp));
		}
	}

}
