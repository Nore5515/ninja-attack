/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

// Imports

import SpriteKit

//
//   ╔══════════════════════════════════════════════╗
// ╔══════════════════════════════════════════════════╗
// ║                                                  ║
// ║  VECTOR MATH FUNCTIONS                           ║
// ║                                                  ║
// ╚══════════════════════════════════════════════════╝
//   ╚══════════════════════════════════════════════╝
//

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

func distanceBetweenPoints(first: CGPoint, second: CGPoint) -> CGFloat{
  //return hypotf(second.x - first.x, second.y - first.y);
  return CGFloat(hypotf(Float(second.x - first.x), Float(second.y - first.y)));
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

//
//   ╔══════════════════════════════════════════════╗
// ╔══════════════════════════════════════════════════╗
// ║                                                  ║
// ║  STRUCTS                                         ║
// ║                                                  ║
// ╚══════════════════════════════════════════════════╝
//   ╚══════════════════════════════════════════════╝
//

struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1
  static let projectile: UInt32 = 0b10
  static let player   : UInt32 = 0b11
  static let monsterProjectile   : UInt32 = 0b101
}

struct Enemy {
  var enemyNoti: EnemyNoti
  var leftFacing: Bool
  var ranger: Bool
  var sightRadius: CGFloat
  var dangerCloseRadius: CGFloat
  var hp: Int
}

struct EnemyNoti {
  var enemyTarget : SKSpriteNode
  var distanceTo : CGFloat
  var cube : SKShapeNode
}

//
//   ╔══════════════════════════════════════════════╗
// ╔══════════════════════════════════════════════════╗
// ║                                                  ║
// ║  MAIN SCENE                                      ║
// ║                                                  ║
// ╚══════════════════════════════════════════════════╝
//   ╚══════════════════════════════════════════════╝
//

class GameScene: SKScene {
  
  // Variable Initialization
  private let player : SKSpriteNode = SKSpriteNode(imageNamed: "player")
  private var health : UInt32 = 100
  private var kills : UInt32 = 0
  private var noLefts : UInt32 = 0    // Tracks number of enemies between left-spawned enemies.
  private var noRanged : UInt32 = 0    // Tracks number of enemies between ranged enemies.
  private var enemyArray: [Enemy] = []
  private var killsLabel : SKLabelNode?
  private var healthLabel : SKLabelNode?
    
  //
  //   ╔══════════════════════════════════════════════╗
  //   ║  Effectively the Init Func                   ║
  //   ╚══════════════════════════════════════════════╝
  //
  override func didMove(to view: SKView) {
    
    backgroundColor = SKColor.white
    
    // Initialize kills label.
    let killsLabel = SKLabelNode(fontNamed:"Times New Roman")
    killsLabel.fontColor = UIColor.black
    killsLabel.text = String(kills)
    killsLabel.fontSize = 14
    killsLabel.position = CGPoint(x:size.width * 0.4, y:size.height * 0.4)
    
    // Initializes the health label.
    let healthLabel = SKLabelNode(fontNamed:"Times New Roman")
    healthLabel.fontColor = UIColor.black
    healthLabel.text = String(health)
    healthLabel.fontSize = 18
    healthLabel.position = CGPoint(x:size.width * 0.6, y:size.height * 0.4)

    
    // Saves kills label to class variable.
    self.killsLabel = killsLabel
    // Adds kills label to scene.
    if let killsLabel = self.killsLabel {
      self.addChild(killsLabel)
    }
    
    // Saves health label to class variable.
    self.healthLabel = healthLabel
    if let healthLabel = self.healthLabel {
      self.addChild(healthLabel)
    }

    // Set player's position and add to scene.
    player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    
    // Adds physics to player.
    player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
    player.physicsBody?.isDynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.player
    player.physicsBody?.contactTestBitMask = PhysicsCategory.none
    player.physicsBody?.collisionBitMask = PhysicsCategory.none
    
    addChild(player)
    
    // Set world physics.
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    // Repeating call to add monster.
    run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addMonster),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
    
    // Repeating call to redraw lines.
    run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(redrawLines),
            SKAction.wait(forDuration: 0.1)
            ])
        ))

  }
  
  //
  //   ╔══════════════════════════════════════════════╗
  //   ║  RNG Funcs.                                  ║
  //   ╚══════════════════════════════════════════════╝
  //
  
  // Get a random float value between 0 and 1.
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  // Get a random float value between two given values.
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return (random() * (max - min)) + min
  }
  
  //
  //   ╔══════════════════════════════════════════════╗
  //   ║  Redraw notification cubes.                  ║
  //   ╚══════════════════════════════════════════════╝
  //
  func redrawLines(){
    var index = -1
    for enemy in enemyArray{
      index = getIndexOfMonster(monster: enemy.enemyNoti.enemyTarget, list: enemyArray)
      if (index >= 0){

        // Calculates the new distance from player to monster.
        enemyArray[index].enemyNoti.distanceTo = distanceBetweenPoints(first: player.position, second: enemy.enemyNoti.enemyTarget.position)

        // Updates cube with new distance/position.
        updateCubeHandler(playerPosition: player.position, monsterPosition: enemy.enemyNoti.enemyTarget.position, distance: enemyArray[index].enemyNoti.distanceTo, cube: enemyArray[index].enemyNoti.cube)
        
      }
      else{
        print ("No enemy found in redraw lines.")
      }
    }
  }
  
  //
  //   ╔══════════════════════════════════════════════╗
  //   ║  Add monster function.                       ║
  //   ╚══════════════════════════════════════════════╝
  //
  func addMonster() {
    
    // Create sprite
    let monster = SKSpriteNode(imageNamed: "monster")
    
    // Assigns physics for the monster.
    monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
    monster.physicsBody?.isDynamic = true
    monster.physicsBody?.categoryBitMask = PhysicsCategory.monster
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
    monster.physicsBody?.collisionBitMask = PhysicsCategory.none

    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
    
    // Spawn monster on left 1 in 15 times, odds increasing the longer you go without a left spawning monster.
    var leftSpawn = random(min: 0.0, max: 15.0 + CGFloat(noLefts))
    leftSpawn = round(leftSpawn)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    if (leftSpawn >= 15.0){
      noLefts = 0
      monster.position = CGPoint(x: 0.0 - monster.size.width/2, y: actualY)
    }
    else{
      noLefts += 1
      monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
    }
    
    // Create and add new EnemyNoti
    let cube = createCube(playerPosition: player.position, monsterPosition: monster.position, distance: distanceBetweenPoints(first: player.position, second: monster.position) )
    let eNoti = EnemyNoti(enemyTarget: monster, distanceTo: distanceBetweenPoints(first: player.position, second: monster.position), cube: cube)
    
    // Creates an enemy object
    var enemyObj = Enemy(enemyNoti: eNoti, leftFacing: false, ranger: false, sightRadius: -1, dangerCloseRadius: -1, hp: 1)
   
    // Spawn 'rangers' 1 in 20 times, odds increasing over time.
    var rangerSpawn = random(min: 0.0, max: 20.0 + CGFloat(noRanged))
    rangerSpawn = round(leftSpawn)
    
    // If Ranger...
    // TODO: replace with 19
    if (rangerSpawn >= 9.0){
      enemyObj.ranger = true
      enemyObj.sightRadius = 200
      enemyObj.dangerCloseRadius = 10
      enemyObj.hp = 3
      noRanged = 0
    }
    else{
      noRanged += 1
    }
    
    // Adds enemy obj to array.
    enemyArray.append(enemyObj)
    
    // Update enemy count
    if let killsLabel = killsLabel {
      killsLabel.text = String(enemyArray.count)
    }
    
    // Add the monster to the scene
    addChild(monster)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(1.5), max: CGFloat(10.0))
    
    // Add angle variance
    let yMod = random(min: CGFloat(-60.0), max: CGFloat(60.0))
    
    // Cap the destination to the screen size.
    var cappedY = actualY + yMod
    // If it's destination is larger than the top of the screen...
    if (cappedY > (size.height-monster.size.width/2)){
      cappedY = size.height - monster.size.width/2
    }
    // ...or the bottom...
    if (cappedY < (monster.size.width/2)){
      cappedY = monster.size.width/2
    }
    
    // Create monster actions.
    let actionMove, loseAction : SKAction
    
    // Custom Move action if opposite moving (and not ranger.
    if (leftSpawn >= 15.0 && !enemyObj.ranger){
      print("OTHER WAY")
      actionMove = SKAction.move(to: CGPoint(x: size.width + monster.size.width/2, y: cappedY),
                                     duration: TimeInterval(actualDuration))
    }
    // Custom Move action if ranger.
    else if (enemyObj.ranger){
      print("RANGER")
      actionMove = SKAction.move(to: moveCloseToPlayer(playerPos: player.position, startingPos: monster.position, buffer: enemyObj.sightRadius), duration: TimeInterval(actualDuration))
    }
    // Regular move action of correct moving.
    else{
      actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY + yMod),
                                     duration: TimeInterval(actualDuration))
    }
    
    // Lose Actions
    loseAction = SKAction.run() {
      let monsterIndex = self.getIndexOfMonster(monster: monster, list: self.enemyArray)
      if (monsterIndex >= 0){
        self.enemyArray[monsterIndex].enemyNoti.cube.removeFromParent();
        self.enemyArray.remove(at: monsterIndex)
        
        // Damage stuff
        if (self.health <= 1){
          self.health -= 1
          let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
          let gameOverScene = GameOverScene(size: self.size, won: false)
          self.view?.presentScene(gameOverScene, transition: reveal)
        }else{
          self.health -= 1
        }
        
        // Update health count
        if let healthLabel = self.healthLabel {
          healthLabel.text = String(self.health)
        }
      }
      
      monster.removeFromParent()
    }
    
    // Add actions to monster (if not ranger)!
    if (!enemyObj.ranger){
      monster.run(SKAction.sequence([actionMove, loseAction]))
    }
    // Rangers should just start shooting after reaching dest.
    else{
      let actionShoot = SKAction.run() { [self] in
        addChild(self.createProjectile(destination: self.player.position, origin: monster.position, contactBitMask: PhysicsCategory.player, categoryBitMask: PhysicsCategory.monsterProjectile))
      }
      let seq = SKAction.sequence([actionShoot, SKAction.wait(forDuration: 2.0)])
      let actRepeat = SKAction.repeatForever(seq)
      
      monster.run(SKAction.sequence([actionMove, actRepeat]))
    }
    
  }
  
  //
  //   ╔═════════════════════════════════════════════════════════════════════╗
  //   ║  Get point from monster to player, ending 100 away from player.     ║
  //   ╚═════════════════════════════════════════════════════════════════════╝
  //
  func moveCloseToPlayer(playerPos: CGPoint, startingPos: CGPoint, buffer: CGFloat) -> CGPoint{
    // Get direction
    var direction = playerPos - startingPos
    // Get Distance
    let distance = distanceBetweenPoints(first: playerPos, second: startingPos)
    
    // Normalize direction to one length
    direction = direction.normalized()
    // Make direction be exactly distance-buffer length
    direction = direction * (distance-buffer)
    
    // Return startingPos + direction!
    return startingPos + direction
  }
  
  //
  //   ╔══════════════════════════════════════════════╗
  //   ║  When finger is removed from screen...       ║
  //   ╚══════════════════════════════════════════════╝
  //
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    
    // Set up initial location of projectile
    let projectile = createProjectile(destination: touchLocation, origin: player.position, contactBitMask: PhysicsCategory.monster, categoryBitMask: PhysicsCategory.projectile)
  
    // Add child
    addChild(projectile)
  }
  
  //
  //   ╔════════════════════════════════════════════════════╗
  //   ║  Create and return a projectile.                   ║
  //   ╚════════════════════════════════════════════════════╝
  //
  func createProjectile(destination: CGPoint, origin: CGPoint, contactBitMask: UInt32, categoryBitMask: UInt32) -> SKSpriteNode{
    // Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = origin
    
    // Set projectile physics.
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = categoryBitMask
    projectile.physicsBody?.contactTestBitMask = contactBitMask
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    // Determine offset of location to projectile
    let offset = destination - projectile.position
    
    // Get the direction of where to shoot
    let direction = offset.normalized()
    
    // Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 2000
    
    // Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // Create the actions
    let actionMove = SKAction.move(to: realDest, duration: 1.5)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    return projectile
  }
  
  //
  //   ╔════════════════════════════════════════════════════╗
  //   ║  What to do on projectile collision w/ monster.    ║
  //   ╚════════════════════════════════════════════════════╝
  //
  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    // print ("MONSTER COLLIDE")
    var enemy : Enemy
    
    // Find respective enemy.
    
    guard let enemyIndex = self.enemyArray.firstIndex(where: { $0.enemyNoti.enemyTarget == monster }) else {
      print("ENEMY NOT FOUND")
      return
    }
    enemy = self.enemyArray[enemyIndex]
    
    // Reduce enemy HP.
    print (enemy.hp)
    enemy.hp -= 1
    print (enemy.hp)
    
    self.enemyArray[enemyIndex] = enemy
    
    // Eliminate projectile.
    projectile.removeFromParent()
    
    // If enemy is dead...
    if (enemy.hp <= 0){
      // Increment kills
      kills += 1
      
      print ("Removing cube")
      enemy.enemyNoti.cube.removeFromParent()
      enemyArray.remove(at: enemyIndex)

      // Update enemy count label.
      if let killsLabel = killsLabel {
        killsLabel.text = String(enemyArray.count)
      }
      
      // Remove monster from scene.
      monster.removeFromParent()
    }
    
  }

  //
  //   ╔════════════════════════════════════════════════════╗
  //   ║  What to do on projectile collision w/ player.     ║
  //   ╚════════════════════════════════════════════════════╝
  //
  func projectileDidCollideWithPlayer(projectile: SKSpriteNode) {
    // print ("PLAYER COLLIDE")

    // Decrement health and remove projectile.
    if (health <= 1){
      health -= 1
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }else{
      health -= 1
    }
    projectile.removeFromParent()
      
    // Update health count
    if let healthLabel = self.healthLabel {
      healthLabel.text = String(health)
    }
  }

  //
  //   ╔═════════════════════════════════════════════════════════════════╗
  //   ║  Find monster's index in the enemy array, if it exists.         ║
  //   ╚═════════════════════════════════════════════════════════════════╝
  //
  
  func getIndexOfMonster(monster: SKSpriteNode, list: Array<Enemy>) -> Int
  {
    
    if let index = list.firstIndex(where: { $0.enemyNoti.enemyTarget == monster }) {
      return index
    }
    
    return -1
  }
  
  //
  //   ╔════════════════════════════════════════════════╗
  //   ║  Return the noticube from player to monster.   ║
  //   ╚════════════════════════════════════════════════╝
  //
  func createCube(playerPosition: CGPoint, monsterPosition: CGPoint, distance: CGFloat) -> SKShapeNode{
    
    // Get direction
    var direction = monsterPosition - playerPosition
    
    // Normalize direction to one length
    direction = direction.normalized()
    // Make direction exactly 50 length
    direction = direction * 50
    
    // Add cube!
    let cube = placeCube(cubePoint: playerPosition + direction, distance: distance, maxSize: 10)
    
    return (cube)
  }
  
  //
  //   ╔═══════════════════════════════════════════════════════╗
  //   ║  Updates the given cube to the new position/size.     ║
  //   ╚═══════════════════════════════════════════════════════╝
  //
  func updateCubeHandler(playerPosition: CGPoint, monsterPosition: CGPoint, distance: CGFloat, cube: SKShapeNode){
    
    // Get direction
    var direction = monsterPosition - playerPosition
    
    // Normalize direction to one length
    direction = direction.normalized()
    // Make direction exactly 50 length
    direction = direction * 50
    
    // Add cube!
    let cubePoint = playerPosition + direction
    updateCube(cubePoint: cubePoint, distance: distance, maxSize: 10, cube: cube)
  }
  
  //
  //   ╔═════════════════════════════════════════════╗
  //   ║  Returns and adds the notification cube.    ║
  //   ╚═════════════════════════════════════════════╝
  //
  func placeCube(cubePoint: CGPoint, distance: CGFloat, maxSize: CGFloat) -> SKShapeNode{
    
    // Create the size of the cube based on distance.
    var size = 15*(100/distance)
    // Cap cube size.
    if (size > maxSize){
      size = maxSize
    }
    
    // Create cube!
    let cube = SKShapeNode(rectOf: CGSize(width: size, height: size))
    cube.fillColor = SKColor.red
    cube.position = cubePoint

    // Add cube to scene, then return it.
    self.addChild(cube)
    return cube
  }
  
  //
  //   ╔═════════════════════════════════════════════╗
  //   ║  Updates the notification cube.             ║
  //   ╚═════════════════════════════════════════════╝
  //
  func updateCube(cubePoint: CGPoint, distance: CGFloat, maxSize: CGFloat, cube: SKShapeNode){
    
    // Create the size of the cube based on distance.
    var size = 15*(100/distance)
    // Cap cube size.
    if (size > maxSize){
      size = maxSize
    }
    
    // Update cube!
    cube.position = cubePoint
    cube.setScale(size)
    cube.fillColor = SKColor.red
  }
}


//
//   ╔══════════════════════════════════════════════╗
// ╔══════════════════════════════════════════════════╗
// ║                                                  ║
// ║  PHYSICS                                         ║
// ║                                                  ║
// ╚══════════════════════════════════════════════════╝
//   ╚══════════════════════════════════════════════╝
//

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
//    print ("First Body", firstBody.categoryBitMask)
//    print ("Monster", PhysicsCategory.monster)
//    print ("Player", PhysicsCategory.player)
//    print ("Projectile", PhysicsCategory.projectile)
//    print ("Monster Projectile", PhysicsCategory.monsterProjectile)
//    print (firstBody.categoryBitMask & PhysicsCategory.player == 0)
//    print (secondBody.categoryBitMask & PhysicsCategory.monsterProjectile == 0)
//    print ("Second Body", secondBody.categoryBitMask)
   
    // Collision between monster and projectile.
    if ((firstBody.categoryBitMask == PhysicsCategory.monster) &&
        (secondBody.categoryBitMask == PhysicsCategory.projectile)) {
      if let monster = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster)
      }
    }

    // Collision between monster projectile and player.
    if ((firstBody.categoryBitMask == PhysicsCategory.player) &&
       (secondBody.categoryBitMask == PhysicsCategory.monsterProjectile)) {
     if let projectile = secondBody.node as? SKSpriteNode {
       projectileDidCollideWithPlayer(projectile: projectile)
     }
    }

  }

}
