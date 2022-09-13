package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;

public class MON_Slime extends Entity{

	public MON_Slime(GamePanel gp) {
		super(gp);
		
		type = 2;
		name = "Slime";
		speed = 1;
		maxLife = 3;
		life = maxLife;
		
		solidArea.x = 6;
		solidArea.y = 24;
		solidArea.width = 36;
		solidArea.height = 24;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		getImage();
	}
	
	public void getImage() {
		
		up1 = setup("/monster/slime_down01");
		up2 = setup("/monster/slime_down02");
		down1 = setup("/monster/slime_down01");
		down2 = setup("/monster/slime_down02");
		left1 = setup("/monster/slime_down01");
		left2 = setup("/monster/slime_down02");
		right1 = setup("/monster/slime_down01");
		right2 = setup("/monster/slime_down02");
	}
	
	public void setAction () {
		
		actionLockCounter ++;
		
		if(actionLockCounter == 120) {
			
			Random random = new Random();
			int i = random.nextInt(100)+1; // pick a number between 1 and 100
			
			if(i < 25) {
				direction = "up";
			}
			if (i >25 && i <=50) {
				direction = "down";
			} 
			if (i > 50 && i <= 75 ) {
				direction = "left";
			}
			if (i > 75 && i <= 100 ) {
				direction = "right";
			}
			
			actionLockCounter= 0;
		}
	}

}
