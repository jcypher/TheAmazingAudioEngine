//
//  GameScene.swift
//  TheGameSample
//
//  Created by Leo on 2014-12-04.
//  Copyright (c) 2014 The Amazing Audio Engine. All rights reserved.
//

import SpriteKit



// Utility functions - you would probably want to organize this better!

/// Returns a float between 0.0 and 1.0
func randomFloat() -> Float {
    return Float(arc4random()) /  Float(UInt32.max)
}



/// This controlls the SpriteKit SKScene for both the Mac and iOS targets!
class GameScene: SKScene {
    
    var _audCtrlr : AEAudioController = audInit(nil)
    
    var _bgMusic  : AEAudioFilePlayer! // takes more memory... keep your background sound files short, and perhaps use lower bitrate (e.g. 22050)
    
    var _samplerChannel : VEAEGameSound!
    
    var btnBgSnd, btnEffects : SKLabelNode!
    
    
    override func didMoveToView(view: SKView) {
        
        backgroundColor = SKColor.blackColor()
        
        let fontSize : CGFloat = 24
        
        // "Button" #1 - a label, but tap/click-able
        btnBgSnd = SKLabelNode(fontNamed:"Chalkduster")
        btnBgSnd.text = "Play background music track!";
        btnBgSnd.fontSize = fontSize;
        btnBgSnd.position = CGPoint(x:CGRectGetMidX(frame), y:CGRectGetMidY(frame) + 64);
        addChild(btnBgSnd)
        
        // "Button" #2 - a label, but tap/click-able
        btnEffects = SKLabelNode(fontNamed:"Chalkduster")
        btnEffects.text = "Play 2 stereo panning sound effects!";
        btnEffects.fontSize = fontSize;
        btnEffects.position = CGPoint(x:CGRectGetMidX(frame), y:CGRectGetMidY(frame) - 64);
        addChild(btnEffects)
        
        // Preload audio
        _samplerChannel = audLoadEffect(NSBundle.mainBundle().URLForResource("effect1", withExtension: "caf"), 1.0, true)
        
        // TEST
//        let ambience = audLoadAmbience(NSBundle.mainBundle().pathForResource("HiQualityMix96.7", ofType: "wav"), 1.0, 0.0, 0)
        var err : NSError?
        let ambience = VEAEGameTrack(fileURL: NSBundle.mainBundle().URLForResource("effect1", withExtension: "caf"), audioController: audController(), shouldLoop:false, error:&err)
        audController().addChannels([ambience])
        runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.runBlock({ ambience.channelIsPlaying = false }), SKAction.waitForDuration(1.0), SKAction.runBlock({ ambience.channelIsPlaying = true }), SKAction.waitForDuration(1.0), SKAction.runBlock({ ambience.channelIsPlaying = false }), SKAction.waitForDuration(1.0), SKAction.runBlock({ ambience.channelIsPlaying = true })]))
        
        // on iOS let's let the user know to use headphones to be able to hear the panning effects
//        #if os(iOS)
//            runAction(SKAction.sequence([SKAction.waitForDuration(0.65), SKAction.runBlock({
//                let alertView = UIAlertView(title: "Tip of the Day", message: "To hear the panning effect, use headphones!\n\nThe pitch and rate are being set randomly but only on one sound effect (the organ); see the source code for more information.", delegate: nil, cancelButtonTitle: "OK")
//                alertView.show()
//            })]))
//        #endif
    }
    
    
//    override func update(currentTime: CFTimeInterval) {
//        /* Called before each frame is rendered */
//    }
    
    
    func _doBtnBoing(btn : SKLabelNode) {
        btn.removeAllActions()
        btn.setScale(1.0)
        SKAction.scaleXTo(0.8, y: 0.6, duration: 0.75)
        btn.runAction(SKAction.sequence([SKAction.scaleXTo(0.9, y: 0.6, duration: 0.075),SKAction.scaleTo(1.0, duration: 0.15)]))
    }
    
    
    func _doStartBgMusic() {
        if _bgMusic == nil {
            // There is an unsupported "AEAudioUnitFilePlayer.h" you can use, but looping doesn't seem to loop and the loop completion callback gets called at what seems to be the wrong time.  So, for no I've converted this function to use a regular file player.  This unfortunately loads everything into memory, so keep these tracks short even if using a compressed format - it still takes the same memory as an uncompressed format.
            var err : NSErrorPointer = nil
            _bgMusic = AEAudioFilePlayer.audioFilePlayerWithURL(NSBundle.mainBundle().URLForResource("bg_music", withExtension: "wav"), audioController: _audCtrlr, error: err) as AEAudioFilePlayer
            if _bgMusic == nil {
                println("Could not load bgMusic !")
                return
            }
            _bgMusic.loop = true
            _bgMusic.volume = 0.65
            _audCtrlr.addChannels([_bgMusic])
            
            println("bgMusic playing: \(_bgMusic.channelIsPlaying)")
        } else {
            _audCtrlr.removeChannels([_bgMusic])
            _bgMusic = nil
        }
    }
    
    /// EVENTS
    func uiEventStart(p : CGPoint) {
        
        if btnBgSnd.containsPoint(p) {
            if btnBgSnd.yScale > 0.99 && btnBgSnd.yScale < 1.01 { // prevents fast repeated taps
                _doBtnBoing(btnBgSnd)
//                runAction(SKAction.runBlock(_doStartBgMusic))
                runAction(SKAction.runBlock({
                    self._samplerChannel = nil
                    self._audCtrlr.removeChannels(self._audCtrlr.channels())
                    self._samplerChannel = audLoadEffect(NSBundle.mainBundle().URLForResource("effect1", withExtension: "caf"), 1.0, true)
                }))
            }
        } else if btnEffects.containsPoint(p) {
            _doBtnBoing(btnEffects)
            runAction(SKAction.runBlock({
                
                // Play it!
                self._samplerChannel.play(1.0)
                
                // Modulate the pan - left to right
                if(self._samplerChannel.auPan > -0.9) {
                    self._samplerChannel.auPanTo(-1.0, duration:0.25);
                    self.runAction(SKAction.sequence([SKAction.waitForDuration(0.25),SKAction.runBlock({
                        self._samplerChannel.auPanTo(1.0, duration:0.75);
                    })]))
                } else {
                    self._samplerChannel.auPanTo(1.0, duration:1.0);
                }
                
                // Modulate the volume - silent to full volume
                self._samplerChannel.auVolume = 0;
                self._samplerChannel.auVolumeTo(1.0, duration:1.5)
                
                // modulate the pitch -1octaves to at-pitch
                self._samplerChannel.auPitchBendTo(1.1, duration:1.0)
                
                
                
                // After 1 second pan back to center
                self.runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.runBlock({
                    self._samplerChannel.auPitchBendTo(1.0, duration:0.25)
                    self._samplerChannel.auPanTo(-0.2, duration:2.0);
                })]))
            }))
        } else {
            
            // Just some sample code from original Xcode generated project:
//            let sprite = SKSpriteNode(imageNamed:"Spaceship")
//            
//            sprite.xScale = 0.5
//            sprite.yScale = 0.5
//            sprite.position = p
//            
//            let action = SKAction.rotateByAngle(CGFloat(M_PI) * (randomFloat() > 0.5 ? 1.0 : -1.0) , duration:0.5 + 0.5 * Double(arc4random_uniform(5)))
//            
//            sprite.runAction(SKAction.repeatActionForever(action))
//            
//            addChild(sprite)
        }
    }
    
    
#if os(iOS)
    // iPad/iPod touch/iPhone
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            uiEventStart(touch.locationInNode(self))
        }
    }
    
#else
    // Mac OS X
    
    override func mouseDown(theEvent: NSEvent) {
        uiEventStart(theEvent.locationInNode(self))
    }
    
#endif
} // END CLASS
