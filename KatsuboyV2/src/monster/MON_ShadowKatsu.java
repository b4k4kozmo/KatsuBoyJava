package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;
import object.OBJ_Coin;
import object.OBJ_Heart;
import object.OBJ_Potion_Green;
import object.OBJ_Shuriken;
import object.OBJ_Snowball;

public class MON_ShadowKatsu extends Entity{
GamePanel gp;
	
	public MON_ShadowKatsu(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_monster;
		name = "Shadow";
		defaultSpeed = 1;
		speed = defaultSpeed;
		maxLife = 200;
		life = maxLife;
		attack = 7;
		defense = 4;
		exp = 600;
		projectile = new OBJ_Shuriken(gp);
		knockBackPower = 5;
		
		solidArea.x = 4;
		solidArea.y = 4;
		solidArea.width = 40;
		solidArea.height = 44;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		attackArea.width = 48;
		attackArea.height = 48;
		motion1_duration = 40;
		motion2_duration = 85;
		
		getImage();
		getAttackImage();
	}
	public void getImage() {
		
		up1 = setup("/monster/shadowkatsu_up_1",gp.tileSize,gp.tileSize);
		up2 = setup("/monster/shadowkatsu_up_2",gp.tileSize,gp.tileSize);
		down1 = setup("/monster/shadowkatsu_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/monster/shadowkatsu_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/monster/shadowkatsu_left_1",gp.tileSize,gp.tileSize);
		left2 = setup("/monster/shadowkatsu_left_2",gp.tileSize,gp.tileSize);
		right1 = setup("/monster/shadowkatsu_right_1",gp.tileSize,gp.tileSize);
		right2 = setup("/monster/shadowkatsu_right_2",gp.tileSize,gp.tileSize);
	}
	public void getAttackImage() {
		
		attackUp1 = setup("/monster/shadow_up_attack_1",gp.tileSize,gp.tileSize*2);
		attackUp2 = setup("/monster/shadow_up_attack_2",gp.tileSize,gp.tileSize*2);
		attackDown1 = setup("/monster/shadow_down_attack_1",gp.tileSize,gp.tileSize*2);
		attackDown2 = setup("/monster/shadow_down_attack_2",gp.tileSize,gp.tileSize*2);
		attackLeft1 = setup("/monster/shadow_left_attack_1",gp.tileSize*2,gp.tileSize);
		attackLeft2 = setup("/monster/shadow_left_attack_2",gp.tileSize*2,gp.tileSize);
		attackRight1 = setup("/monster/shadow_right_attack_1",gp.tileSize*2,gp.tileSize);
		attackRight2 = setup("/monster/shadow_right_attack_2",gp.tileSize*2,gp.tileSize);
	}
	public void setAction () {
		
		if(onPath == true) {
			
			// Check if stop chasing
			checkStopChasing(gp.player, 15, 100);
		
			// Search the direction to go
			searchPath(getGoalCol(gp.player),getGoalRow(gp.player));
			
			// Check if it shoot a projectile
			checkShooting(200,30);
		}
		else {
			// Check if it starts chasing
			checkStartChasing(gp.player, 5, 100); 
			
			// Get a random direction if not on path
			getRandomDirection();
		}
		
		// Check if it attacks
		if(attacking == false) {
			checkAttacking(30, gp.tileSize*4, gp.tileSize);
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
