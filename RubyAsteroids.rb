# Asteroids Game made in Ruby
# Author: Ian Caio

require 'gtk3'

# Classes:
class Game
  SCREEN_WIDTH = 600
  SCREEN_HEIGHT = 400

  # State of the keys to move the ship
  attr_accessor :key_up, :key_down, :key_left, :key_right

  def initialize
    mainMenu
  end

  def createWindow      # Creates the window where the game will be draw
    @window = Gtk::Window.new
    @window.set_title "Asteroids"

    @window.signal_connect("destroy"){
      Gtk.main_quit
    }

    @window.set_default_size SCREEN_WIDTH, SCREEN_HEIGHT
    @window.set_window_position :center

    @window.signal_connect("key-press-event") { |widget, event|
      key_press_callback(widget, event)
    }
    @window.signal_connect("key-release-event") { |widget, event|
      key_release_callback(widget, event)
    }

    @drawingArea = Gtk::DrawingArea.new
    @drawingArea.signal_connect("draw"){
      cairoContext = @drawingArea.window.create_cairo_context

      SpaceObject.SpaceObjectInstances.each { |spaceObj|
        spaceObj.updatePosition
        spaceObj.draw(cairoContext)
      }
    }

    GLib::Timeout.add(50){
      updateControls
      updateGame
      @drawingArea.queue_draw
    }

    @window.add @drawingArea
    @window.show_all
  end

  def updateControls
    if @key_up
      Ship.ShipInstances.each { |ship|
        ship.accelerate(5)
      }
    elsif @key_down
      Ship.ShipInstances.each { |ship|
        ship.accelerate(-5)
      }
    end

    if @key_left
      Ship.ShipInstances.each { |ship|
        ship.rotate(-0.3)
      }
    elsif @key_right
      Ship.ShipInstances.each { |ship|
        ship.rotate(0.3)
      }
    end
  end

  def key_press_callback(widget, event)
    key = event.keyval

    if key == Gdk::Keyval::KEY_w
      @key_up = true
    elsif key == Gdk::Keyval::KEY_s
      @key_down = true
    end

    if key == Gdk::Keyval::KEY_a
      @key_left = true
    elsif key == Gdk::Keyval::KEY_d
      @key_right = true
    end

    if key == Gdk::Keyval::KEY_space
      Ship.ShipInstances.each { |ship|
        ship.shoot
      }
    end
  end

  def key_release_callback(widget, event)
    key = event.keyval

    if key == Gdk::Keyval::KEY_w
      @key_up = false
    elsif key == Gdk::Keyval::KEY_s
      @key_down = false
    end

    if key == Gdk::Keyval::KEY_a
      @key_left = false
    elsif key == Gdk::Keyval::KEY_d
      @key_right = false
    end
  end

  def mainMenu  # Goes to the main menu of the game (Start/HighScores/Quit)
    puts '========     ASTEROIDS     ========'
    puts '==================================='
    puts "Type 'start' to start playing"
    puts "     'highscore' to view the highscore"
    puts "     'exit' to leave the game"
    puts '==================================='
    puts 'Controls:'
    puts "'W', 'A', 'S', 'D' = Turn/Move ship"
    puts "'space' = Shoot"
    puts '==================================='
    print "> "

    choice = gets.chomp

    case choice
    when 'start'
      startGame
    when 'highscore'
      showHighscore
      exit 0
    when 'quit'
      exit 0
    else
      puts "Invalid command!"
      exit 0
    end
  end

  def startGame # Starts the game
    createWindow
    @score = 1_000_000        # Current game score (starts at 1 million and goes down with time)
    @lastScoreUpdate = Time.now.to_f    # The last time the score was updated
  end

  def showHighscore     # Shows the highscore table
    if (File.exists?(File.realpath("./") + "/HighScore") && File.readable?(File.realpath("./HighScore")))
      highscoreFile = File.open(File.realpath("./HighScore"), "r")

      system("clear")
      puts "============================================="
      puts "========     ASTEROIDS HIGHSCORE     ========"
      puts "============================================="

      counter = 1
      while line = highscoreFile.gets
        score = highscoreFile.gets
        if score
          score = score.chomp.to_i
          puts "#{counter} - #{line.chomp} - #{score}"
          counter += 1
        else
          puts "Highscore file is corrupted!"
          highscoreFile.close
          return
        end
      end

      highscoreFile.close
    else
      puts "Couldn't open Highscore file!"
    end
    return
  end

  def showWinScreen     # Shows the winning screen
    system("clear")
    puts "==================================="
    puts "========     ASTEROIDS     ========"
    puts "==================================="
    puts "========     YOU  WIN!     ========"
    puts "==================================="
    puts "Score: #{@score}"

    # Open highscore file, check if the score is higher than any of the scores there
    # and prompt the user for a name if it is.
    if (File.exists?(File.realpath("./") + "/HighScore") && File.readable?(File.realpath("./HighScore")) &&
        File.writable?(File.realpath("./HighScore")))
      highscoreFile = File.open(File.realpath("./HighScore"), "r")
      highscoreArray = [] # Array containing arrays with the position, name and score

      counter = 1
      while line = highscoreFile.gets
        score = highscoreFile.gets
        if score
          score = score.chomp.to_i
          tempArray = [counter, line.chomp, score]
          highscoreArray.push(tempArray)
          counter += 1
        else
          puts "Highscore file is corrupted!"
          highscoreFile.close
          return
        end
      end

      highscoreFile.close

      # Check the player position in the highscore
      playerPosition = 11        # 11 means it's not in the highscore, since it goes up to 10
      highscoreArray.each { |value|
        if (playerPosition > value[0] && @score > value[2])
          playerPosition = value[0]
        end
      }

      if playerPosition < 11
        puts "You entered the highscore! What's your name?"
        print "> "
        playerName = gets.chomp

        # Put the players from the playerPosition on in a lower position (except for the last, that will be excluded)
        if playerPosition != 10
          9.downto(playerPosition) { |i|
            highscoreArray[i][1] = highscoreArray[i-1][1]
            highscoreArray[i][2] = highscoreArray[i-1][2]
          }
        end

        # Put the player in the highscore
        highscoreArray[playerPosition-1][1] = playerName
        highscoreArray[playerPosition-1][2] = @score

        highscoreFile = File.open(File.realpath("./HighScore"), "w")

        highscoreArray.each { |value|
          highscoreFile.write("#{value[1]}\n#{value[2]}\n")
        }

        highscoreFile.close
      end
      showHighscore
    else
      puts "Couldn't open Highscore file!"
    end
    return
  end

  def showLoseScreen    # Shows the losing screen
    system("clear")
    puts "==================================="
    puts "========     ASTEROIDS     ========"
    puts "==================================="
    puts "========     YOU LOSE!     ========"
    puts "==================================="
    return
  end

  def updateGame        # Updates the game
    timeSinceLastUpdate = Time.now.to_f - @lastScoreUpdate
    @score = (@score - timeSinceLastUpdate * 100).to_i
    @lastScoreUpdate = Time.now.to_f

    if Ship.ShipInstances.empty?       # No ships, meaning player lost the game
      GLib::Timeout.add(2000) { # 2 seconds and we show the lose screen and quit
        Gtk.main_quit
        showLoseScreen
      }
    elsif Asteroid.AsteroidInstances.empty?        # No asteroids, meaning the player won the game
      GLib::Timeout.add(2000) { # 2 seconds and we show the lose screen and quit
        Gtk.main_quit
        showWinScreen
      }
    end
  end
end

class Vector
  attr_accessor :x
  attr_accessor :y

  def initialize(x,y)
    @x = x
    @y = y
  end

  def vectormodule      # Calculates the vector module
    vecmod = Math::sqrt(@x**2 + @y**2)
  end

  def distance(x,y)     # Calculates the distance between this object and the given point
    dist = Math::sqrt((x - @x)**2 + (y - @y)**2)
  end
end

class SpaceObject
  @@SpaceObjectInstances = []      # Array holding the class instances (to avoid using ObjectSpace::each_object to iterate
                        # through the objects, since it could iterate through dead objects that were not yet
                        # removed from memory by the Garbage Collector)

  attr_accessor :position     # A vector representing the position of the object
  attr_accessor :speed        # A vector representing the speed of the object
  attr_reader :collisionRadius      # The radius we will use to calculate the collision with

  @lastPositionUpdate   # Time when the position was last updated (in millisecs)

  def initialize(x, y, speedx, speedy, collisionradius)
    @position = Vector.new(x,y)
    @speed = Vector.new(speedx, speedy)
    @collisionRadius = collisionradius
    @lastPositionUpdate = Time.now.to_f

    @@SpaceObjectInstances.push(self)      # Add the instance to the list of objects
  end

  # Instance methods:
  def updatePosition    # Updates the position according to the current speed
    if @speed.x != 0 or @speed.y != 0
      @position.x += @speed.x * (Time.now.to_f - @lastPositionUpdate)
      @position.y += @speed.y * (Time.now.to_f - @lastPositionUpdate)
    end

    if @position.x > (Game::SCREEN_WIDTH + @collisionRadius + 10)    # We add 10 pixels so the object don't bounce infinitely on both edges
      @position.x = 0 - @collisionRadius
    elsif @position.x < (0 - @collisionRadius - 10)     # We subtract 10 pixels so the object don't bounce infinitely on both edges
      @position.x = Game::SCREEN_WIDTH + @collisionRadius
    end

    if @position.y > (Game::SCREEN_HEIGHT + @collisionRadius + 10)
      @position.y = 0 - @collisionRadius
    elsif @position.y < (0 - @collisionRadius - 10)
      @position.y = Game::SCREEN_HEIGHT + @collisionRadius
    end

    @lastPositionUpdate = Time.now.to_f
  end

  def collision?(spaceObj2)  # Checks if this object collides with another one
    if @position.distance(spaceObj2.position.x, spaceObj2.position.y) < (@collisionRadius + spaceObj2.collisionRadius)
      true
    else
      false
    end
  end

  def draw(cairoContext); end # Draws the space object (will be overriden by the inherited classes)

  # Class methods
  # Method to read the space object instances array
  def self.SpaceObjectInstances
    @@SpaceObjectInstances
  end
end

class Asteroid < SpaceObject
  @@AsteroidInstances = []      # Array containing asteroid instances

  def initialize(x, y, speedx, speedy, collisionradius)
    super

    @@AsteroidInstances.push(self)      # Adds object to the asteroid instances array
  end

  # Overriding the update position to include collision check
  def updatePosition
    super

    Bullet.BulletInstances.each { |bullet|
      if collision?(bullet)
        bullet.destroy
        explode
      end
    }

    Ship.ShipInstances.each { |ship|
      if collision?(ship)
        ship.destroy
        explode
      end
    }
  end

  def explode
    if @collisionRadius > 5
      childasteroid = Asteroid.new(@position.x, @position.y, rand(-60..60), rand(-60..60), @collisionRadius/2)
      @collisionRadius = @collisionRadius/2
    else
      destroy
    end
  end

  def destroy
    @@AsteroidInstances.delete(self)
    @@SpaceObjectInstances.delete(self)
  end

  def draw(cairoContext)
    cairoContext.set_source_rgb 0, 0, 0
    cairoContext.arc @position.x, @position.y, @collisionRadius, 0, Math::PI*2
    cairoContext.fill
  end

  def self.AsteroidInstances
    @@AsteroidInstances
  end
end

class Ship < SpaceObject
  MAX_SPEED = 80
  SHOOT_TIMEOUT = 0.5   # Half a second between each shoot

  @@ShipInstances = []  # Array holding the ship instances

  def initialize(x, y, speedx, speedy, collisionradius)
    super

    @angle = 0.5        # The ship angle in radians (not necessary on Asteroids, since they are circles)

    @lastShootTime = Time.now.to_f       # Shooting cooldown

    @@ShipInstances.push(self)  # Also add the ship to the ship instances array (besides the space objects arrays)
  end

  def rotate(ang)
    @angle += ang
  end

  def accelerate(accel)
    if @speed.vectormodule < MAX_SPEED
      @speed.x += Math::cos(@angle)*accel
      @speed.y += Math::sin(@angle)*accel
    else
      # Check if the acceleration will result in a lower module speed.
      # If not, keep the old speed.
      oldspeedx = @speed.x
      oldspeedy = @speed.y
      oldvectormodule = @speed.vectormodule

      @speed.x += Math::cos(@angle)*accel
      @speed.y += Math::sin(@angle)*accel

      if oldvectormodule < @speed.vectormodule
        @speed.x = oldspeedx
        @speed.y = oldspeedy
      end
    end
  end

  def shoot
    if (Time.now.to_f - @lastShootTime) > 0.5
      bullet = Bullet.new(@position.x, @position.y, Math::cos(@angle)*100, Math::sin(@angle)*100, 3, @angle)
      @lastShootTime = Time.now.to_f
    end
  end

  def destroy
    @@ShipInstances.delete(self)
    @@SpaceObjectInstances.delete(self)
  end

  def draw(cairoContext)
    cairoContext.set_source_rgb 0.2,0.23,0.9
    cairoContext.save
    cairoContext.translate @position.x, @position.y
    cairoContext.rotate @angle
    cairoContext.rectangle -9, -4, 18, 8
    cairoContext.rectangle -8, -9, 4, 18
    cairoContext.fill
    cairoContext.restore

    # Draw the collision radius
    cairoContext.set_source_rgba 1,0,0,0.2
    cairoContext.arc @position.x, @position.y, @collisionRadius, 0, Math::PI*2
    cairoContext.fill
  end

  def self.ShipInstances
    @@ShipInstances
  end
end

class Bullet < SpaceObject
  TIME_TO_LIVE = 5.0    # Bullet lives for 5 seconds

  @@BulletInstances = []        # Array holding the bullet instances

  def initialize(x, y, speedx, speedy, collisionradius, angle)
    super(x, y, speedx, speedy, collisionradius)

    @angle = angle

    @birthtime = Time.now.to_f

    @@BulletInstances.push(self) # Also add the bullet to the bullet instances array (besides the space objects arrays)
  end

  def updatePosition
    super

    if (Time.now.to_f - @birthtime) > TIME_TO_LIVE
      destroy
    end
  end

  def destroy
    @@BulletInstances.delete(self)
    @@SpaceObjectInstances.delete(self)
  end

  def draw(cairoContext)
    cairoContext.set_source_rgb 1,0.6,0.2
    cairoContext.rectangle @position.x-1, @position.y-1, 3, 3
    cairoContext.fill
  end

  def self.BulletInstances
    @@BulletInstances
  end
end

# Code flow start:
Gtk.init

game = Game.new

randomGen = Random.new(Time.now.to_i)

ship = Ship.new(randomGen.rand(50..550),randomGen.rand(50..350),0,0,10)

for i in (1..10)
  xDirection = randomGen.rand(1..2)
  yDirection = randomGen.rand(1..2)
  speedx = randomGen.rand(30..60)
  speedy = randomGen.rand(30..60)

  if xDirection == 1
    speedx *= -1
  end
  if yDirection == 1
    speedy *= -1
  end

  # Half asteroids are large, half are medium
  if i >= 5
    asteroid = Asteroid.new(rand(30..570),rand(30..370),speedx,speedy,20)
  else
    asteroid = Asteroid.new(rand(30..570),rand(30..370),speedx,speedy,10)
  end
end

Gtk.main
