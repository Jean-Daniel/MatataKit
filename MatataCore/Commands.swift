//
//  Commands.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 03/01/2022.
//

import Foundation
import SwiftUI

struct RGBColor {
  let red: UInt8
  let green: UInt8
  let blue: UInt8
}

struct BotCommands {

  // MARK: Motion
  // | `0x10 0x01` | Forward       |  distance in mm (16 bits)                        |
  func move(forward mm: UInt16) {

  }

  // | `0x10 0x02` | Backward      |  distance in mm (16 bits)                        |
  func move(backward mm: UInt16) {

  }

  // | `0x10 0x03` | Turn Left     |  angle in degree (16 bits)                       |
  func turn(left degree: UInt16) {

  }
  // | `0x10 0x04` | Turn Right    |  angle in degree (16 bits)                       |
  func turn(right degree: UInt16) {

  }

  // | `0x11 -`    | Wheel Motion  |  _See below_                                     |
  enum Wheel {
    case stop
    case forward(speed: UInt8)
    case backward(speed: UInt8)
  }
  func wheel(left: Wheel?, right: Wheel?) {

  }

  // MARK: Misc

  // | `0x12 0x01` | Dance         |  Dance [0x1; 0x6]                                |
  enum Dance : Int {
    case dance1 = 0x01
    case dance2 = 0x02
    case dance3 = 0x03
    case dance4 = 0x04
    case dance5 = 0x05
    case dance6 = 0x06
  }
  func dance(_ dance: Dance) {

  }

  // | `0x13 0x01` | Action        |  Action [0x1; 0x6]                               |
  enum Action : Int {
    case action1 = 0x01
    case action2 = 0x02
    case action3 = 0x03
    case action4 = 0x04
    case action5 = 0x05
    case action6 = 0x06
  }
  func action(_ action: Action) {

  }

  // MARK: Music
  // | `0x15 -`    | Play Note     |  beat (16 bits) / note (16 bits)                 |
  // BEATC = [131, 147, 165, 175, 196, 220, 247]
  // BEATH = [262, 294, 330, 349, 392, 440, 494, 523]
  func play(note: UInt16, beat: UInt16) {

  }
  
  // | `0x16 0x01` | Play Melody   |  Melody [0x1; 0xa]                               |
  // | `0x16 0x01` | Play Music    |  Music [0x11; 0x16]                              |
  // | `0x16 0x01` | Play Sound    |  Music [0x21; 0x2f]                              |
  enum Sound : Int {
    case melody1 = 0x01
    case melody2 = 0x02
    case melody3 = 0x03
    case melody4 = 0x04
    case melody5 = 0x05
    case melody6 = 0x06
    case melody7 = 0x07
    case melody8 = 0x08
    case melody9 = 0x09
    case melody10 = 0x0a

    case shiver      = 0x0b
    case startle     = 0x0c
    case wake_up     = 0x0e
    case dizzy       = 0x10

    case music1 = 0x11
    case music2 = 0x12
    case music3 = 0x13
    case music4 = 0x14
    case music5 = 0x15
    case music6 = 0x16

    case hello       = 0x21
    case zzz         = 0x24
    case sleepy      = 0x26
    case smile       = 0x27
    case yes         = 0x28
    case uh_oh       = 0x29
    // case angry = 0x29
    case no          = 0x2b
    case goodbye     = 0x2e
    case wow         = 0x2f
  }

  func play(_ sound: Sound) {

  }

  // MARK: LEDs
  // | `0x17 -`    | Eyes          |  bit field (left: 1, right: 2) / r, g, b [0;255] |
  func eyes(left: RGBColor?, right: RGBColor?) {

  }
}

struct ControllerCommands {

  enum Color: Int {
    case white = 1
    case red = 2
    case yellow = 3
    case green = 4
    case blue = 5
    case purple = 6
    case off = 7 // black
  }

  enum Level: Int {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    case level5 = 5
    case level6 = 6
  }

  enum Animation: Int {
    case spoondrift = 1
    case meteor = 2
    case rainbow = 3
    case firefly = 4
    case colorwipe = 5
    case breathe = 6
  }

  // | `0x18 0x02` | Show all            | `<color> <level [1;6]>`       |
  func leds(all color: Color, level: Level) {

  }

  // | `0x18 0x03` | Show all (RGB)      | `<r> <g> <b>`                 |
  func leds(all color: RGBColor) {

  }

  // | `0x18 0x04` | Show previous LED   | `<color> <level [1;6]>`       |
  func leds(previous color: Color, level: Level) {

  }

  // | `0x18 0x05` | Show next LED       | `<color> <level [1;6]>`       |
  func leds(next color: Color, level: Level) {

  }

  // | `0x18 0x06` | Show LED animation  | `<animation [1;6]>`           |
  func leds(_ animation: Animation) {

  }

  // | `0x18 0x07` | Show all (advanced) | 12 × `<r> <g> <b>`            |
  /// colors must be a 12 elements array
  func leds(all colors: [RGBColor]) {

  }

  // | `0x18 0x08` | Show single LED     | `<index [0; 11]> <r> <g> <b>` |
  enum Led: Int {
    case led1 = 1
    case led2 = 2
    case led3 = 3
    case led4 = 4
    case led5 = 5
    case led6 = 6
    case led7 = 7
    case led8 = 8
    case led9 = 9
    case led10 = 10
    case led11 = 11
    case led12 = 12
  }

  func led(_ led: Led, color: RGBColor) {

  }
}

struct ControllerSensors {

  // MARK: Motion

  //  | `0x20 0x02 0x01`      | is shaked            | `> 0 if true`      |
  func isShaked() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x02`      | is halo up           | `> 0 if true`      |
  func isHaloUp() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x03`      | is halo down         | `> 0 if true`      |
  func isHaloDown() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x04`      | is tilted left       | `> 0 if true`      |
  func isTiledLeft() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x05`      | is tilted right      | `> 0 if true`      |
  func isTiledRight() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x06`      | is tilted forward    | `> 0 if true`      |
  func isTiledForward() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x07`      | is tilted backward   | `> 0 if true`      |
  func isTiledBackward() -> Bool {
    return false
  }

  //  | `0x20 0x02 0x08`      | is falling           | `> 0 if true`      |
  func isFalling() -> Bool {
    return false
  }

  // MARK: Motion Advanced

  //  | `0x28 0x01 0x01`      | get X acceleration   | `32 bits LE float` |
  func getXAcceleration() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x02`      | get Y acceleration   | `32 bits LE float` |
  func getYAcceleration() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x03`      | get Z acceleration   | `32 bits LE float` |
  func getZAcceleration() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x04`      | get roll             | `32 bits LE float` |
  func getRoll() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x05`      | get pitch            | `32 bits LE float` |
  func getPitch() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x06`      | get yaw              | `32 bits LE float` |
  func getYaw() -> Float32 {
    return 0
  }

  //  | `0x28 0x01 0x07`      | get shake strength   | `32 bits LE float` |
  func getShakeStrength() -> Float32 {
    return 0
  }


  // MARK: Misc

  //  | `0x20 0x03`           | is sound detected    | `> 0 if true`      |
  func isSoundDetected() -> Bool {
    return false
  }

  //  | `0x20 0x04`           | is obstacle ahead    | `> 0 if true`      |
  func isObstacleAhead() -> Bool {
    return false
  }

  //  | `0x20 0x07 <button>`  | is button pressed    | `> 0 if true`      |
  enum Button: Int {
    case play = 1
    case delete = 2
    case turnRight = 3
    case forward = 4
    case turnLeft = 5
    case music = 6
    case backward = 7
  }

  func isButtonPressed(_ button: Button) -> Bool {
    return false
  }

  // MARK: Messaging

  //  | `0x20 0x06 0x01 <msg>`| send message         | `-`                |
  func send(message: UInt8) {

  }

  //  | `0x20 0x06 0x02`      | get received message | `message`          |
  func getMessage() -> UInt8? {
    return nil
  }

}

