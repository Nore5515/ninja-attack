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

import SpriteKit

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


struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1       // 1
  static let projectile: UInt32 = 0b10      // 2
}

struct EnemyNoti {
  var enemyTarget : SKSpriteNode
  var distanceTo : CGFloat
  var eCube : EnemyCube
//  var notificationCube: SKShapeNode
}

struct EnemyCube{
  var line : SKShapeNode
  var cube : SKShapeNode
}



class GameScene: SKScene {
  // 1
  let player = SKSpriteNode(imageNamed: "player")
  var kills = 0
  var noLefts : UInt32 = 0
  
  var enemyNotiArray: [EnemyNoti] = []
  
  
  private var killsLabel : SKLabelNode?
    
  override func didMove(to view: SKView) {
    
    backgroundColor = SKColor.white
    
    let killsLabel2 = SKLabelNode(fontNamed:"Times New Roman")
    killsLabel2.fontColor = UIColor.black
    killsLabel2.text = String(kills)
    killsLabel2.fontSize = 14
  
    killsLabel2.position = CGPoint(x:size.width * 0.4, y:size.height * 0.4)
    self.killsLabel = killsLabel2
    if let killsLabel = killsLabel {
      self.addChild(killsLabel)
    }
    
    // 2
    
    // 3
    player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    // 4
    addChild(player)
    
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addMonster),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
    run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(redrawLines),
            SKAction.wait(forDuration: 0.1)
            ])
        ))

  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func redrawLines(){
    var index = -1
    for enemy in enemyNotiArray{
      index = getIndexOfMonster(monster: enemy.enemyTarget, list: enemyNotiArray)
      if (index >= 0){
//        enemyNotiArray[index].eCube.line.removeFromParent()
        enemyNotiArray[index].eCube.cube.removeFromParent()
        enemyNotiArray[index].distanceTo = distanceBetweenPoints(first: player.position, second: enemy.enemyTarget.position)
        let (line, cube) = createLine(playerPosition: player.position, monsterPosition: enemy.enemyTarget.position, distance: enemyNotiArray[index].distanceTo)
        let enemyCube = EnemyCube(line: line, cube: cube)
        enemyNotiArray[index].eCube = enemyCube
      }
    }
  }
  
  func distanceBetweenPoints(first: CGPoint, second: CGPoint) -> CGFloat{
    //return hypotf(second.x - first.x, second.y - first.y);
    return CGFloat(hypotf(Float(second.x - first.x), Float(second.y - first.y)));
  }

  func addMonster() {
    
    // Create sprite
    let monster = SKSpriteNode(imageNamed: "monster")
    
    monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
    monster.physicsBody?.isDynamic = true // 2
    monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5

    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
    
    // Spawn monster on left 1 in 15 times, odds increasing the longer you go without one.
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
    
    let (line, cube) = createLine(playerPosition: player.position, monsterPosition: monster.position, distance: distanceBetweenPoints(first: player.position, second: monster.position) )
    let enemyCube = EnemyCube(line: line, cube: cube)
    enemyNotiArray.append(EnemyNoti(enemyTarget: monster, distanceTo: distanceBetweenPoints(first: player.position, second: monster.position), eCube: enemyCube))
    if let killsLabel = killsLabel {
      killsLabel.text = String(enemyNotiArray.count)
    }
    
    // Add the monster to the scene
    addChild(monster)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(1.5), max: CGFloat(10.0))
    
    // Add angle variance
    let yMod = random(min: CGFloat(-150.0), max: CGFloat(150.0))
    
    // Cap the destination to the screen size.
    var cappedY = actualY + yMod
    if (cappedY > size.height){
      cappedY = size.height - monster.size.width/2
    }
    if (cappedY < 0){
      cappedY = monster.size.width/2
    }
    
    
    // Create the actions
    let actionMoveDone = SKAction.removeFromParent()
    if (leftSpawn >= 15.0){
      print("OTHER WAY")
      let actionMove = SKAction.move(to: CGPoint(x: size.width + monster.size.width/2, y: cappedY),
                                     duration: TimeInterval(actualDuration))
//      let loseAction = SKAction.run() { [weak self] in
//        guard let `self` = self else { return }
//        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//        let gameOverScene = GameOverScene(size: self.size, won: false)
//        self.view?.presentScene(gameOverScene, transition: reveal)
      let loseAction = SKAction.run() {
        let monsterIndex = self.getIndexOfMonster(monster: monster, list: self.enemyNotiArray)
        if (monsterIndex >= 0){
          self.enemyNotiArray[monsterIndex].eCube.cube.removeFromParent();
          self.enemyNotiArray.remove(at: monsterIndex)
        }
        monster.removeFromParent()
      }
      monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

    }
    else{
      let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY + yMod),
                                     duration: TimeInterval(actualDuration))
      let loseAction = SKAction.run() {
        let monsterIndex = self.getIndexOfMonster(monster: monster, list: self.enemyNotiArray)
        if (monsterIndex >= 0){
          self.enemyNotiArray[monsterIndex].eCube.cube.removeFromParent();
          self.enemyNotiArray.remove(at: monsterIndex)
        }
        monster.removeFromParent()
//        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//        let gameOverScene = GameOverScene(size: self.size, won: false)
//        self.view?.presentScene(gameOverScene, transition: reveal)
      }
      monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))

    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    
    // 2 - Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true

    
    // 3 - Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    
    // 4 - Bail out if you are shooting down or backwards
    //    if offset.x < 0 { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(projectile)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 2000
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    
    // 9 - Create the actions
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
  }

  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    print("Hit")
    kills += 1
    print (kills)
    projectile.removeFromParent()
    let monsterIndex = getIndexOfMonster(monster: monster, list: enemyNotiArray)
    if (monsterIndex >= 0){
//      enemyNotiArray[monsterIndex].eCube.line.removeFromParent();
      enemyNotiArray[monsterIndex].eCube.cube.removeFromParent();
      enemyNotiArray.remove(at: monsterIndex)
    }
    if let killsLabel = killsLabel {
//      killsLabel.text = String(kills)
      killsLabel.text = String(enemyNotiArray.count)
    }
    monster.removeFromParent()
    
  }
  
  func getIndexOfMonster(monster: SKSpriteNode, list: Array<EnemyNoti>) -> Int
  {
    var index = 0
    for enemyNoti in list{
      if (enemyNoti.enemyTarget == monster){
        return index
      }
      index += 1
    }
    return -1
  }
  
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
    var cube = placeCube(cubePoint: playerPosition + direction, distance: distance)
    
    let shape = SKShapeNode()
    shape.path = line_path
    shape.strokeColor = UIColor.red
    shape.lineWidth = 2
    
//    addChild(shape)
    
    return (shape, cube)
  }
  
  func placeCube(cubePoint: CGPoint, distance: CGFloat) -> SKShapeNode{
    var size = 15*(100/distance)
    if (size > 40){
      size = 40
    }
    var barra = SKShapeNode(rectOf: CGSize(width: size, height: size))
    barra.name = "bar"
    barra.fillColor = SKColor.red
    barra.position = cubePoint

    self.addChild(barra)
    return barra
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
