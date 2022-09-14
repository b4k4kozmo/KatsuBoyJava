package main;

public class EventHandler {

	GamePanel gp;
	EventRect eventRect[][];
	
	int prevEventX, prevEventY;
	boolean canTouchEvent = true;
	
	
	public EventHandler(GamePanel gp) {
		this.gp = gp;
		
		eventRect = new EventRect[gp.maxWorldCol][gp.maxWorldRow];
		
		int col = 0;
		int row = 0;
		while(col < gp.maxWorldCol && row < gp.maxWorldRow) {
			
			eventRect[col][row] = new EventRect();
			eventRect[col][row].x = 23;
			eventRect[col][row].y = 23;
			eventRect[col][row].width = 12;
			eventRect[col][row].height = 12;
			eventRect[col][row].eventRectDefaultX = eventRect[col][row].x;
			eventRect[col][row].eventRectDefaultY = eventRect[col][row].y;
			
			col++;
			if(col == gp.maxWorldCol) {
				col=0;
				row++;
			}
		}	
	}
	
	public void checkEvent() {
		
		// check if player character is more than 1 tile away from last event
		
		int xDistance = Math.abs(gp.player.worldX - prevEventX);
		int yDistance = Math.abs(gp.player.worldY - prevEventY);
		int distance = Math.max(xDistance, yDistance);
		if(distance > gp.tileSize) {
			canTouchEvent = true;
		}
		
		
		
		if(canTouchEvent == true) {
			if(hit(95,95, "any") == true) { damagePit(95, 95, gp.dialogueState); }
			if(hit(5, 71, "down") == true) { healingPool(5, 71, gp.dialogueState); }
			if(hit(97,97, "any") == true) { teleport(97,97, gp.dialogueState); }
		}
		
	}
	
	public boolean hit(int col, int row, String reqDirection) {
	
		boolean hit= false;
	
		gp.player.solidArea.x = gp.player.worldX + gp.player.solidArea.x;
		gp.player.solidArea.y = gp.player.worldY + gp.player.solidArea.y;
		eventRect[col][row].x = col*gp.tileSize+eventRect[col][row].x; 
		eventRect[col][row].y = row*gp.tileSize+eventRect[col][row].y; 
	
		if(gp.player.solidArea.intersects(eventRect[col][row]) && eventRect[col][row].eventDone == false) {
			if(gp.player.direction.contentEquals(reqDirection) || reqDirection.contentEquals("any")) {
				hit = true;
				
				prevEventX = gp.player.worldX;
				prevEventY = gp.player.worldY;
		}
	}
	
		gp.player.solidArea.x = gp.player.solidAreaDefaultX;
		gp.player.solidArea.y = gp.player.solidAreaDefaultY;
		eventRect[col][row].x = eventRect[col][row].eventRectDefaultX;
		eventRect[col][row].y = eventRect[col][row].eventRectDefaultY;
	
		return hit;
	}
	public void teleport(int col, int row, int gameState) {
		
		gp.gameState = gameState;
		gp.ui.currentDialogue = "Surprise!";
		gp.player.worldX = gp.tileSize*5;
		gp.player.worldY = gp.tileSize*70;
		
		
	}
	public void damagePit(int col, int row, int gameState) {
		gp.gameState = gameState;
		gp.ui.currentDialogue = "Ouch! You fell down";
		gp.player.life -= 1;
//		eventRect[col][row].eventDone = true;
		canTouchEvent = false;
	}
	public void healingPool(int col, int row, int gameState) {
		
		if(gp.keyH.enterPressed == true) {
			gp.gameState = gameState;
			gp.ui.currentDialogue = "Mmmmm... that was tasty. \nYou feel refreshed.";
			gp.player.life = gp.player.maxLife;
			
		}
		
		
	}
		
}
