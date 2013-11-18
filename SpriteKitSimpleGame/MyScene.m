//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Meera Sundar on 5/1/13.
//  Copyright (c) 2013 com.behagdev. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

static const uint32_t projectileCategory = 0x1 << 0;
static const uint32_t monsterCategory    = 0x1 << 1;

@interface MyScene()

@property (nonatomic) SKSpriteNode * player;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monstersDestroyed;
@end


static inline CGPoint rwAdd(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
    
}

static inline CGPoint rwMult(CGPoint a, float b)
{
    return CGPointMake(a.x * b, a.y * b);
}


static inline float rwLength(CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint rwNormalize(CGPoint a){
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
    
}


@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if(self = [super initWithSize:size])
    {
        //2
        NSLog(@"Size: %@", NSStringFromCGSize(size));
        //3
        self.backgroundColor = [SKColor colorWithRed:1.0 green: 1.0 blue: 1.0 alpha:1.0];
        
        //4
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        
        self.player.position = CGPointMake(self.frame.size.width/2, self.player.size.height/2);
        [self addChild:self.player];
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
    }
    return self;
}

-(void)addMonster
{
    //Create Sprite
    SKSpriteNode *monster =[SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    monster.physicsBody.dynamic = YES;
    monster.physicsBody.categoryBitMask = monsterCategory;
    monster.physicsBody.contactTestBitMask = projectileCategory;
    monster.physicsBody.collisionBitMask = 0;
    
    
    int minY = monster.size.height / 2;
    int maxY = self.frame.size.height - monster.size.height / 2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    
    int minX = monster.size.width / 2;
    int maxX = self.frame.size.width - monster.size.width / 2;
    int rangeX = maxX - minX;
    int actualX = (arc4random() % rangeX) + minX;
    
    
    //Set initial position of the monster
   // monster.position = CGPointMake(self.frame.size.width + monster.size.width /2, actualY);
    
    
    monster.position = CGPointMake(actualX,  self.frame.size.height);
    
    [self addChild:monster];
    
   //Determine speed of the monster
    int minDuration = 5.0;
    int maxDuration = 7.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    //Create the actions
    //SKAction * actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY) duration:actualDuration];
    SKAction *actionMove = [SKAction moveTo:CGPointMake(actualX, -self.frame.size.height/2) duration:actualDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];

    SKAction *loseAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene * gameOverScene = [[GameOverScene alloc]initWithSize:self.size won:NO];
        [self.view presentScene:gameOverScene transition:reveal];
    }];
    
    [monster runAction:[SKAction sequence:@[actionMove,loseAction,actionMoveDone]]];
}

-(void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    if(self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}


-(void)update:(NSTimeInterval)currentTime
{
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if(timeSinceLast > 1) {
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }

    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}



- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {

   //[self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];

    // 1 - Choose one of the touches to work with
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    // 2 - Set up initial location of projectile
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    projectile.position = self.player.position;
    
    
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width / 2];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = monsterCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    
    
    // 3 - Determine offset of location to projectile
    CGPoint offset = rwSub(location, projectile.position);
    
    // 4 - Bailout if you are shooting backward or downward
    if (offset.x <=0) return;
    
    //5 Add projectile to the screen
    [self addChild:projectile];
    
    // 6 - Get direction of shooting
    CGPoint direction = rwNormalize(offset);
    
    //7 Make it shoot far enough to be guaranteed off screen
    CGPoint shootAmount = rwMult(direction, 1000);
    
    //8 Add the shoot amount to current position
    CGPoint realDest = rwAdd(shootAmount, projectile.position);
    
    //9 Create actions
    float velocity = 480.0 / 1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [projectile runAction: [SKAction sequence:@[actionMove,actionMoveDone]]];
    
}

-(void)projectile:(SKSpriteNode * ) projectile didCollideWithMonster: (SKSpriteNode *) monster
{
    NSLog(@"Hit");
    [projectile removeFromParent];
    [monster removeFromParent];
    self.monstersDestroyed++;
    if(self.monstersDestroyed > 30)
    {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        [self.view presentScene:gameOverScene transition:reveal];
        
    }
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if((firstBody.categoryBitMask & projectileCategory) != 0 && (secondBody.categoryBitMask & monsterCategory) != 0)
    {
        [self projectile:(SKSpriteNode *)firstBody.node didCollideWithMonster:(SKSpriteNode*)secondBody.node];
    }
    
}


@end
