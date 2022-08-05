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
}

struct EnemyNoti {
  var enemyTarget : SKSpriteNode
  var distanceTo : CGFloat
  var eCube : EnemyCube
}

struct EnemyCube{
  var line : SKShapeNode
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
  private var kills : UInt32 = 0
  private var noLefts : UInt32 = 0    // Tracks number of enemies between left-spawned enemies.
  private var enemyNotiArray: [EnemyNoti] = []
  private var killsLabel : SKLabelNode?
    
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
    
    // Saves kills label to class variable.
    self.killsLabel = killsLabel
    // Adds kills label to scene.
    if let killsLabel = self.killsLabel {
      self.addChild(killsLabel)
    }

    // Set player's position and add to scene.
    player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
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
    for enemy in enemyNotiArray{
      index = getIndexOfMonster(monster: enemy.enemyTarget, list: enemyNotiArray)
      if (index >= 0){
        // Removes the cube and line from the parent.
        enemyNotiArray[index].eCube.cube.removeFromParent()
        enemyNotiArray[index].eCube.line.removeFromParent()
        // Calculates the new distance from player to monster.
        enemyNotiArray[index].distanceTo = distanceBetweenPoints(first: player.position, second: enemy.enemyTarget.position)
        // Creates a new line and cube.
        let (line, cube) = createLine(playerPosition: player.position, monsterPosition: enemy.enemyTarget.position, distance: enemyNotiArray[index].distanceTo)
        // Creates a new EnemyCube with the new line and cube, then reassigns the enemyNoti's eCube.
        let enemyCube = EnemyCube(line: line, cube: cube)
        enemyNotiArray[index].eCube = enemyCube
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
    let (line, cube) = createLine(playerPosition: player.position, monsterPosition: monster.position, distance: distanceBetweenPoints(first: player.position, second: monster.position) )
    let enemyCube = EnemyCube(line: line, cube: cube)
    enemyNotiArray.append(EnemyNoti(enemyTarget: monster, distanceTo: distanceBetweenPoints(first: player.position, second: monster.position), eCube: enemyCube))
    
    // Update enemy count
    if let killsLabel = killsLabel {
      killsLabel.text = String(enemyNotiArray.count)
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
    
    //
    //   ╔══════════════════════════════════════════════╗
    //   ║  Create monster actions.                     ║
    //   ╚══════════════════════════════════════════════╝
    //
    let actionMove, loseAction, actionMoveDone : SKAction
    
    // Custom Move action if opposite moving.
    if (leftSpawn >= 15.0){
      print("OTHER WAY")
      actionMove = SKAction.move(to: CGPoint(x: size.width + monster.size.width/2, y: cappedY),
                                     duration: TimeInterval(actualDuration))
    }
    // Regular move action of correct moving.
    else{
      actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY + yMod),
                                     duration: TimeInterval(actualDuration))
    }
    
    // Lose Actions
    loseAction = SKAction.run() {
      let monsterIndex = self.getIndexOfMonster(monster: monster, list: self.enemyNotiArray)
      if (monsterIndex >= 0){
        self.enemyNotiArray[monsterIndex].eCube.cube.removeFromParent();
        self.enemyNotiArray.remove(at: monsterIndex)
      }
      monster.removeFromParent()
    }
    
    // Action to do when movement is over.
    actionMoveDone = SKAction.removeFromParent()
    
    // Add actions to monster!
    monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
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
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
    // Set projectile physics.
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true

    
    // Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // Add child
    addChild(projectile)
    
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
  }

  //
  //   ╔════════════════════════════════════════════════════╗
  //   ║  What to do on projectile collision w/ monster.    ║
  //   ╚════════════════════════════════════════════════════╝
  //
  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    // Increment kills and remove projectile.
    kills += 1
    projectile.removeFromParent()
    
    // If monster is within enemyNotiArray...
    let monsterIndex = getIndexOfMonster(monster: monster, list: enemyNotiArray)
    // Remove it's line, cube and the monster itself.
    if (monsterIndex >= 0){
      enemyNotiArray[monsterIndex].eCube.line.removeFromParent();
      enemyNotiArray[monsterIndex].eCube.cube.removeFromParent();
      enemyNotiArray.remove(at: monsterIndex)
    }
    
    // Update enemy count label.
    if let killsLabel = killsLabel {
      killsLabel.text = String(enemyNotiArray.count)
    }
    
    // Remove monster from scene.
    monster.removeFromParent()
  }

  //
  //   ╔═════════════════════════════════════════════════════════════════╗
  //   ║  Find monster's index in the enemyNoti array, if it exists.     ║
  //   ╚═════════════════════════════════════════════════════════════════╝
  //
  func getIndexOfMonster(monster: SKSpriteNode, list: Array<EnemyNoti>) -> Int
  {
    var index = 0
    for enemyNoti in list{
      // If monster is found, return index.
      if (enemyNoti.enemyTarget == monster){
        return index
      }
      // Otherwise, increment.
      else{
        index += 1
      }
    }
    return -1
  }
  
  //
  //   ╔════════════════════════════════════════════════════════════════════════╗
  //   ║  Return the line from player to monster, as well as the noti cube.     ║
  //   ╚════════════════════════════════════════════════════════════════════════╝
  //
  func createLine(playerPosition: CGPoint, monsterPosition: CGPoint, distance: CGFloat) -> (shape: SKShapeNode, cube: SKShapeNode){
    
    // Get direction
    var direction = monsterPosition - playerPosition
    
    // Normalize direction to one length
    direction = direction.normalized()
    // Make direction exactly 50 length
    direction = direction * 50
    
    // Initialize a mutable path
    let line_path:CGMutablePath = CGMutablePath()
    // Start the path at the player
    line_path.move(to: playerPosition)
    // Point it towards target FROM player, exactly 50 length
    line_path.addLine(to: playerPosition + direction)
    
    // Add cube!
    var cube = placeCube(cubePoint: playerPosition + direction, distance: distance, maxSize: 30)
    
    // Create Line! (TODO: REMOVE ???)
    let shape = SKShapeNode()
    shape.path = line_path
    shape.strokeColor = UIColor.red
    shape.lineWidth = 2
    
    return (shape, cube)
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
    
}


extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
   
    // 2
    if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster)
      }
    }
  }

}
