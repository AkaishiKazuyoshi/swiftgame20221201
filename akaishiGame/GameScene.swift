//
//  GameScene.swift
//  akaishiGame
//
//  Created by user on 2022/12/01.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let eriko = SKSpriteNode(imageNamed: "Angry_Erikosan")
    let player = SKShapeNode(circleOfRadius: 20)
    var enemies = [SKShapeNode]()
    var timer: Timer?
    var prevTime: TimeInterval = 0
    var startTime: TimeInterval = 0
    var isGameFinished = false
    let playerAgent = GKAgent2D()
    let agentSystem = GKComponentSystem(componentClass: GKAgent2D.self)
    var enemyAgents = [GKAgent2D]()
    var obstacles = [GKCircleObstacle]()
    
    override func didMove(to view: SKView) {
        player.fillColor = UIColor(red: 0.93, green: 0.96, blue: 0.00, alpha: 1.0)
        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        eriko.size = CGSize(width: size.width / 5, height: size.height / 10)
        eriko.position.x = 250
        eriko.position.y = 40
        addChild(player)
        addChild(eriko)
        
        createObstacles()
        setCreateEnemyTimer()
        physicsWorld.gravity = CGVector()
    }
    
    func createObstacles() {
        guard let viewFrame = view?.frame else {
            return
        }
        
        while obstacles.count < 5 {
            let point = CGPoint(
                x: CGFloat(arc4random_uniform(UInt32(viewFrame.width))) - viewFrame.width / 2,
                y: CGFloat(arc4random_uniform(UInt32(viewFrame.height))) - viewFrame.height / 2)
            let radius = Float(arc4random_uniform(50) + 50)
            
            // 障害物かPlayerが衝突していたら設置しない
            let isObstacleOverlapped = obstacles.contains {
                let dx = (Float(point.x) - $0.position.x)
                let dy = (Float(point.y) - $0.position.y)
                if sqrt(dx*dx + dy*dy) < $0.radius + radius {
                    return true
                }
                return false
            }
            let dx = point.x - player.position.x
            let dy = point.y - player.position.y
            let isPlayerOverlapped = sqrt(dx*dx + dy*dy) < CGFloat(radius) + player.frame.width
            if isObstacleOverlapped || isPlayerOverlapped {
                continue
            }
            
            let obstacleNode = SKShapeNode(circleOfRadius: CGFloat(radius))
            obstacleNode.fillColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
            obstacleNode.position = point
            obstacleNode.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(radius))
            obstacleNode.physicsBody?.pinned = true
            addChild(obstacleNode)
            
            let obstacle = GKCircleObstacle(radius: radius)
//            obstacle.position = float2(x: Float(point.x), y: Float(point.y))
            obstacle.position = vector_float2(x: Float(point.x), y: Float(point.y))
            obstacles.append(obstacle)
        }
    }
    
    //            guard let viewFrame = view?.frame else {
    //                return
    //            }
    //
    //            var obstacleNodes = [SKShapeNode]()
    //            while obstacleNodes.count < 5 {
    //                let point = CGPoint(
    //                    x: CGFloat(arc4random_uniform(UInt32(viewFrame.width))) - viewFrame.width / 2,
    //                    y: CGFloat(arc4random_uniform(UInt32(viewFrame.height))) - viewFrame.height / 2)
    //                let radius = CGFloat(arc4random_uniform(50) + 50)
    //
    //                // 障害物かPlayerが衝突していたら設置しない
    //                let isObstacleOverlapped = obstacleNodes.contains {
    //                    let dx = (point.x - $0.position.x)
    //                    let dy = (point.y - $0.position.y)
    //                    if sqrt(dx*dx + dy*dy) < $0.frame.width + radius {
    //                        return true
    //                    }
    //                    return false
    //                }
    //                let dx = point.x - player.position.x
    //                let dy = point.y - player.position.y
    //                let isPlayerOverlapped = sqrt(dx*dx + dy*dy) < radius + player.frame.width
    //                if isObstacleOverlapped || isPlayerOverlapped {
    //                    continue
    //                }
    //
    //                let obstacleNode = SKShapeNode(circleOfRadius: CGFloat(radius))
    //                obstacleNode.fillColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    //                obstacleNode.position = point
    //                obstacleNode.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(radius))
    //                obstacleNode.physicsBody?.pinned = true
    //                addChild(obstacleNode)
    //                obstacleNodes.append(obstacleNode)
    //            }
    //        }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach {
            let point = $0.location(in: self)
            player.removeAllActions()
            
            let path = CGMutablePath()
            path.move(to: CGPoint())
            path.addLine(to: CGPoint(x: point.x - player.position.x, y: point.y - player.position.y))
            player.run(SKAction.follow(path, speed: 70.0))
        }
    }
    
    func setCreateEnemyTimer() {
        timer?.invalidate()
        // 5秒に一度、createEnemyを呼び出す処理
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(GameScene.createEnemy), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    @objc func createEnemy() {
        let enemy = SKShapeNode(circleOfRadius: 10)
        enemy.position.x = size.width / 2
        enemy.fillColor = UIColor(red: 0.94, green: 0.14, blue: 0.08, alpha: 1.0)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.width / 2)
        addChild(enemy)
        enemies.append(enemy)
        
        let anemyAgent = GKAgent2D()
        anemyAgent.maxAcceleration = 200
        anemyAgent.maxSpeed = 200
        anemyAgent.position = vector_float2(x: Float(enemy.position.x), y: Float(enemy.position.y))
        anemyAgent.delegate = self
        print(obstacles)
        
//        anemyAgent.behavior = GKBehavior(goals: [
//            GKGoal(toSeekAgent: playerAgent),
//            GKGoal(toAvoid: obstacles, maxPredictionTime: 2),
//        ], andWeights: [NSNumber(value: 1), NSNumber(value: 50)])
        
        anemyAgent.behavior = GKBehavior(goals: [
            GKGoal(toSeekAgent: playerAgent),
        ])
        
        agentSystem.addComponent(anemyAgent)
        enemyAgents.append(anemyAgent)
        
        
        //                let enemy = SKShapeNode(circleOfRadius: 10)
        //                enemy.position.x = size.width / 2
        //                enemy.fillColor = UIColor(red: 0.94, green: 0.14, blue: 0.08, alpha: 1.0)
        //                enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.width / 2)
        //                addChild(enemy)
        //                enemies.append(enemy)
        //                let anemyAgent = GKAgent2D()
        //                anemyAgent.maxAcceleration = 200
        //                anemyAgent.maxSpeed = 100
        //                anemyAgent.position = vector_float2(x: Float(enemy.position.x), y: Float(enemy.position.y))
        //                anemyAgent.delegate = self
        //                anemyAgent.behavior = GKBehavior(goals: [
        //                    GKGoal(toSeekAgent: playerAgent),
        //                ])
        //                agentSystem.addComponent(anemyAgent)
        //                enemyAgents.append(anemyAgent)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if prevTime == 0 {
            prevTime = currentTime
            startTime = currentTime
        }
        agentSystem.update(deltaTime: currentTime - prevTime)
        playerAgent.position = vector_float2(x: Float(player.position.x), y: Float(player.position.y))
        
        // プレイヤーの位置が変わるので、1秒に一度移動方向を調整する
        //        if Int(currentTime) != Int(prevTime) {
        //            enemies.forEach {
        //                $0.removeAllActions()
        //                let path = CGMutablePath()
        //                path.move(to: CGPoint())
        //                path.addLine(to: CGPoint(x: player.position.x - $0.position.x, y: player.position.y - $0.position.y))
        //                $0.run(SKAction.follow(path, speed: 50.0))
        //            }
        //        }
        if !isGameFinished {
            for enemy in enemies {
                let dx = enemy.position.x - player.position.x
                let dy = enemy.position.y - player.position.y
                if sqrt(dx*dx + dy*dy) < player.frame.width / 2 + enemy.frame.width / 2 {
                    isGameFinished = true
                    timer?.invalidate()
                    let label = SKLabelNode(text: "記録:\(Int(currentTime - startTime))秒")
                    label.fontSize = 80
                    label.position = CGPoint(x: 0, y: -100)
                    addChild(label)
                    break
                }
            }
        }
//        else {
//
//            let scene = GameScene(size: size)
//            self.view?.presentScene(scene)
//        }
        prevTime = currentTime
    }
    
    
    //    private var label : SKLabelNode?
    //    private var spinnyNode : SKShapeNode?
    //
    //    override func didMove(to view: SKView) {
    //
    //        // Get label node from scene and store it for use later
    //        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
    //        if let label = self.label {
    //            label.alpha = 0.0
    //            label.run(SKAction.fadeIn(withDuration: 2.0))
    //        }
    //
    //        // Create shape node to use during mouse interaction
    //        let w = (self.size.width + self.size.height) * 0.05
    //        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
    //
    //        if let spinnyNode = self.spinnyNode {
    //            spinnyNode.lineWidth = 2.5
    //
    //            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
    //            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
    //                                              SKAction.fadeOut(withDuration: 0.5),
    //                                              SKAction.removeFromParent()]))
    //        }
    //    }
    //
    //
    //    func touchDown(atPoint pos : CGPoint) {
    //        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
    //            n.position = pos
    //            n.strokeColor = SKColor.green
    //            self.addChild(n)
    //        }
    //    }
    //
    //    func touchMoved(toPoint pos : CGPoint) {
    //        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
    //            n.position = pos
    //            n.strokeColor = SKColor.yellow
    //            self.addChild(n)
    //        }
    //    }
    //
    //    func touchUp(atPoint pos : CGPoint) {
    //        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
    //            n.position = pos
    //            n.strokeColor = SKColor.red
    //            self.addChild(n)
    //        }
    //    }
    //
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        if let label = self.label {
    //            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
    //        }
    //
    //        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    //    }
    //
    //    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    //    }
    //
    //    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    //    }
    //
    //    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    //    }
    //
    //
    //    override func update(_ currentTime: TimeInterval) {
    //        // Called before each frame is rendered
    //    }
}

extension GameScene: GKAgentDelegate {
    func agentDidUpdate(_ agent: GKAgent) {
        if let agent = agent as? GKAgent2D, let index = enemyAgents.firstIndex(where: { $0 == agent }) {
            let enemy = enemies[index]
            enemy.position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
        }
    }
}
